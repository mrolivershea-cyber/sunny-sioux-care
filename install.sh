#!/bin/bash

##############################################
# Sunny Sioux Care - Автоматическая установка
# Версия: 1.0
##############################################

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║   Sunny Sioux Care - Auto Installer      ║"
echo "║   Версия 1.0                             ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Проверка root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ошибка: Запустите скрипт от root (sudo bash install.sh)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Запуск от root${NC}"

# Сбор информации
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Шаг 1: Сбор информации${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -p "Введите домен (например: sunnysiouxcare.com): " DOMAIN
read -p "Введите ваш email для SSL: " EMAIL

echo ""
echo -e "${YELLOW}MongoDB Atlas (бесплатный облачный MongoDB)${NC}"
echo "Получите на: https://www.mongodb.com/cloud/atlas/register"
echo "Пример: mongodb+srv://user:password@cluster0.xxxxx.mongodb.net/"
read -p "Введите MongoDB URL: " MONGO_URL

echo ""
echo -e "${YELLOW}PayPal Credentials${NC}"
read -p "PayPal Client ID: " PAYPAL_CLIENT_ID
read -p "PayPal Client Secret: " PAYPAL_SECRET

# Подтверждение
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Проверьте данные:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Домен: $DOMAIN"
echo "Email: $EMAIL"
echo "MongoDB URL: ${MONGO_URL:0:40}..."
echo "PayPal Client ID: ${PAYPAL_CLIENT_ID:0:20}..."
echo ""
read -p "Всё правильно? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}Установка отменена${NC}"
    exit 1
fi

# Начало установки
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Начинаем установку...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. Создание SWAP
echo ""
echo -e "${YELLOW}[1/10] Создание SWAP (2GB дополнительной памяти)...${NC}"
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo -e "${GREEN}✓ SWAP создан${NC}"
else
    echo -e "${GREEN}✓ SWAP уже существует${NC}"
fi

# 2. Обновление системы
echo ""
echo -e "${YELLOW}[2/10] Обновление системы...${NC}"
apt update -qq
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq
echo -e "${GREEN}✓ Система обновлена${NC}"

# 3. Установка базовых пакетов
echo ""
echo -e "${YELLOW}[3/10] Установка базовых пакетов...${NC}"
apt install -y -qq curl wget git nano ufw nginx software-properties-common
echo -e "${GREEN}✓ Базовые пакеты установлены${NC}"

# 4. Настройка Firewall
echo ""
echo -e "${YELLOW}[4/10] Настройка Firewall...${NC}"
ufw --force reset
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo -e "${GREEN}✓ Firewall настроен${NC}"

# 5. Установка Python 3.11
echo ""
echo -e "${YELLOW}[5/10] Установка Python 3.11...${NC}"
apt install -y -qq python3.11 python3.11-venv python3-pip
echo -e "${GREEN}✓ Python 3.11 установлен${NC}"

# 6. Установка Node.js, Yarn и PM2
echo ""
echo -e "${YELLOW}[6/10] Установка Node.js 18, Yarn и PM2...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt install -y -qq nodejs
npm install -g pm2 yarn > /dev/null 2>&1
echo -e "${GREEN}✓ Node.js, Yarn и PM2 установлены${NC}"

# 7. Клонирование проекта
echo ""
echo -e "${YELLOW}[7/10] Клонирование проекта с GitHub...${NC}"
cd /var/www
if [ -d "sunny-sioux-care" ]; then
    rm -rf sunny-sioux-care
fi
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git > /dev/null 2>&1
cd sunny-sioux-care
echo -e "${GREEN}✓ Проект клонирован${NC}"

# 8. Настройка Backend
echo ""
echo -e "${YELLOW}[8/10] Настройка Backend...${NC}"
cd /var/www/sunny-sioux-care/backend

# Создание virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Установка зависимостей
pip install --quiet --upgrade pip > /dev/null 2>&1
pip install --quiet -r requirements.txt > /dev/null 2>&1

# Создание .env файла
cat > .env << EOF
MONGO_URL="${MONGO_URL}"
DB_NAME="sunnysiouxcare"
CORS_ORIGINS="https://${DOMAIN},https://www.${DOMAIN}"
PAYPAL_CLIENT_ID="${PAYPAL_CLIENT_ID}"
PAYPAL_CLIENT_SECRET="${PAYPAL_SECRET}"
PAYPAL_MODE="live"
EMAIL_ENABLED="false"
SMTP_HOST="mail.${DOMAIN}"
SMTP_PORT="587"
SMTP_USER="info@${DOMAIN}"
SMTP_PASSWORD=""
FROM_EMAIL="noreply@${DOMAIN}"
ADMIN_EMAIL="info@${DOMAIN}"
EOF

# Создание PM2 ecosystem
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'sunnysiouxcare-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port 8001',
    cwd: '/var/www/sunny-sioux-care/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '200M',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
EOF

echo -e "${GREEN}✓ Backend настроен${NC}"

# 9. Сборка Frontend (локально с оптимизацией)
echo ""
echo -e "${YELLOW}[9/10] Сборка Frontend...${NC}"
cd /var/www/sunny-sioux-care/frontend

# Создание .env для frontend
cat > .env << EOF
REACT_APP_BACKEND_URL=https://${DOMAIN}
EOF

# Установка зависимостей с оптимизацией памяти
export NODE_OPTIONS="--max_old_space_size=400"
npm install --production --no-optional > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠ npm install не удался, пробуем yarn...${NC}"
    npm install -g yarn > /dev/null 2>&1
    yarn install --production --ignore-optional > /dev/null 2>&1
}

# Build
echo -e "${YELLOW}   Сборка может занять 2-3 минуты...${NC}"
npm run build > /dev/null 2>&1 || yarn build > /dev/null 2>&1 || {
    echo -e "${RED}✗ Сборка frontend не удалась${NC}"
    echo -e "${YELLOW}ℹ Скачайте собранный frontend с локального компьютера${NC}"
}

if [ -d "build" ]; then
    echo -e "${GREEN}✓ Frontend собран${NC}"
else
    echo -e "${YELLOW}⚠ Frontend не собран (недостаточно памяти)${NC}"
    echo -e "${YELLOW}ℹ Соберите локально: yarn build, затем загрузите на сервер${NC}"
fi

# 10. Настройка Nginx
echo ""
echo -e "${YELLOW}[10/10] Настройка Nginx...${NC}"

cat > /etc/nginx/sites-available/sunnysiouxcare << EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    root /var/www/sunny-sioux-care/frontend/build;
    index index.html;

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # React Router
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
}
EOF

# Активация сайта
ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверка конфигурации
nginx -t
systemctl reload nginx

echo -e "${GREEN}✓ Nginx настроен${NC}"

# Запуск Backend
echo ""
echo -e "${YELLOW}Запуск Backend...${NC}"
cd /var/www/sunny-sioux-care/backend
pm2 start ecosystem.config.js
pm2 save
pm2 startup | tail -1 | bash

echo -e "${GREEN}✓ Backend запущен${NC}"

# SSL сертификат
echo ""
echo -e "${YELLOW}Установка SSL сертификата...${NC}"
apt install -y -qq certbot python3-certbot-nginx
certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email ${EMAIL} --redirect

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL сертификат установлен${NC}"
else
    echo -e "${YELLOW}⚠ SSL сертификат не установлен (возможно DNS ещё не обновился)${NC}"
    echo -e "${YELLOW}ℹ Запустите позже: certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}${NC}"
fi

# Финал
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Установка завершена!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Ваш сайт:${NC} https://${DOMAIN}"
echo ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "  pm2 status              - статус backend"
echo "  pm2 logs                - логи backend"
echo "  pm2 restart all         - перезапуск backend"
echo "  systemctl status nginx  - статус nginx"
echo "  certbot renew           - обновить SSL"
echo ""
echo -e "${YELLOW}Проверьте:${NC}"
echo "  1. Откройте: https://${DOMAIN}"
echo "  2. Проверьте тарифы и оплату"
echo "  3. Проверьте форму контакта"
echo "  4. Проверьте donate кнопку"
echo ""
echo -e "${GREEN}Готово! 🎉${NC}"
