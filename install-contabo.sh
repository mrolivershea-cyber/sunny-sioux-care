#!/bin/bash

###############################################################################
# 🚀 Полный установочный скрипт SunnySiouxCare для Contabo сервера
# IP: 154.53.46.148
# Домен: sunnysiouxcare.com
# Версия: 3.0
# Дата: 21 октября 2025
###############################################################################

set -e

# Конфигурация
PROJECT_DIR="/var/www/sunny-sioux-care"
GITHUB_REPO="https://github.com/mrolivershea-cyber/sunny-sioux-care.git"
DOMAIN="sunnysiouxcare.com"
SERVER_IP="154.53.46.148"
EMAIL_USER="info"
EMAIL_DOMAIN="sunnysiouxcare.com"
EMAIL_PASSWORD=$(openssl rand -base64 24)

echo "═══════════════════════════════════════════════════════════"
echo "  🚀 Установка SunnySiouxCare.com на Contabo"
echo "  IP: $SERVER_IP | Домен: $DOMAIN"
echo "═══════════════════════════════════════════════════════════"
echo

###############################################################################
# 1. Обновление системы
###############################################################################

echo "[1/10] Обновление системы..."
apt-get update -qq
apt-get upgrade -y

###############################################################################
# 2. Установка системных зависимостей
###############################################################################

echo "[2/10] Установка зависимостей (Node.js 20, Python 3.11, MongoDB)..."

# Базовые пакеты
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl wget git nano htop \
    build-essential software-properties-common \
    python3.11 python3.11-venv python3-pip \
    nginx certbot python3-certbot-nginx \
    ufw net-tools

# Node.js 20
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'.' -f1 | sed 's/v//')" -lt 20 ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

# Yarn
npm install -g yarn pm2

# MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update -qq
apt-get install -y mongodb-org
systemctl enable mongod
systemctl start mongod

echo "✅ Зависимости установлены"

###############################################################################
# 3. Установка почтового сервера
###############################################################################

echo "[3/10] Установка почтового сервера (Postfix + Dovecot + OpenDKIM)..."

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postfix dovecot-core dovecot-imapd dovecot-pop3d \
    opendkim opendkim-tools mailutils

# Создать почтового пользователя
useradd -m -s /bin/bash "$EMAIL_USER" 2>/dev/null || true
echo "$EMAIL_USER:$EMAIL_PASSWORD" | chpasswd
mkdir -p /home/$EMAIL_USER/Maildir/{cur,new,tmp}
chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir
chmod -R 700 /home/$EMAIL_USER/Maildir

# Настроить Postfix
cat > /etc/postfix/main.cf << EOF
myhostname = mail.$EMAIL_DOMAIN
mydomain = $EMAIL_DOMAIN
myorigin = \$mydomain
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
inet_interfaces = all
inet_protocols = all
home_mailbox = Maildir/

# TLS
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level=may

# SASL
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes

# Relay
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination

# Aliases
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
EOF

# Submission порт
cat >> /etc/postfix/master.cf << EOF

submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
EOF

# Настроить Dovecot
sed -i 's/mail_location = .*/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = yes/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf

# Dovecot auth для Postfix
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

# OpenDKIM
mkdir -p /etc/opendkim/keys/$EMAIL_DOMAIN
cd /etc/opendkim/keys/$EMAIL_DOMAIN
opendkim-genkey -b 2048 -d $EMAIL_DOMAIN -s mail
chown opendkim:opendkim mail.private
chmod 600 mail.private

cat > /etc/opendkim.conf << EOF
Syslog yes
Domain $EMAIL_DOMAIN
Selector mail
KeyFile /etc/opendkim/keys/$EMAIL_DOMAIN/mail.private
Socket inet:8891@localhost
UserID opendkim:opendkim
EOF

echo "127.0.0.1
localhost
$EMAIL_DOMAIN
mail.$EMAIL_DOMAIN
$SERVER_IP" > /etc/opendkim/TrustedHosts

# Добавить OpenDKIM в Postfix
postconf -e 'milter_default_action = accept'
postconf -e 'milter_protocol = 6'
postconf -e 'smtpd_milters = inet:localhost:8891'
postconf -e 'non_smtpd_milters = inet:localhost:8891'

# Запустить почтовые сервисы
systemctl restart postfix dovecot
mkdir -p /run/opendkim
chown opendkim:opendkim /run/opendkim
opendkim -x /etc/opendkim.conf

# Сохранить DKIM ключ для DNS
DKIM_KEY=$(cat /etc/opendkim/keys/$EMAIL_DOMAIN/mail.txt | grep -v "^mail._domainkey" | tr -d '\n\t "' | sed 's/.*p=/p=/')

echo "✅ Почтовый сервер установлен"
echo "📧 Email: $EMAIL_USER@$EMAIL_DOMAIN"
echo "🔐 Пароль: $EMAIL_PASSWORD"
echo ""
echo "Сохраните пароль: $EMAIL_PASSWORD" > /root/email_password.txt
chmod 600 /root/email_password.txt

###############################################################################
# 4. Клонирование проекта
###############################################################################

echo "[4/10] Клонирование проекта с GitHub..."
mkdir -p /var/www
cd /var/www
git clone $GITHUB_REPO sunny-sioux-care
cd sunny-sioux-care

echo "✅ Проект склонирован"

###############################################################################
# 5. Настройка Backend
###############################################################################

echo "[5/10] Настройка Backend..."
cd $PROJECT_DIR/backend

# Создать виртуальное окружение
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# Создать .env
cat > .env << ENVEOF
MONGO_URL="mongodb://localhost:27017"
DB_NAME="sunnysiouxcare_production"
CORS_ORIGINS="https://$DOMAIN,https://www.$DOMAIN"

# PayPal Configuration
PAYPAL_CLIENT_ID="AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg"
PAYPAL_CLIENT_SECRET="ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x"
PAYPAL_MODE="live"

# Email Configuration
EMAIL_ENABLED="true"
SMTP_HOST="localhost"
SMTP_PORT="587"
SMTP_USER="$EMAIL_USER"
SMTP_PASSWORD="$EMAIL_PASSWORD"
FROM_EMAIL="$EMAIL_USER@$EMAIL_DOMAIN"
ADMIN_EMAIL="$EMAIL_USER@$EMAIL_DOMAIN"
ENVEOF

echo "✅ Backend настроен"

###############################################################################
# 6. Настройка Frontend
###############################################################################

echo "[6/10] Настройка Frontend..."
cd $PROJECT_DIR/frontend

# Создать .env
cat > .env << ENVEOF
REACT_APP_BACKEND_URL=https://$DOMAIN
WDS_SOCKET_PORT=443
REACT_APP_ENABLE_VISUAL_EDITS=false
ENABLE_HEALTH_CHECK=false
ENVEOF

# Установить зависимости
yarn install

# Собрать с ограничением памяти
echo "[6/10] Сборка Frontend (может занять 1-2 минуты)..."
export NODE_OPTIONS="--max-old-space-size=1024"
yarn build

echo "✅ Frontend собран"

###############################################################################
# 7. Настройка PM2
###############################################################################

echo "[7/10] Настройка PM2..."

# Создать ecosystem.config.js если не существует
if [ ! -f "$PROJECT_DIR/backend/ecosystem.config.js" ]; then
cat > $PROJECT_DIR/backend/ecosystem.config.js << 'EOFPM2'
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
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M'
  }]
};
EOFPM2
fi

cd $PROJECT_DIR/backend
pm2 start ecosystem.config.js
pm2 save
pm2 startup

echo "✅ PM2 настроен"

###############################################################################
# 8. Настройка Nginx
###############################################################################

echo "[8/10] Настройка Nginx..."

cat > /etc/nginx/sites-available/sunnysiouxcare << EOFNGINX
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    root $PROJECT_DIR/frontend/build;
    index index.html;
    
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
    
    location / {
        try_files \$uri /index.html;
    }
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOFNGINX

ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx

echo "✅ Nginx настроен"

###############################################################################
# 9. Настройка SSL
###############################################################################

echo "[9/10] Установка SSL сертификата..."

# Подождать пока DNS обновится
echo "Проверка DNS для $DOMAIN..."
if dig +short $DOMAIN | grep -q "$SERVER_IP"; then
    certbot --nginx -d $DOMAIN -d www.$DOMAIN \
        --non-interactive --agree-tos \
        --email info@$DOMAIN \
        --redirect
    echo "✅ SSL установлен"
else
    echo "⚠️  DNS еще не обновился. Запустите позже:"
    echo "   certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi

###############################################################################
# 10. Настройка Firewall
###############################################################################

echo "[10/10] Настройка Firewall..."

ufw allow ssh
ufw allow http
ufw allow https
ufw allow 25/tcp   # SMTP
ufw allow 587/tcp  # SMTP Submission
ufw allow 993/tcp  # IMAP SSL
ufw allow 995/tcp  # POP3 SSL
echo "y" | ufw enable

echo "✅ Firewall настроен"

###############################################################################
# Финал
###############################################################################

sleep 3

echo
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "═══════════════════════════════════════════════════════════"
echo
echo "🌐 Сайт: https://$DOMAIN"
echo "📧 Email: $EMAIL_USER@$EMAIL_DOMAIN"
echo "🔐 Email пароль: $EMAIL_PASSWORD"
echo "   (сохранен в /root/email_password.txt)"
echo
echo "📋 DNS ЗАПИСИ (добавьте в Namecheap):"
echo
echo "1. A Record:"
echo "   Host: @     Value: $SERVER_IP"
echo "   Host: www   Value: $SERVER_IP"
echo "   Host: mail  Value: $SERVER_IP"
echo
echo "2. MX Record:"
echo "   Host: @  Value: mail.$EMAIL_DOMAIN  Priority: 10"
echo
echo "3. SPF (TXT Record):"
echo "   Host: @  Value: v=spf1 ip4:$SERVER_IP a mx ~all"
echo
echo "4. DKIM (TXT Record):"
echo "   Host: mail._domainkey"
echo "   Value: $DKIM_KEY"
echo
echo "5. DMARC (TXT Record):"
echo "   Host: _dmarc"
echo "   Value: v=DMARC1; p=quarantine; rua=mailto:$EMAIL_USER@$EMAIL_DOMAIN"
echo
echo "═══════════════════════════════════════════════════════════"
echo "🔍 Проверка статуса:"
echo "   pm2 status"
echo "   systemctl status nginx"
echo "   systemctl status postfix dovecot mongod"
echo
echo "📝 Логи:"
echo "   pm2 logs"
echo "   tail -f /var/log/nginx/error.log"
echo
echo "🔄 Обновление в будущем:"
echo "   cd $PROJECT_DIR && bash update-from-github.sh"
echo "═══════════════════════════════════════════════════════════"
echo
