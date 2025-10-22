#!/bin/bash

###############################################################################
# АВТОМАТИЧЕСКИЙ УСТАНОВЩИК SUNNYSIOUXCARE - ВЕРСИЯ 5.0
# Полностью автоматическая установка БЕЗ ручных действий
# Для Ubuntu 22.04 LTS
###############################################################################

set -e
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3; echo ""; echo "❌ ОШИБКА! Установка прервана."; exit 1' ERR

clear
echo "════════════════════════════════════════════════════════════════"
echo "       🚀 SUNNYSIOUXCARE.COM - АВТОУСТАНОВКА"
echo "════════════════════════════════════════════════════════════════"
echo ""
sleep 1

# Переменные
PROJECT_DIR="/var/www/sunny-sioux-care"
EMAIL_PASS=$(openssl rand -base64 24)

###############################################################################
echo "[1/11] Обновление системы..."
###############################################################################
apt-get update -qq 2>&1 | grep -v "^Get:" | grep -v "^Hit:" || true
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq 2>&1 >/dev/null

###############################################################################
echo "[2/11] Установка базовых пакетов..."
###############################################################################
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget git build-essential \
    python3.11 python3.11-venv python3-pip \
    nginx certbot python3-certbot-nginx \
    ufw gnupg ca-certificates apt-transport-https \
    2>&1 >/dev/null

###############################################################################
echo "[3/11] Установка MongoDB 7.0..."
###############################################################################
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc 2>/dev/null | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg 2>/dev/null
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update -qq 2>&1 | grep -v "^Get:" | grep -v "^Hit:" || true
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mongodb-org 2>&1 >/dev/null
systemctl enable mongod >/dev/null 2>&1
systemctl start mongod
sleep 2
systemctl is-active --quiet mongod && echo "   ✓ MongoDB запущен" || exit 1

###############################################################################
echo "[4/11] Установка Node.js 20..."
###############################################################################
curl -fsSL https://deb.nodesource.com/setup_20.x 2>/dev/null | bash - >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs 2>&1 >/dev/null
npm install -g yarn pm2 >/dev/null 2>&1
echo "   ✓ Node.js $(node -v) установлен"

###############################################################################
echo "[5/11] Установка почтового сервера..."
###############################################################################
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    postfix dovecot-core dovecot-imapd dovecot-pop3d \
    opendkim opendkim-tools mailutils 2>&1 >/dev/null

useradd -m -s /bin/bash info 2>/dev/null || true
echo "info:$EMAIL_PASS" | chpasswd
mkdir -p /home/info/Maildir/{cur,new,tmp}
chown -R info:info /home/info/Maildir
chmod -R 700 /home/info/Maildir
echo "$EMAIL_PASS" > /root/email_password.txt
chmod 600 /root/email_password.txt
echo "   ✓ Почтовый сервер установлен"

###############################################################################
echo "[6/11] Настройка Postfix и Dovecot..."
###############################################################################

cat > /etc/postfix/main.cf << 'EOFPOSTFIX'
myhostname = mail.sunnysiouxcare.com
mydomain = sunnysiouxcare.com
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
relayhost =
mynetworks = 127.0.0.0/8
inet_interfaces = all
inet_protocols = ipv4
home_mailbox = Maildir/
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level=may
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
EOFPOSTFIX

grep -q "^submission inet" /etc/postfix/master.cf 2>/dev/null || cat >> /etc/postfix/master.cf << 'EOFSUB'

submission inet n - y - - smtpd
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
EOFSUB

sed -i 's|mail_location = .*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf 2>/dev/null || true
sed -i 's|#disable_plaintext_auth = yes|disable_plaintext_auth = yes|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true
sed -i 's|auth_mechanisms = plain|auth_mechanisms = plain login|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true

cat > /etc/dovecot/conf.d/10-master.conf << 'EOFMASTER'
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOFMASTER

systemctl restart postfix dovecot
echo "   ✓ Почта настроена"

###############################################################################
echo "[7/11] Клонирование проекта..."
###############################################################################
cd /var/www
rm -rf sunny-sioux-care 2>/dev/null || true
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git 2>&1 | grep -v "^remote:" || true
echo "   ✓ Проект склонирован"

###############################################################################
echo "[8/11] Настройка Backend..."
###############################################################################
cd $PROJECT_DIR/backend
python3.11 -m venv venv
source venv/bin/activate
pip install -q --upgrade pip 2>/dev/null
pip install -q -r requirements.txt 2>/dev/null
deactivate

cat > .env << EOFENV
MONGO_URL="mongodb://localhost:27017"
DB_NAME="sunnysiouxcare_production"
CORS_ORIGINS="*"
PAYPAL_CLIENT_ID="AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg"
PAYPAL_CLIENT_SECRET="ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x"
PAYPAL_MODE="live"
EMAIL_ENABLED="true"
SMTP_HOST="localhost"
SMTP_PORT="587"
SMTP_USER="info"
SMTP_PASSWORD="$EMAIL_PASS"
FROM_EMAIL="info@sunnysiouxcare.com"
ADMIN_EMAIL="info@sunnysiouxcare.com"
EOFENV

cat > ecosystem.config.js << 'EOFECO'
module.exports = {
  apps: [{
    name: 'sunnysiouxcare-backend',
    script: 'venv/bin/python',
    args: '-m uvicorn server:app --host 0.0.0.0 --port 8001',
    cwd: '/var/www/sunny-sioux-care/backend',
    interpreter: 'none',
    env: { PYTHONPATH: '/var/www/sunny-sioux-care/backend' }
  }]
};
EOFECO

echo "   ✓ Backend настроен"

###############################################################################
echo "[9/11] Сборка Frontend (1-2 минуты)..."
###############################################################################
cd $PROJECT_DIR/frontend
cat > .env << 'EOFENV'
REACT_APP_BACKEND_URL=https://sunnysiouxcare.com
EOFENV

yarn install >/dev/null 2>&1
export NODE_OPTIONS="--max-old-space-size=1536"
yarn build 2>&1 | grep -E "Compiled|File sizes|Done" || true
[ -f "build/index.html" ] && echo "   ✓ Frontend собран" || exit 1

###############################################################################
echo "[10/11] Запуск Backend через PM2..."
###############################################################################
cd $PROJECT_DIR/backend
pm2 delete all 2>/dev/null || true
pm2 start ecosystem.config.js >/dev/null 2>&1
pm2 save >/dev/null 2>&1
pm2 startup 2>/dev/null | tail -1 | bash >/dev/null 2>&1 || true
sleep 3
pm2 list | grep -q "online" && echo "   ✓ Backend запущен" || exit 1

###############################################################################
echo "[11/11] Настройка Nginx..."
###############################################################################

cat > /etc/nginx/sites-available/sunnysiouxcare << 'EOFNGINX'
server {
    listen 80;
    server_name sunnysiouxcare.com www.sunnysiouxcare.com;
    root /var/www/sunny-sioux-care/frontend/build;
    index index.html;
    
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location / {
        try_files $uri /index.html;
    }
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
}
EOFNGINX

rm -f /etc/nginx/sites-enabled/*
ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/sunnysiouxcare
nginx -t >/dev/null 2>&1 && systemctl reload nginx
echo "   ✓ Nginx настроен"

ufw allow 22 80 443 25 587 993 >/dev/null 2>&1
echo "y" | ufw enable >/dev/null 2>&1

###############################################################################
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                    ✅ ГОТОВО!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Сайт: http://$(hostname -I | awk '{print $1}') (по IP)"
echo "   Домен: https://sunnysiouxcare.com (после DNS)"
echo ""
echo "📧 Email: info@sunnysiouxcare.com"
echo "   Пароль: $EMAIL_PASS"
echo ""
echo "🔧 Команды:"
echo "   pm2 status"
echo "   pm2 logs"
echo "   curl http://localhost:8001/api/status"
echo ""
echo "📋 Следующий шаг - SSL (после DNS):"
echo "   certbot --nginx -d sunnysiouxcare.com -d www.sunnysiouxcare.com"
echo ""
echo "════════════════════════════════════════════════════════════════"
