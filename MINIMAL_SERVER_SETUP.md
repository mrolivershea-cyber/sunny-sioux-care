# 💰 Установка на минимальный сервер DigitalOcean ($4/month)

## ⚠️ Важно понять

**Ваша конфигурация:**
- 512 MB RAM
- 1 CPU
- 10 GB SSD
- $4/month

**Это МИНИМУМ**, но работать будет! Нужна оптимизация:
1. ✅ Frontend собираем ЛОКАЛЬНО (не на сервере)
2. ✅ MongoDB - используем БЕСПЛАТНЫЙ внешний (MongoDB Atlas)
3. ✅ Добавим SWAP для памяти
4. ✅ Упростим конфигурацию

---

## 🚀 Шаг 1: Создание Droplet

**На DigitalOcean выберите:**
- Image: **Ubuntu 22.04 LTS**
- Plan: **Basic**
- CPU: **Regular - $4/month**
  - 512 MB / 1 CPU
  - 10 GB SSD
  - 500 GB Transfer
- Datacenter: **New York 1**
- Authentication: SSH Key или Password
- Hostname: `sunnysiouxcare`

**Нажмите "Create Droplet"**

Получите IP адрес (например: `123.45.67.89`)

---

## 🌐 Шаг 2: Настройка DNS на Namecheap

**Domain List → Manage → Advanced DNS:**

Добавьте записи:
```
Type: A Record | Host: @ | Value: ВАШ_IP | TTL: Automatic
Type: A Record | Host: www | Value: ВАШ_IP | TTL: Automatic
```

Подождите 10-30 минут для распространения DNS.

---

## 🔧 Шаг 3: Первая настройка сервера

### Подключитесь:
```bash
ssh root@ВАШ_IP
```

### Создайте SWAP (дополнительная память):
```bash
# Создать 2GB swap файл
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Сделать постоянным
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Проверить
free -h
# Должны видеть: Swap: 2.0Gi
```

### Обновить систему:
```bash
apt update && apt upgrade -y
apt install -y curl wget git nano ufw nginx
```

### Настроить Firewall:
```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

---

## 💾 Шаг 4: MongoDB Atlas (БЕСПЛАТНО вместо локального)

Вместо установки MongoDB на сервере (съедает 200-500MB RAM), используем облачный:

### Регистрация:
1. Зайдите: https://www.mongodb.com/cloud/atlas/register
2. Создайте аккаунт (БЕСПЛАТНО)

### Создайте кластер:
1. **Choose a path:** M0 FREE
2. **Cloud Provider:** AWS
3. **Region:** us-east-1 (ближе к вашему серверу)
4. **Cluster Name:** SunnySiouxCare
5. Нажмите **Create Deployment**

### Настройте доступ:
1. **Database Access** → Add New Database User
   - Username: `sunnysiouxcare`
   - Password: сгенерируйте сложный (скопируйте!)
   - Role: **Atlas admin**

2. **Network Access** → Add IP Address
   - Введите IP вашего DigitalOcean сервера
   - Или **0.0.0.0/0** (доступ отовсюду - менее безопасно)

3. **Connect** → Drivers → **Python**
   - Скопируйте connection string:
   ```
   mongodb+srv://sunnysiouxcare:PASSWORD@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

---

## 📦 Шаг 5: Подготовка Frontend (НА ВАШЕМ КОМПЬЮТЕРЕ)

**НЕ собирайте на сервере!** Слишком мало памяти.

### На вашем компьютере:
```bash
cd /app/frontend

# Установить зависимости (если ещё не установлены)
yarn install

# Собрать production build
yarn build

# Архивировать build
tar -czf frontend-build.tar.gz build/
```

### Загрузите на сервер:
```bash
scp frontend-build.tar.gz root@ВАШ_IP:/tmp/
```

---

## 🖥️ Шаг 6: Установка на сервере

### Подключитесь к серверу:
```bash
ssh root@ВАШ_IP
```

### Установите Python и Node.js:
```bash
# Python 3.11
apt install -y python3.11 python3.11-venv python3-pip

# Node.js (только для PM2, не для build)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# PM2
npm install -g pm2
```

### Создайте директории:
```bash
mkdir -p /var/www/sunnysiouxcare/frontend
mkdir -p /var/www/sunnysiouxcare/backend
```

### Распакуйте Frontend:
```bash
cd /var/www/sunnysiouxcare/frontend
tar -xzf /tmp/frontend-build.tar.gz
```

### Установите Backend:
```bash
cd /var/www/sunnysiouxcare

# Клонировать репозиторий
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git temp_repo

# Скопировать только backend
cp -r temp_repo/backend/* backend/
rm -rf temp_repo

cd backend

# Создать virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Установить зависимости
pip install -r requirements.txt
```

---

## ⚙️ Шаг 7: Настройка .env файлов

### Backend .env:
```bash
nano /var/www/sunnysiouxcare/backend/.env
```

Содержимое:
```env
# MongoDB Atlas (из шага 4)
MONGO_URL="mongodb+srv://sunnysiouxcare:ВАШ_ПАРОЛЬ@cluster0.xxxxx.mongodb.net/sunnysiouxcare?retryWrites=true&w=majority"
DB_NAME="sunnysiouxcare"

# CORS
CORS_ORIGINS="https://sunnysiouxcare.com,https://www.sunnysiouxcare.com"

# PayPal
PAYPAL_CLIENT_ID="AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg"
PAYPAL_CLIENT_SECRET="ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x"
PAYPAL_MODE="live"

# Email (пока отключен)
EMAIL_ENABLED="false"
```

Сохраните: `Ctrl+X`, `Y`, `Enter`

---

## 🚀 Шаг 8: Запуск Backend с PM2

### Создайте ecosystem.config.js:
```bash
nano /var/www/sunnysiouxcare/backend/ecosystem.config.js
```

Содержимое:
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
    max_memory_restart: '200M',  // Лимит памяти
    env: {
      NODE_ENV: 'production'
    }
  }]
};
```

### Запустите:
```bash
cd /var/www/sunnysiouxcare/backend
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Проверьте:
```bash
pm2 status
pm2 logs
curl http://localhost:8001/api/
# Должны увидеть: {"message":"Hello World"}
```

---

## 🌐 Шаг 9: Настройка Nginx

### Создайте конфигурацию:
```bash
nano /etc/nginx/sites-available/sunnysiouxcare
```

Содержимое:
```nginx
server {
    listen 80;
    server_name sunnysiouxcare.com www.sunnysiouxcare.com;

    # Frontend
    root /var/www/sunnysiouxcare/frontend/build;
    index index.html;

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # React Router
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
}
```

### Активируйте:
```bash
ln -s /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default  # Удалить default
nginx -t  # Проверить конфигурацию
systemctl reload nginx
```

---

## 🔒 Шаг 10: SSL сертификат (HTTPS)

```bash
# Установить certbot
apt install -y certbot python3-certbot-nginx

# Получить сертификат
certbot --nginx -d sunnysiouxcare.com -d www.sunnysiouxcare.com

# Ввести email и согласиться с условиями
# Certbot автоматически настроит HTTPS!

# Проверить автообновление
certbot renew --dry-run
```

---

## ✅ Проверка

Откройте в браузере:
- https://sunnysiouxcare.com
- Должен загрузиться сайт!

Проверьте:
1. ✅ Главная страница открывается
2. ✅ Кнопки тарифов работают
3. ✅ Donate кнопка отображается
4. ✅ Форма контакта работает

---

## 📊 Мониторинг памяти

```bash
# Проверить использование памяти
free -h
htop

# Логи PM2
pm2 logs

# Если backend падает из-за памяти - перезапуск
pm2 restart sunnysiouxcare-backend
```

---

## 💡 Оптимизации для 512MB

### Если сервер тормозит:

1. **Ограничить память для backend:**
```bash
pm2 stop sunnysiouxcare-backend
pm2 delete sunnysiouxcare-backend
# Отредактировать ecosystem.config.js - поставить max_memory_restart: '150M'
pm2 start ecosystem.config.js
```

2. **Очистить кэш:**
```bash
apt clean
apt autoremove -y
```

3. **Увеличить SWAP:**
```bash
swapoff /swapfile
fallocate -l 4G /swapfile
mkswap /swapfile
swapon /swapfile
```

---

## 🆘 Если не хватает места (10GB)

### Удалить ненужное:
```bash
# Удалить логи
pm2 flush

# Очистить apt кэш
apt clean

# Проверить место
df -h
```

---

## 💰 Стоимость итого

**DigitalOcean:** $4/месяц = $48/год
**MongoDB Atlas:** БЕСПЛАТНО (до 512MB)
**Namecheap домен:** $10-15/год
**SSL:** БЕСПЛАТНО (Let's Encrypt)

**ИТОГО:** ~$60/год! 🎉

---

## ⚠️ Важные ограничения

**С 512MB RAM:**
- ✅ Сайт работает отлично
- ✅ Backend справляется
- ✅ 5-50 одновременных пользователей - норма
- ⚠️ Не устанавливайте лишние пакеты
- ⚠️ Backend может упасть при большой нагрузке
- 💡 При росте трафика - upgrade на $12/month (2GB RAM)

---

## 📈 Когда upgrade на $12/month?

Если видите:
- Backend часто перезагружается
- Сайт медленно открывается
- PM2 показывает "Out of memory"
- Больше 50 одновременных пользователей

Тогда: DigitalOcean → Droplet → Resize → $12/month

---

Готово! Следуйте шагам по порядку! 🚀
