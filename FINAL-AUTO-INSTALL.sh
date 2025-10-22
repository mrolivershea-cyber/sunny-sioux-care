#!/bin/bash

################################################################################
# ФИНАЛЬНЫЙ АВТОУСТАНОВЩИК SUNNYSIOUXCARE v7.0
# Полная автоматическая установка + проверки + SSL
# Для Ubuntu 22.04 LTS
################################################################################

set -e
exec > >(tee /root/install-log-$(date +%Y%m%d-%H%M%S).log)
exec 2>&1

clear
echo "════════════════════════════════════════════════════════════════"
echo "    🚀 SUNNYSIOUXCARE.COM - ПОЛНАЯ АВТОУСТАНОВКА"
echo "════════════════════════════════════════════════════════════════"
sleep 2

EMAIL_PASS=$(openssl rand -base64 24)
SERVER_IP=$(hostname -I | awk '{print $1}')

################################################################################
echo "► [1/12] Обновление системы..."
################################################################################
apt-get update -qq 2>&1 | grep -v "^Get:" | grep -v "^Hit:" || true
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq 2>&1 >/dev/null
echo "   ✓ Система обновлена"

################################################################################
echo "► [2/12] Базовые пакеты..."
################################################################################
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget git nano \
    build-essential \
    python3.11 python3.11-venv python3-pip \
    nginx \
    certbot python3-certbot-nginx \
    ufw \
    gnupg \
    ca-certificates \
    2>&1 >/dev/null

# Проверка certbot
if command -v certbot >/dev/null 2>&1; then
    echo "   ✓ Certbot установлен"
else
    echo "   ✗ Certbot не установился!"
    exit 1
fi

################################################################################
echo "► [3/12] MongoDB 7.0..."
################################################################################
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc 2>/dev/null | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg 2>/dev/null
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update -qq 2>&1 | grep -v "^Get:" | grep -v "^Hit:" || true
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mongodb-org 2>&1 >/dev/null
systemctl enable mongod >/dev/null 2>&1
systemctl start mongod
sleep 3

if systemctl is-active --quiet mongod; then
    echo "   ✓ MongoDB запущен"
else
    echo "   ✗ MongoDB не запустился!"
    exit 1
fi

################################################################################
echo "► [4/12] Node.js 20..."
################################################################################
curl -fsSL https://deb.nodesource.com/setup_20.x 2>/dev/null | bash - >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs 2>&1 >/dev/null
npm install -g yarn pm2 >/dev/null 2>&1
echo "   ✓ Node.js $(node -v)"

################################################################################
echo "► [5/12] Почтовый сервер..."
################################################################################
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    postfix dovecot-core dovecot-imapd dovecot-pop3d \
    opendkim opendkim-tools mailutils \
    2>&1 >/dev/null

useradd -m -s /bin/bash info 2>/dev/null || true
echo "info:$EMAIL_PASS" | chpasswd
mkdir -p /home/info/Maildir/{cur,new,tmp}
chown -R info:info /home/info/Maildir
chmod -R 700 /home/info/Maildir
echo "$EMAIL_PASS" > /root/email_password.txt
chmod 600 /root/email_password.txt
echo "   ✓ Почтовые пакеты установлены"

################################################################################
echo "► [6/12] Настройка Postfix и Dovecot..."
################################################################################

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
mailbox_size_limit = 0
recipient_delimiter = +

smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level=may

smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous

smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
EOFPOSTFIX

if ! grep -q "^submission inet" /etc/postfix/master.cf 2>/dev/null; then
cat >> /etc/postfix/master.cf << 'EOFSUBMISSION'

submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
EOFSUBMISSION
fi

sed -i 's|mail_location = .*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf 2>/dev/null || true
sed -i 's|#disable_plaintext_auth = yes|disable_plaintext_auth = yes|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true
sed -i 's|auth_mechanisms = plain|auth_mechanisms = plain login|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true

cat > /etc/dovecot/conf.d/10-master.conf << 'EOFDOVECOT'
service imap-login {
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOFDOVECOT

systemctl restart postfix
systemctl restart dovecot

if systemctl is-active --quiet postfix && systemctl is-active --quiet dovecot; then
    echo "   ✓ Почта настроена и запущена"
else
    echo "   ✗ Проблема с почтой!"
fi

################################################################################
echo "► [7/12] Клонирование GitHub..."
################################################################################
cd /var/www
rm -rf sunny-sioux-care 2>/dev/null || true
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git 2>&1 | grep -E "Cloning|done" || true
echo "   ✓ Проект склонирован"

################################################################################
echo "► [8/12] Backend setup..."
################################################################################
cd /var/www/sunny-sioux-care/backend
python3.11 -m venv venv
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
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
    env: {
      PYTHONPATH: '/var/www/sunny-sioux-care/backend'
    }
  }]
};
EOFECO

echo "   ✓ Backend настроен"

################################################################################
echo "► [9/12] Frontend build..."
################################################################################
cd /var/www/sunny-sioux-care/frontend

cat > .env << 'EOFENV'
REACT_APP_BACKEND_URL=https://sunnysiouxcare.com
EOFENV

yarn install 2>&1 | grep -E "success|Done" || true
export NODE_OPTIONS="--max-old-space-size=1536"
yarn build 2>&1 | grep -E "Compiled|File sizes|Done in" || true

if [ -f "build/index.html" ]; then
    echo "   ✓ Frontend собран"
else
    echo "   ✗ Frontend не собрался!"
    exit 1
fi

################################################################################
echo "► [10/12] PM2 запуск..."
################################################################################
cd /var/www/sunny-sioux-care/backend
pm2 delete all 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save >/dev/null 2>&1
pm2 startup 2>/dev/null | tail -1 | bash >/dev/null 2>&1 || true
sleep 3

if pm2 list | grep -q "online"; then
    echo "   ✓ Backend запущен"
else
    echo "   ✗ Backend не запустился!"
    exit 1
fi

################################################################################
echo "► [11/12] Nginx..."
################################################################################

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

if nginx -t 2>&1 | grep -q "successful"; then
    systemctl reload nginx
    echo "   ✓ Nginx настроен"
else
    echo "   ✗ Ошибка Nginx!"
    exit 1
fi

################################################################################
echo "► [12/12] SSL сертификат..."
################################################################################

# Проверить что certbot установлен
if ! command -v certbot >/dev/null 2>&1; then
    echo "   ! Certbot не найден, устанавливаю..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
fi

# Проверить DNS
echo "   Проверка DNS для sunnysiouxcare.com..."
if dig +short sunnysiouxcare.com 2>/dev/null | grep -q "$SERVER_IP"; then
    echo "   ✓ DNS указывает на этот сервер"
    
    # Установить SSL
    certbot --nginx \
        -d sunnysiouxcare.com \
        -d www.sunnysiouxcare.com \
        --email info@sunnysiouxcare.com \
        --agree-tos \
        --non-interactive \
        --redirect 2>&1 | grep -E "Successfully|Congratulations" || true
    
    if [ -d "/etc/letsencrypt/live/sunnysiouxcare.com" ]; then
        echo "   ✓ SSL сертификат установлен"
    else
        echo "   ⚠️  SSL не установлен (возможно DNS еще не обновился)"
    fi
else
    echo "   ⚠️  DNS еще не указывает на $SERVER_IP"
    echo "   Установите SSL позже командой:"
    echo "   certbot --nginx -d sunnysiouxcare.com -d www.sunnysiouxcare.com"
fi

################################################################################
echo "► Firewall..."
################################################################################
ufw allow 22 80 443 25 587 993 995 >/dev/null 2>&1
echo "y" | ufw enable >/dev/null 2>&1
echo "   ✓ Firewall настроен"

################################################################################
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "              🧪 АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ"
echo "════════════════════════════════════════════════════════════════"
################################################################################

sleep 2

echo -n "► MongoDB.............. "
systemctl is-active --quiet mongod && echo "✅" || echo "❌"

echo -n "► Backend PM2.......... "
pm2 list 2>/dev/null | grep -q "online" && echo "✅" || echo "❌"

echo -n "► Backend API.......... "
sleep 2
curl -s http://localhost:8001/api/status >/dev/null 2>&1 && echo "✅" || echo "⚠️"

echo -n "► Frontend Build....... "
[ -f "/var/www/sunny-sioux-care/frontend/build/index.html" ] && echo "✅" || echo "❌"

echo -n "► Nginx................ "
systemctl is-active --quiet nginx && echo "✅" || echo "❌"

echo -n "► Сайт HTTP............ "
curl -s -I http://localhost 2>&1 | grep -q "200 OK" && echo "✅" || echo "❌"

echo -n "► Postfix.............. "
systemctl is-active --quiet postfix && echo "✅" || echo "❌"

echo -n "► SMTP порт 587........ "
ss -tlnp 2>/dev/null | grep -q ":587" && echo "✅" || echo "⚠️"

echo -n "► Dovecot.............. "
systemctl is-active --quiet dovecot && echo "✅" || echo "❌"

echo -n "► SSL сертификат....... "
[ -d "/etc/letsencrypt/live/sunnysiouxcare.com" ] && echo "✅" || echo "⚠️  (установите позже)"

################################################################################
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "              ✅ УСТАНОВКА ЗАВЕРШЕНА!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🌐 ВАШ САЙТ:"
echo "   IP:     http://$SERVER_IP"
echo "   Домен:  https://sunnysiouxcare.com"
echo ""
echo "📧 ПОЧТА:"
echo "   Email:    info@sunnysiouxcare.com"
echo "   Пароль:   $EMAIL_PASS"
echo "   Файл:     /root/email_password.txt"
echo ""
echo "   SMTP:     mail.sunnysiouxcare.com:587"
echo "   IMAP:     mail.sunnysiouxcare.com:993"
echo ""
echo "🔧 УПРАВЛЕНИЕ:"
echo "   pm2 status"
echo "   pm2 logs"
echo "   pm2 restart sunnysiouxcare-backend"
echo "   systemctl status nginx"
echo "   systemctl status postfix dovecot mongod"
echo ""
echo "🧪 ТЕСТЫ:"
echo "   curl http://localhost:8001/api/status"
echo "   curl -I http://$SERVER_IP"
echo "   curl -I https://sunnysiouxcare.com"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
pm2 status
echo ""
echo "📝 Лог установки: $(ls -t /root/install-log-*.log | head -1)"
echo ""
