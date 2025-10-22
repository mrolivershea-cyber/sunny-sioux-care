#!/bin/bash
###############################################################################
# АВТОУСТАНОВЩИК SUNNYSIOUXCARE v6.0 - ФИНАЛЬНАЯ ВЕРСИЯ
# Одна команда - полная установка
###############################################################################

set -e
exec > >(tee /root/install.log)
exec 2>&1

clear
echo "════════════════════════════════════════════════════════════════"
echo "    🚀 АВТОМАТИЧЕСКАЯ УСТАНОВКА SUNNYSIOUXCARE.COM"
echo "════════════════════════════════════════════════════════════════"
sleep 2

EMAIL_PASS=$(openssl rand -base64 24)

echo "[1/10] Обновление системы..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

echo "[2/10] Базовые пакеты..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl wget git build-essential python3.11 python3.11-venv python3-pip nginx certbot python3-certbot-nginx ufw gnupg ca-certificates

echo "[3/10] MongoDB 7.0..."
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mongodb-org
systemctl enable mongod && systemctl start mongod
sleep 3

echo "[4/10] Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs
npm install -g yarn pm2 >/dev/null 2>&1

echo "[5/10] Почтовый сервер..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postfix dovecot-core dovecot-imapd dovecot-pop3d opendkim opendkim-tools mailutils

useradd -m info 2>/dev/null || true
echo "info:$EMAIL_PASS" | chpasswd
mkdir -p /home/info/Maildir/{cur,new,tmp}
chown -R info:info /home/info/Maildir
echo "$EMAIL_PASS" > /root/email_password.txt

cat > /etc/postfix/main.cf << 'EOF'
myhostname = mail.sunnysiouxcare.com
mydomain = sunnysiouxcare.com
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
relayhost =
mynetworks = 127.0.0.0/8
inet_interfaces = all
inet_protocols = ipv4
home_mailbox = Maildir/
smtpd_tls_security_level=may
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
EOF

grep -q "^submission inet" /etc/postfix/master.cf || echo "submission inet n - y - - smtpd
  -o smtpd_sasl_auth_enable=yes" >> /etc/postfix/master.cf

sed -i 's|mail_location = .*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf
cat > /etc/dovecot/conf.d/10-master.conf << 'EOF'
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOF

systemctl restart postfix dovecot

echo "[6/10] Клонирование GitHub..."
cd /var/www
rm -rf sunny-sioux-care
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git >/dev/null 2>&1

echo "[7/10] Backend setup..."
cd /var/www/sunny-sioux-care/backend
python3.11 -m venv venv
source venv/bin/activate
pip install -q -r requirements.txt
deactivate

cat > .env << EOF
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
EOF

cat > ecosystem.config.js << 'EOF'
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
EOF

echo "[8/10] Frontend build..."
cd /var/www/sunny-sioux-care/frontend
cat > .env << 'EOF'
REACT_APP_BACKEND_URL=https://sunnysiouxcare.com
EOF

yarn install >/dev/null 2>&1
export NODE_OPTIONS="--max-old-space-size=1536"
yarn build

echo "[9/10] PM2 start..."
cd /var/www/sunny-sioux-care/backend
pm2 delete all 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save
pm2 startup | tail -1 | bash

echo "[10/10] Nginx..."
cat > /etc/nginx/sites-available/sunnysiouxcare << 'EOF'
server {
    listen 80;
    server_name sunnysiouxcare.com www.sunnysiouxcare.com;
    root /var/www/sunny-sioux-care/frontend/build;
    index index.html;
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location / {
        try_files $uri /index.html;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/*
ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

ufw allow 22 80 443 25 587 993 >/dev/null 2>&1
echo "y" | ufw enable >/dev/null 2>&1

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                    ✅ УСТАНОВКА ЗАВЕРШЕНА!"
echo "════════════════════════════════════════════════════════════════"
echo "🌐 http://$(hostname -I | awk '{print $1}')"
echo "📧 info@sunnysiouxcare.com | Пароль: $EMAIL_PASS"
echo "════════════════════════════════════════════════════════════════"
pm2 status
curl -I http://localhost | head -3
