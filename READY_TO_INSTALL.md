# ⚡ ГОТОВАЯ УСТАНОВКА - Одна команда!

## 🎯 Универсальная команда для установки:

```bash
wget -O install.sh https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install-auto.sh && chmod +x install.sh && sudo ./install.sh
```

---

## 📝 Что нужно ТОЛЬКО MongoDB URL!

### Все остальное УЖЕ настроено:
- ✅ Домен: `sunnysiouxcare.com`
- ✅ Email: `info@sunnysiouxcare.com`
- ✅ PayPal Client ID: Настроен
- ✅ PayPal Secret: Настроен

### Нужен ТОЛЬКО MongoDB URL:

**Получите бесплатно на MongoDB Atlas:**
1. Зайдите: https://www.mongodb.com/cloud/atlas/register
2. Создайте кластер (M0 FREE)
3. Создайте пользователя базы данных
4. Добавьте IP адрес: 0.0.0.0/0 (или IP вашего сервера)
5. Скопируйте connection string:
   ```
   mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/
   ```

---

## 🚀 Процесс установки:

### 1. Запустите команду на сервере:
```bash
wget -O install.sh https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install-auto.sh && chmod +x install.sh && sudo ./install.sh
```

### 2. Введите только MongoDB URL:
```
Enter MongoDB URL: mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/
```

### 3. Подтвердите:
```
Continue? (yes/no): yes
```

### 4. Подождите 5-8 минут ⏱️

Скрипт автоматически:
- ✅ Создаст SWAP (2GB)
- ✅ Обновит систему
- ✅ Установит Python 3.11, Node.js 18, PM2, Nginx
- ✅ Клонирует проект с GitHub
- ✅ Настроит Backend с вашим MongoDB
- ✅ Соберет Frontend
- ✅ Настроит Nginx
- ✅ Получит SSL сертификат (HTTPS)
- ✅ Запустит все сервисы

---

## ✅ После установки

Ваш сайт будет доступен по адресу:
```
https://sunnysiouxcare.com
```

### Проверьте:
1. Главная страница открывается
2. Тарифные планы с кнопками PayPal работают
3. Donate кнопка отображается
4. Форма Contact отправляется
5. SSL (зеленый замок 🔒 в браузере)

---

## 🔧 Полезные команды:

```bash
# Статус backend
pm2 status

# Логи backend
pm2 logs

# Перезапуск backend
pm2 restart sunnysiouxcare-backend

# Статус Nginx
systemctl status nginx

# Обновить SSL
certbot renew
```

---

## 💡 Что уже настроено:

- ✅ **Домен:** sunnysiouxcare.com
- ✅ **PayPal Live Mode** с реальными credentials
- ✅ **3 тарифных плана:**
  - Infant Care: $1,200/month
  - Toddler & Preschool: $950/month
  - School-Age Care: $600/month
- ✅ **Автоматические инвойсы** (cron job каждые 10 минут)
- ✅ **Email сервис** (требует настройки SMTP на сервере)

---

## ⚠️ Требования к серверу:

**Минимум:**
- 512 MB RAM (с SWAP)
- 1 CPU
- 10 GB Disk
- Ubuntu 22.04 LTS

**Рекомендовано:**
- 1-2 GB RAM
- 1-2 CPU  
- 25+ GB Disk
- Ubuntu 22.04 LTS

---

## 🆘 Если что-то не работает:

### Frontend не собрался:
```bash
# Увеличьте SWAP
sudo swapoff /swapfile
sudo fallocate -l 4G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Соберите вручную
cd /var/www/sunny-sioux-care/frontend
export NODE_OPTIONS="--max_old_space_size=800"
yarn build
```

### Backend не запускается:
```bash
pm2 logs sunnysiouxcare-backend
```

### SSL не получен:
```bash
# Подождите 30 минут для DNS, затем:
sudo certbot --nginx -d sunnysiouxcare.com -d www.sunnysiouxcare.com
```

---

## 🎉 Готово!

**Одна команда + MongoDB URL = Работающий сайт за 5-8 минут!**
