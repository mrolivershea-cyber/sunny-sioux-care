# 🚀 SunnySiouxCare.com - Полная документация по развертыванию

## 📋 Содержание
1. [Обзор проекта](#обзор-проекта)
2. [Технологии](#технологии)
3. [Структура проекта](#структура-проекта)
4. [Требования к серверу](#требования-к-серверу)
5. [Инструкция по установке](#инструкция-по-установке)
6. [Конфигурация](#конфигурация)
7. [Интеграции](#интеграции)
8. [Развертывание](#развертывание)
9. [Обслуживание](#обслуживание)

---

## 📊 Обзор проекта

**Название:** SunnySiouxCare.com
**Тип:** Full-stack веб-приложение для центра детского ухода
**Адрес:** 2110 Summit St, Sioux City, IA 51104

**Основные функции:**
- Презентация услуг и программ по возрастным группам
- Система тарифов с интеграцией PayPal
- Регистрация на программы с автоматической отправкой инвойсов
- Форма обратной связи
- Кастомные инвойсы PayPal
- Donate кнопка для пожертвований
- Email уведомления (опционально)

---

## 💻 Технологии

### Frontend
- **Framework:** React 19.0.0
- **Routing:** React Router v7
- **UI Library:** Shadcn UI (Radix UI)
- **Styling:** Tailwind CSS
- **Build Tool:** Craco
- **HTTP Client:** Axios
- **Notifications:** Sonner (toast)

### Backend
- **Framework:** FastAPI (Python 3.11)
- **Database:** MongoDB
- **ORM:** Motor (async MongoDB)
- **Scheduler:** APScheduler (для cron jobs)
- **Validation:** Pydantic
- **CORS:** Starlette middleware

### Интеграции
- **PayPal:** API v2 (платежи + инвойсы)
- **Email:** SMTP (готов к настройке)

---

## 📁 Структура проекта

```
/app/
├── frontend/                   # React приложение
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   ├── ui/            # Shadcn UI компоненты
│   │   │   ├── Header.jsx
│   │   │   ├── Hero.jsx
│   │   │   ├── Programs.jsx
│   │   │   ├── Features.jsx
│   │   │   ├── Gallery.jsx
│   │   │   ├── Testimonials.jsx
│   │   │   ├── FAQ.jsx
│   │   │   ├── Pricing.jsx    # Тарифы + регистрация
│   │   │   ├── Donate.jsx     # PayPal Donate
│   │   │   ├── Contact.jsx
│   │   │   └── Footer.jsx
│   │   ├── mock.js            # Mock данные (статика)
│   │   ├── App.js
│   │   ├── App.css
│   │   └── index.css
│   ├── package.json
│   ├── tailwind.config.js
│   └── .env                   # Frontend env variables
│
├── backend/                    # FastAPI приложение
│   ├── server.py              # Main app + routes
│   ├── models.py              # Pydantic models
│   ├── paypal_service.py      # PayPal API integration
│   ├── email_service.py       # Email service
│   ├── payment_monitor.py     # Cron job для проверки платежей
│   ├── requirements.txt
│   └── .env                   # Backend env variables
│
├── contracts.md               # API contracts
├── EMAIL_SETUP_INSTRUCTIONS.md
└── DEPLOYMENT_GUIDE.md        # Этот файл
```

---

## 🖥️ Требования к серверу

### Минимальные требования:
- **OS:** Ubuntu 22.04 LTS
- **CPU:** 2 cores
- **RAM:** 4GB
- **Storage:** 20GB SSD
- **Network:** Static IP address

### Рекомендуемые:
- **OS:** Ubuntu 22.04 LTS
- **CPU:** 4 cores
- **RAM:** 8GB
- **Storage:** 40GB SSD
- **Network:** Static IP + Domain name

### Необходимые порты:
- **80** - HTTP (Nginx)
- **443** - HTTPS (Nginx + SSL)
- **3000** - Frontend (внутренний, не открывать)
- **8001** - Backend API (внутренний, не открывать)
- **27017** - MongoDB (внутренний, не открывать)

---

## 📦 Инструкция по установке

### Шаг 1: Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl wget git nginx certbot python3-certbot-nginx \
    python3.11 python3.11-venv python3-pip nodejs npm mongodb-org

# Установка Yarn
npm install -g yarn

# Установка PM2 (process manager)
npm install -g pm2
```

### Шаг 2: Установка MongoDB

```bash
# Импорт публичного ключа MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Добавление репозитория MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Установка MongoDB
sudo apt update
sudo apt install -y mongodb-org

# Запуск MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

### Шаг 3: Загрузка проекта

```bash
# Создание директории проекта
sudo mkdir -p /var/www/sunnysiouxcare
cd /var/www/sunnysiouxcare

# Скопируйте все файлы проекта сюда
# Используйте scp, rsync или git clone
```

### Шаг 4: Установка Frontend зависимостей

```bash
cd /var/www/sunnysiouxcare/frontend

# Установка зависимостей
yarn install

# Build для production
yarn build
```

### Шаг 5: Установка Backend зависимостей

```bash
cd /var/www/sunnysiouxcare/backend

# Создание виртуального окружения
python3.11 -m venv venv
source venv/bin/activate

# Установка зависимостей
pip install -r requirements.txt
```

---

## ⚙️ Конфигурация

### Frontend Environment Variables
Файл: `/var/www/sunnysiouxcare/frontend/.env`

```env
# Backend API URL
REACT_APP_BACKEND_URL=https://sunnysiouxcare.com
```

### Backend Environment Variables
Файл: `/var/www/sunnysiouxcare/backend/.env`

```env
# MongoDB Configuration
MONGO_URL="mongodb://localhost:27017"
DB_NAME="sunnysiouxcare_production"

# CORS Origins
CORS_ORIGINS="https://sunnysiouxcare.com,https://www.sunnysiouxcare.com"

# PayPal Configuration
PAYPAL_CLIENT_ID="AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg"
PAYPAL_CLIENT_SECRET="ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x"
PAYPAL_MODE="live"

# Email Configuration (ОПЦИОНАЛЬНО - настроить после покупки домена)
EMAIL_ENABLED="false"
SMTP_HOST="mail.sunnysiouxcare.com"
SMTP_PORT="587"
SMTP_USER="info@sunnysiouxcare.com"
SMTP_PASSWORD="your-email-password-here"
FROM_EMAIL="noreply@sunnysiouxcare.com"
ADMIN_EMAIL="info@sunnysiouxcare.com"
```

---

## 🔗 Интеграции

### PayPal Integration

**Что работает:**
1. **Pricing Plans (Тарифы)** - 3 кнопки с прямыми ссылками на оплату:
   - Infant Care ($1200/month): `/9JJPVWE34GT22`
   - Toddler & Preschool ($950/month): `/ULN9NX35HA8SY`
   - School-Age Care ($600/month): `/DHYRTHK8ZUN8C`

2. **Custom Invoice (Кастомный инвойс)** - создание произвольных инвойсов через PayPal API

3. **Donate Button (Пожертвования)** - кнопка donate с hosted button ID: `B6XLRY6MY435A`

4. **Automatic Fallback Invoice** - автоматическое создание инвойса если оплата не прошла (через 10 минут)

**PayPal Credentials:**
- Client ID: `AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg`
- Client Secret: `ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x`
- Mode: `live` (production)

### Email Integration (Опционально)

Для настройки email следуйте инструкциям в `/app/EMAIL_SETUP_INSTRUCTIONS.md`

---

## 🚀 Развертывание

### Настройка PM2 для Backend

Создайте файл `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'sunnysiouxcare-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port 8001',
    cwd: '/var/www/sunnysiouxcare/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
```

Запуск:
```bash
cd /var/www/sunnysiouxcare/backend
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Настройка Nginx

Создайте файл `/etc/nginx/sites-available/sunnysiouxcare`:

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name sunnysiouxcare.com www.sunnysiouxcare.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name sunnysiouxcare.com www.sunnysiouxcare.com;

    # SSL Configuration (will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/sunnysiouxcare.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sunnysiouxcare.com/privkey.pem;

    # Frontend - Serve static React build
    root /var/www/sunnysiouxcare/frontend/build;
    index index.html;

    # Backend API - Proxy to FastAPI
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # React Router - все остальные запросы идут на index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
}
```

Активация конфигурации:
```bash
sudo ln -s /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Получение SSL сертификата

```bash
# Остановите Nginx временно
sudo systemctl stop nginx

# Получите сертификат
sudo certbot certonly --standalone -d sunnysiouxcare.com -d www.sunnysiouxcare.com

# Запустите Nginx обратно
sudo systemctl start nginx

# Настройте автоматическое обновление
sudo certbot renew --dry-run
```

### DNS настройки

В вашем регистраторе домена (Namecheap, GoDaddy и т.д.) добавьте записи:

```
A     @                 YOUR_SERVER_IP
A     www               YOUR_SERVER_IP
CNAME mail              @  (если настраиваете email)
MX    @                 mail.sunnysiouxcare.com  (priority: 10)
TXT   @                 "v=spf1 mx ~all"
```

---

## 🔧 Обслуживание

### Просмотр логов

```bash
# Backend logs
pm2 logs sunnysiouxcare-backend

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# MongoDB logs
sudo tail -f /var/log/mongodb/mongod.log
```

### Мониторинг процессов

```bash
# PM2 status
pm2 status
pm2 monit

# System resources
htop
df -h
free -h
```

### Обновление приложения

```bash
# Frontend
cd /var/www/sunnysiouxcare/frontend
git pull  # или загрузить новые файлы
yarn install
yarn build
sudo systemctl reload nginx

# Backend
cd /var/www/sunnysiouxcare/backend
git pull  # или загрузить новые файлы
source venv/bin/activate
pip install -r requirements.txt
pm2 restart sunnysiouxcare-backend
```

### Резервное копирование

```bash
# MongoDB backup
mongodump --db sunnysiouxcare_production --out /backups/mongodb/$(date +%Y%m%d)

# Files backup
tar -czf /backups/files/sunnysiouxcare-$(date +%Y%m%d).tar.gz /var/www/sunnysiouxcare
```

### Cron задачи

Добавьте в crontab для автоматических бэкапов:

```bash
crontab -e

# Добавьте:
0 2 * * * mongodump --db sunnysiouxcare_production --out /backups/mongodb/$(date +\%Y\%m\%d)
0 3 * * 0 tar -czf /backups/files/sunnysiouxcare-$(date +\%Y\%m\%d).tar.gz /var/www/sunnysiouxcare
```

---

## 🐛 Troubleshooting

### Backend не запускается

```bash
# Проверьте логи
pm2 logs sunnysiouxcare-backend

# Проверьте порт
sudo netstat -tulpn | grep 8001

# Перезапустите
pm2 restart sunnysiouxcare-backend
```

### MongoDB connection errors

```bash
# Проверьте статус
sudo systemctl status mongod

# Перезапустите
sudo systemctl restart mongod

# Проверьте логи
sudo tail -f /var/log/mongodb/mongod.log
```

### SSL certificate issues

```bash
# Обновите сертификат
sudo certbot renew

# Проверьте сертификат
sudo certbot certificates
```

### PayPal API errors

1. Проверьте `.env` файл - правильные ли credentials
2. Проверьте PAYPAL_MODE (должен быть "live" для production)
3. Проверьте логи backend для деталей ошибки

---

## 📊 Мониторинг и аналитика

### Рекомендуемые инструменты:

1. **Uptime Monitoring:**
   - UptimeRobot (бесплатно)
   - Pingdom

2. **Error Tracking:**
   - Sentry (для JavaScript и Python)

3. **Performance:**
   - Google Analytics
   - Google PageSpeed Insights

4. **Server Monitoring:**
   - Netdata (бесплатно, self-hosted)
   - New Relic

---

## 📞 Поддержка

**Важные файлы для справки:**
- `/app/contracts.md` - API документация
- `/app/EMAIL_SETUP_INSTRUCTIONS.md` - Настройка email
- `/app/test_result.md` - Результаты тестирования

**База данных MongoDB:**
- `enrollment_registrations` - регистрации на программы
- `invoice_requests` - созданные инвойсы
- `contact_submissions` - контактные формы

**Cron Jobs:**
- Payment monitor запускается каждые 10 минут автоматически
- Проверяет регистрации старше 10 минут со статусом "pending"
- Автоматически создаёт и отправляет PayPal инвойсы

---

## ✅ Чеклист развертывания

- [ ] Сервер настроен (Ubuntu 22.04)
- [ ] Домен куплен (sunnysiouxcare.com)
- [ ] DNS записи настроены
- [ ] MongoDB установлен и запущен
- [ ] Node.js и Python установлены
- [ ] Проект загружен на сервер
- [ ] Frontend зависимости установлены
- [ ] Frontend собран (yarn build)
- [ ] Backend зависимости установлены
- [ ] .env файлы настроены
- [ ] PM2 настроен для backend
- [ ] Nginx настроен
- [ ] SSL сертификат получен
- [ ] Сайт доступен по HTTPS
- [ ] PayPal интеграция протестирована
- [ ] Email настроен (опционально)
- [ ] Backup настроен
- [ ] Мониторинг настроен

---

## 🎉 Готово!

Ваш сайт SunnySiouxCare.com готов к работе!

**Домен:** https://sunnysiouxcare.com
**Email:** info@sunnysiouxcare.com (после настройки)
**Адрес:** 2110 Summit St, Sioux City, IA 51104

Все системы работают автоматически:
✅ Прием оплат через PayPal
✅ Автоматические инвойсы при неудачной оплате
✅ Форма обратной связи
✅ Donate кнопка
✅ Email уведомления (после настройки)
