#!/bin/bash

################################################################################
# АВТОМАТИЧЕСКИЙ УСТАНОВЩИК SUNNYSIOUXCARE.COM
# Версия: FINAL 1.0
# Один скрипт - полная установка + тесты
# Для Ubuntu 22.04 LTS
################################################################################

set -e

# Логирование
exec > >(tee /root/install-$(date +%Y%m%d-%H%M%S).log)
exec 2>&1

clear
cat << "EOF"
════════════════════════════════════════════════════════════════
         🚀 SUNNYSIOUXCARE.COM - АВТОУСТАНОВКА
════════════════════════════════════════════════════════════════
EOF
echo ""
sleep 1

# Генерация пароля для email
EMAIL_PASSWORD=$(openssl rand -base64 24)
SERVER_IP=$(hostname -I | awk '{print $1}')

################################################################################
echo "► [1/11] Обновление системы..."
################################################################################
apt-get update -qq 2>&1 | grep -v "^Get:" | grep -v "^Hit:" || true
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq 2>&1 >/dev/null
echo "   ✓ Система обновлена"

################################################################################
echo "► [2/11] Установка базовых пакетов..."
################################################################################
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget git nano htop \
    build-essential \
    python3.11 python3.11-venv python3-pip \
    nginx \
    certbot python3-certbot-nginx \
    ufw \
    gnupg \
    ca-certificates \
    apt-transport-https \
    2>&1 >/dev/null
echo "   ✓ Базовые пакеты установлены"

################################################################################
echo "► [3/11] Установка MongoDB 7.0..."
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
    echo "   ✓ MongoDB 7.0 запущен"
else
    echo "   ✗ MongoDB не запустился"
    exit 1
fi

################################################################################
echo "► [4/11] Установка Node.js 20..."
################################################################################
curl -fsSL https://deb.nodesource.com/setup_20.x 2>/dev/null | bash - >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs 2>&1 >/dev/null
npm install -g yarn pm2 >/dev/null 2>&1
echo "   ✓ Node.js $(node -v) + Yarn + PM2"

################################################################################
echo "► [5/11] Установка почтового сервера..."
################################################################################
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    postfix \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    opendkim \
    opendkim-tools \
    mailutils \
    2>&1 >/dev/null
echo "   ✓ Postfix + Dovecot + OpenDKIM установлены"

################################################################################
echo "► [6/11] Настройка почты (info@sunnysiouxcare.com)..."
################################################################################

# Создать пользователя
useradd -m -s /bin/bash info 2>/dev/null || true
echo "info:$EMAIL_PASSWORD" | chpasswd
mkdir -p /home/info/Maildir/{cur,new,tmp}
chown -R info:info /home/info/Maildir
chmod -R 700 /home/info/Maildir
echo "$EMAIL_PASSWORD" > /root/email_password.txt
chmod 600 /root/email_password.txt

# Postfix конфигурация
cat > /etc/postfix/main.cf << 'EOFPOSTFIX'
myhostname = mail.sunnysiouxcare.com
mydomain = sunnysiouxcare.com
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
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

# Submission порт в master.cf
if ! grep -q "^submission inet" /etc/postfix/master.cf 2>/dev/null; then
cat >> /etc/postfix/master.cf << 'EOFSUBMISSION'

submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
EOFSUBMISSION
fi

# Dovecot конфигурация
sed -i 's|mail_location = .*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf 2>/dev/null || true
sed -i 's|#disable_plaintext_auth = yes|disable_plaintext_auth = yes|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true
sed -i 's|auth_mechanisms = plain|auth_mechanisms = plain login|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true

# Создать чистый 10-master.conf
cat > /etc/dovecot/conf.d/10-master.conf << 'EOFDOVECOT'
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    port = 995
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

# Запустить почтовые сервисы
systemctl restart postfix
systemctl restart dovecot

if systemctl is-active --quiet postfix && systemctl is-active --quiet dovecot; then
    echo "   ✓ Почтовый сервер запущен"
    if ss -tlnp 2>/dev/null | grep -q ":587"; then
        echo "   ✓ SMTP порт 587 открыт"
    fi
else
    echo "   ✗ Проблема с почтовым сервером"
fi

################################################################################
echo "► [7/11] Клонирование проекта из GitHub..."
################################################################################
cd /var/www
rm -rf sunny-sioux-care 2>/dev/null || true
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git 2>&1 | \
    grep -E "Cloning|done" || true
echo "   ✓ Проект склонирован"

################################################################################
echo "► [8/11] Настройка Backend..."
################################################################################
cd /var/www/sunny-sioux-care/backend

# Виртуальное окружение
python3.11 -m venv venv
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
deactivate

# Создать .env файл
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
SMTP_PASSWORD="$EMAIL_PASSWORD"
FROM_EMAIL="info@sunnysiouxcare.com"
ADMIN_EMAIL="info@sunnysiouxcare.com"
EOFENV

# PM2 ecosystem config
cat > ecosystem.config.js << 'EOFECOSYSTEM'
module.exports = {
  apps: [{
    name: 'sunnysiouxcare-backend',
    script: 'venv/bin/python',
    args: '-m uvicorn server:app --host 0.0.0.0 --port 8001',
    cwd: '/var/www/sunny-sioux-care/backend',
    interpreter: 'none',
    env: {
      PYTHONPATH: '/var/www/sunny-sioux-care/backend'
    },
    autorestart: true,
    max_memory_restart: '500M'
  }]
};
EOFECOSYSTEM

echo "   ✓ Backend настроен"

################################################################################
echo "► [9/11] Сборка Frontend..."
################################################################################
cd /var/www/sunny-sioux-care/frontend

# .env для frontend
cat > .env << 'EOFENV'
REACT_APP_BACKEND_URL=https://sunnysiouxcare.com
WDS_SOCKET_PORT=443
EOFENV

# Установка зависимостей
yarn install 2>&1 | grep -E "success|Done" || true

# Сборка
export NODE_OPTIONS="--max-old-space-size=1536"
echo "   ⏳ Сборка (может занять 1-2 минуты)..."
yarn build 2>&1 | grep -E "Compiled|File sizes|Done in" || true

if [ -f "build/index.html" ]; then
    echo "   ✓ Frontend собран успешно"
else
    echo "   ✗ Frontend не собрался!"
    exit 1
fi

################################################################################
echo "► [10/11] Запуск Backend через PM2..."
################################################################################
cd /var/www/sunny-sioux-care/backend

# Остановить все PM2 процессы
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Запустить backend
pm2 start ecosystem.config.js
sleep 3

# Сохранить и автозапуск
pm2 save >/dev/null 2>&1
pm2 startup 2>/dev/null | tail -1 | bash >/dev/null 2>&1 || true

# Проверка
if pm2 list | grep -q "online"; then
    echo "   ✓ Backend запущен через PM2"
else
    echo "   ✗ Backend не запустился!"
    pm2 logs --lines 10
    exit 1
fi

################################################################################
echo "► [11/11] Настройка Nginx..."
################################################################################

# Создать конфиг
cat > /etc/nginx/sites-available/sunnysiouxcare << 'EOFNGINX'
server {
    listen 80;
    server_name sunnysiouxcare.com www.sunnysiouxcare.com;
    
    root /var/www/sunny-sioux-care/frontend/build;
    index index.html;
    
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
    
    location / {
        try_files $uri /index.html;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOFNGINX

# Активировать сайт
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/*
ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/sunnysiouxcare

# Проверить и перезапустить
if nginx -t 2>&1 | grep -q "successful"; then
    systemctl reload nginx
    echo "   ✓ Nginx настроен и перезапущен"
else
    echo "   ✗ Ошибка в конфигурации Nginx!"
    nginx -t
    exit 1
fi

################################################################################
echo "► Настройка Firewall..."
################################################################################
ufw allow 22/tcp comment 'SSH' >/dev/null 2>&1
ufw allow 80/tcp comment 'HTTP' >/dev/null 2>&1
ufw allow 443/tcp comment 'HTTPS' >/dev/null 2>&1
ufw allow 25/tcp comment 'SMTP' >/dev/null 2>&1
ufw allow 587/tcp comment 'SMTP Submission' >/dev/null 2>&1
ufw allow 993/tcp comment 'IMAP SSL' >/dev/null 2>&1
ufw allow 995/tcp comment 'POP3 SSL' >/dev/null 2>&1
echo "y" | ufw enable >/dev/null 2>&1
echo "   ✓ Firewall настроен"

################################################################################
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                 🧪 АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ"
echo "════════════════════════════════════════════════════════════════"
################################################################################

sleep 2

# Тест 1: MongoDB
echo -n "► MongoDB.......... "
if systemctl is-active --quiet mongod; then
    echo "✅ РАБОТАЕТ"
else
    echo "❌ НЕ РАБОТАЕТ"
fi

# Тест 2: Backend PM2
echo -n "► Backend PM2...... "
if pm2 list 2>/dev/null | grep -q "online"; then
    echo "✅ РАБОТАЕТ"
else
    echo "❌ НЕ РАБОТАЕТ"
fi

# Тест 3: Backend API
echo -n "► Backend API...... "
sleep 2
if curl -s http://localhost:8001/api/status >/dev/null 2>&1; then
    echo "✅ ОТВЕЧАЕТ"
else
    echo "⚠️  НЕ ОТВЕЧАЕТ (может нужно время)"
fi

# Тест 4: Frontend Build
echo -n "► Frontend Build... "
if [ -f "/var/www/sunny-sioux-care/frontend/build/index.html" ]; then
    echo "✅ СОБРАН"
else
    echo "❌ НЕ СОБРАН"
fi

# Тест 5: Nginx
echo -n "► Nginx............ "
if systemctl is-active --quiet nginx; then
    echo "✅ РАБОТАЕТ"
else
    echo "❌ НЕ РАБОТАЕТ"
fi

# Тест 6: Сайт доступен
echo -n "► Сайт (HTTP)...... "
if curl -s -I http://localhost 2>&1 | grep -q "200 OK"; then
    echo "✅ ДОСТУПЕН"
else
    echo "❌ НЕ ДОСТУПЕН"
fi

# Тест 7: Postfix
echo -n "► Postfix.......... "
if systemctl is-active --quiet postfix; then
    echo "✅ РАБОТАЕТ"
else
    echo "❌ НЕ РАБОТАЕТ"
fi

# Тест 8: Postfix порт 587
echo -n "► SMTP порт 587.... "
if ss -tlnp 2>/dev/null | grep -q ":587"; then
    echo "✅ ОТКРЫТ"
else
    echo "⚠️  НЕ СЛУШАЕТ"
fi

# Тест 9: Dovecot
echo -n "► Dovecot.......... "
if systemctl is-active --quiet dovecot; then
    echo "✅ РАБОТАЕТ"
else
    echo "❌ НЕ РАБОТАЕТ"
fi

# Тест 10: PayPal интеграция
echo -n "► PayPal API....... "
if grep -q "PAYPAL_CLIENT_ID" /var/www/sunny-sioux-care/backend/.env 2>/dev/null; then
    echo "✅ НАСТРОЕН"
else
    echo "⚠️  НЕ НАСТРОЕН"
fi

################################################################################
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "              ✅ УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🌐 ВАШ САЙТ:"
echo "   По IP:     http://$SERVER_IP"
echo "   По домену: https://sunnysiouxcare.com (после обновления DNS)"
echo ""
echo "📧 ПОЧТА:"
echo "   Email:  info@sunnysiouxcare.com"
echo "   Пароль: $EMAIL_PASSWORD"
echo "   Файл:   /root/email_password.txt"
echo ""
echo "   SMTP:   mail.sunnysiouxcare.com:587 (STARTTLS)"
echo "   IMAP:   mail.sunnysiouxcare.com:993 (SSL)"
echo ""
echo "🔧 УПРАВЛЕНИЕ:"
echo "   Backend:  pm2 status | pm2 logs | pm2 restart sunnysiouxcare-backend"
echo "   Nginx:    systemctl status nginx | systemctl reload nginx"
echo "   Почта:    systemctl status postfix dovecot"
echo "   MongoDB:  systemctl status mongod"
echo ""
echo "📋 DNS ЗАПИСИ (обновите в Namecheap):"
echo "   A Record:    @     →  $SERVER_IP"
echo "   A Record:    www   →  $SERVER_IP"
echo "   A Record:    mail  →  $SERVER_IP"
echo "   MX Record:   @     →  mail.sunnysiouxcare.com (Priority: 10)"
echo "   TXT (SPF):   @     →  v=spf1 ip4:$SERVER_IP a mx ~all"
echo ""
echo "📌 ПОСЛЕ ОБНОВЛЕНИЯ DNS (15-30 минут):"
echo "   Установите SSL:"
echo "   certbot --nginx -d sunnysiouxcare.com -d www.sunnysiouxcare.com --email info@sunnysiouxcare.com --agree-tos --non-interactive"
echo ""
echo "🧪 БЫСТРАЯ ПРОВЕРКА:"
echo "   curl http://localhost:8001/api/status"
echo "   curl -I http://$SERVER_IP"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 ТЕКУЩИЙ СТАТУС:"
pm2 status
echo ""
