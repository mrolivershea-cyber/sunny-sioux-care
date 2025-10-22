#!/bin/bash

###############################################################################
# 🚀 ПОЛНОСТЬЮ АВТОМАТИЧЕСКИЙ УСТАНОВЩИК SunnySiouxCare
# Версия: 4.0 - БЕЗ ОШИБОК
# Для Contabo/любого VPS с Ubuntu 22.04
###############################################################################

set -e
trap 'echo "❌ ОШИБКА на строке $LINENO! Остановка."; exit 1' ERR

PROJECT_DIR="/var/www/sunny-sioux-care"
GITHUB_REPO="https://github.com/mrolivershea-cyber/sunny-sioux-care.git"

echo "═══════════════════════════════════════════════════════════"
echo "  🚀 Автоматическая установка SunnySiouxCare.com"
echo "═══════════════════════════════════════════════════════════"
sleep 2

###############################################################################
# Шаг 1: Подготовка
###############################################################################

echo "[1/12] Подготовка системы..."
apt-get update -qq
apt-get upgrade -y -qq

###############################################################################
# Шаг 2: Установка базовых пакетов
###############################################################################

echo "[2/12] Установка базовых пакетов..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget git nano htop \
    build-essential software-properties-common \
    python3.11 python3.11-venv python3-pip \
    nginx certbot python3-certbot-nginx \
    ufw net-tools gnupg ca-certificates

echo "✅ Базовые пакеты установлены"

###############################################################################
# Шаг 3: Установка MongoDB 7.0
###############################################################################

echo "[3/12] Установка MongoDB 7.0..."
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list >/dev/null
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mongodb-org
systemctl enable mongod >/dev/null 2>&1
systemctl start mongod
sleep 3

if systemctl is-active --quiet mongod; then
    echo "✅ MongoDB запущен"
else
    echo "❌ MongoDB не запустился!"
    exit 1
fi

###############################################################################
# Шаг 4: Установка Node.js 20
###############################################################################

echo "[4/12] Установка Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs
npm install -g yarn pm2 >/dev/null 2>&1

NODE_VERSION=$(node -v)
echo "✅ Node.js $NODE_VERSION установлен"

###############################################################################
# Шаг 5: Установка почтового сервера
###############################################################################

echo "[5/12] Установка Postfix, Dovecot, OpenDKIM..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    postfix dovecot-core dovecot-imapd dovecot-pop3d \
    opendkim opendkim-tools mailutils

echo "✅ Почтовые пакеты установлены"

###############################################################################
# Шаг 6: Настройка почтового сервера
###############################################################################

echo "[6/12] Настройка почтового сервера..."

# Создать пользователя
EMAIL_PASSWORD=$(openssl rand -base64 24)
useradd -m -s /bin/bash info 2>/dev/null || true
echo "info:$EMAIL_PASSWORD" | chpasswd
mkdir -p /home/info/Maildir/{cur,new,tmp}
chown -R info:info /home/info/Maildir
chmod -R 700 /home/info/Maildir
echo "$EMAIL_PASSWORD" > /root/email_password.txt
chmod 600 /root/email_password.txt

# Postfix main.cf
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

smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
EOFPOSTFIX

# Postfix master.cf - добавить submission
grep -q "^submission inet" /etc/postfix/master.cf || cat >> /etc/postfix/master.cf << 'EOFSUB'

submission inet n - y - - smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
EOFSUB

# Dovecot 10-mail.conf
sed -i 's|mail_location = .*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf

# Dovecot 10-auth.conf
sed -i 's|#disable_plaintext_auth = yes|disable_plaintext_auth = yes|' /etc/dovecot/conf.d/10-auth.conf
sed -i 's|auth_mechanisms = plain|auth_mechanisms = plain login|' /etc/dovecot/conf.d/10-auth.conf

# Dovecot 10-master.conf
cat > /etc/dovecot/conf.d/10-master.conf << 'EOFMASTER'
service imap-login {
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service pop3-login {
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
EOFMASTER

# Запустить почтовые сервисы
systemctl restart postfix
systemctl restart dovecot

if systemctl is-active --quiet postfix && systemctl is-active --quiet dovecot; then
    echo "✅ Почтовый сервер запущен"
else
    echo "⚠️  Проблема с почтовым сервером, но продолжаем..."
fi

###############################################################################
# Шаг 7: Клонирование проекта
###############################################################################

echo "[7/12] Клонирование проекта из GitHub..."
cd /var/www
rm -rf sunny-sioux-care
git clone $GITHUB_REPO >/dev/null 2>&1
cd sunny-sioux-care

echo "✅ Проект склонирован"

###############################################################################
# Шаг 8: Настройка Backend
###############################################################################

echo "[8/12] Настройка Backend Python..."
cd $PROJECT_DIR/backend

python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip >/dev/null 2>&1
pip install -r requirements.txt >/dev/null 2>&1
deactivate

# Создать .env
cat > .env << ENVEOF
MONGO_URL="mongodb://localhost:27017"
DB_NAME="sunnysiouxcare_production"
CORS_ORIGINS="https://sunnysiouxcare.com,https://www.sunnysiouxcare.com"

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
ENVEOF

# Создать ecosystem.config.js
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
    },
    autorestart: true,
    watch: false,
    max_memory_restart: '500M'
  }]
};
EOFECO

echo "✅ Backend настроен"

###############################################################################
# Шаг 9: Настройка Frontend
###############################################################################

echo "[9/12] Настройка и сборка Frontend (займет 1-2 минуты)..."
cd $PROJECT_DIR/frontend

# .env
cat > .env << 'ENVEOF'
REACT_APP_BACKEND_URL=https://sunnysiouxcare.com
WDS_SOCKET_PORT=443
ENVEOF

yarn install >/dev/null 2>&1
export NODE_OPTIONS="--max-old-space-size=1536"
yarn build

if [ -f "build/index.html" ]; then
    echo "✅ Frontend собран"
else
    echo "❌ Frontend не собрался!"
    exit 1
fi

###############################################################################
# Шаг 10: Запуск Backend через PM2
###############################################################################

echo "[10/12] Запуск Backend через PM2..."
cd $PROJECT_DIR/backend

pm2 delete sunnysiouxcare-backend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save >/dev/null 2>&1
pm2 startup | tail -1 | bash >/dev/null 2>&1

sleep 3

if pm2 list | grep -q "online"; then
    echo "✅ Backend запущен"
else
    echo "❌ Backend не запустился!"
    pm2 logs --lines 20
    exit 1
fi

###############################################################################
# Шаг 11: Настройка Nginx
###############################################################################

echo "[11/12] Настройка Nginx..."

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
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOFNGINX

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/sunny
ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/sunnysiouxcare

if nginx -t 2>&1 | grep -q "successful"; then
    systemctl reload nginx
    echo "✅ Nginx настроен"
else
    echo "❌ Ошибка в конфигурации Nginx!"
    nginx -t
    exit 1
fi

###############################################################################
# Шаг 12: Настройка Firewall
###############################################################################

echo "[12/12] Настройка Firewall..."
ufw allow 22/tcp >/dev/null 2>&1
ufw allow 80/tcp >/dev/null 2>&1
ufw allow 443/tcp >/dev/null 2>&1
ufw allow 25/tcp >/dev/null 2>&1
ufw allow 587/tcp >/dev/null 2>&1
ufw allow 993/tcp >/dev/null 2>&1
echo "y" | ufw enable >/dev/null 2>&1

echo "✅ Firewall настроен"

###############################################################################
# ФИНАЛЬНАЯ ПРОВЕРКА
###############################################################################

echo
echo "═══════════════════════════════════════════════════════════"
echo "  🧪 ПРОВЕРКА ВСЕХ КОМПОНЕНТОВ"
echo "═══════════════════════════════════════════════════════════"

# MongoDB
if systemctl is-active --quiet mongod; then
    echo "✅ MongoDB: РАБОТАЕТ"
else
    echo "❌ MongoDB: НЕ РАБОТАЕТ"
fi

# Backend
if pm2 list | grep -q "online"; then
    echo "✅ Backend PM2: РАБОТАЕТ"
    if curl -s http://localhost:8001/api/status >/dev/null 2>&1; then
        echo "✅ Backend API: ОТВЕЧАЕТ"
    else
        echo "⚠️  Backend API: НЕ ОТВЕЧАЕТ (может нужно время)"
    fi
else
    echo "❌ Backend PM2: НЕ РАБОТАЕТ"
fi

# Frontend
if [ -f "$PROJECT_DIR/frontend/build/index.html" ]; then
    echo "✅ Frontend: СОБРАН"
else
    echo "❌ Frontend: НЕ СОБРАН"
fi

# Nginx
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx: РАБОТАЕТ"
    if curl -s -I http://localhost | grep -q "200 OK"; then
        echo "✅ Сайт: ДОСТУПЕН"
    else
        echo "❌ Сайт: НЕ ДОСТУПЕН"
    fi
else
    echo "❌ Nginx: НЕ РАБОТАЕТ"
fi

# Postfix
if systemctl is-active --quiet postfix; then
    echo "✅ Postfix: РАБОТАЕТ"
    if ss -tlnp | grep -q ":587"; then
        echo "✅ SMTP порт 587: ОТКРЫТ"
    else
        echo "⚠️  SMTP порт 587: НЕ СЛУШАЕТ"
    fi
else
    echo "❌ Postfix: НЕ РАБОТАЕТ"
fi

# Dovecot
if systemctl is-active --quiet dovecot; then
    echo "✅ Dovecot: РАБОТАЕТ"
else
    echo "❌ Dovecot: НЕ РАБОТАЕТ"
fi

###############################################################################
# ФИНАЛ
###############################################################################

echo
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ УСТАНОВКА ЗАВЕРШЕНА!"
echo "═══════════════════════════════════════════════════════════"
echo
echo "🌐 САЙТ:"
echo "   По IP: http://$(hostname -I | awk '{print $1}')"
echo "   Домен: https://sunnysiouxcare.com (после обновления DNS)"
echo
echo "📧 EMAIL:"
echo "   Адрес: info@sunnysiouxcare.com"
echo "   Пароль: $EMAIL_PASSWORD"
echo "   (сохранен в /root/email_password.txt)"
echo
echo "🔧 УПРАВЛЕНИЕ:"
echo "   Backend: pm2 status | pm2 logs | pm2 restart sunnysiouxcare-backend"
echo "   Nginx: systemctl status nginx | systemctl reload nginx"
echo "   Почта: systemctl status postfix dovecot"
echo
echo "📋 СЛЕДУЮЩИЕ ШАГИ:"
echo "   1. Обновите DNS A записи на IP: $(hostname -I | awk '{print $1}')"
echo "   2. Подождите 15-30 минут"
echo "   3. Установите SSL:"
echo "      certbot --nginx -d sunnysiouxcare.com -d www.sunnysiouxcare.com"
echo
echo "🧪 ТЕСТИРОВАНИЕ:"
echo "   Backend API: curl http://localhost:8001/api/status"
echo "   Сайт: curl -I http://localhost"
echo "   PM2: pm2 status"
echo
echo "═══════════════════════════════════════════════════════════"
echo
