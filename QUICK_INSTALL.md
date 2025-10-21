# ⚡ Быстрая установка SunnySiouxCare.com за 5 минут

## 🎯 Одна команда для полной установки!

После того как вы:
1. ✅ Создали Droplet на DigitalOcean (Ubuntu 22.04)
2. ✅ Настроили DNS на вашем домене
3. ✅ Получили MongoDB URL (MongoDB Atlas - бесплатно)
4. ✅ Получили PayPal Credentials

---

## 🚀 Команда для установки

Подключитесь к вашему серверу и выполните:

```bash
# Скачать и запустить автоматический установщик
curl -fsSL https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install.sh | sudo bash
```

### Альтернативный способ (если нужно сначала просмотреть скрипт):

```bash
# Скачать скрипт
wget https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install.sh

# Просмотреть скрипт (опционально)
cat install.sh

# Дать права на выполнение
chmod +x install.sh

# Запустить
sudo ./install.sh
```

---

## 📝 Что потребуется во время установки

Скрипт спросит у вас:

1. **Домен** (например: `sunnysiouxcare.com`)
2. **Email для SSL** (например: `admin@sunnysiouxcare.com`)
3. **MongoDB URL** от MongoDB Atlas:
   ```
   mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/
   ```
4. **PayPal Client ID**
5. **PayPal Client Secret**

---

## ⏱️ Время установки

- ⚡ **2-3 минуты** - базовая установка (SWAP, пакеты, nginx)
- ⚡ **1-2 минуты** - установка backend и зависимостей
- ⚡ **1-2 минуты** - сборка frontend (может быть дольше на слабых серверах)
- ⚡ **30 секунд** - получение SSL сертификата

**Итого: ~5-8 минут** 🎉

---

## ✅ После установки

Скрипт автоматически:

✅ Создаст SWAP (2GB дополнительной памяти)
✅ Обновит систему
✅ Настроит Firewall (UFW)
✅ Установит Python 3.11, Node.js 18, PM2
✅ Клонирует проект с GitHub
✅ Настроит .env файлы
✅ Соберет и запустит Frontend
✅ Запустит Backend через PM2
✅ Настроит Nginx
✅ Получит SSL сертификат (HTTPS)

**Ваш сайт будет доступен по адресу:** `https://ваш-домен.com`

---

## 🔧 Полезные команды после установки

```bash
# Проверить статус backend
pm2 status

# Посмотреть логи
pm2 logs

# Перезапустить backend
pm2 restart sunnysiouxcare-backend

# Проверить Nginx
systemctl status nginx

# Просмотреть логи Nginx
tail -f /var/log/nginx/error.log

# Обновить SSL сертификат
certbot renew
```

---

## 📊 Проверка работы

Откройте в браузере:
- **Главная:** https://ваш-домен.com
- **API:** https://ваш-домен.com/api/
- **Backend здоровье:** https://ваш-домен.com/api/health

Проверьте функционал:
1. ✅ Главная страница загружается
2. ✅ Тарифные планы отображаются
3. ✅ Кнопка Donate работает
4. ✅ Форма Contact отправляется
5. ✅ SSL сертификат активен (🔒 в браузере)

---

## ⚠️ Требования к серверу

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

**Поддержка:**
- DigitalOcean: от $4/месяц (минимум) или $12/месяц (рекомендовано)
- Linode, Vultr, AWS EC2 - тоже подойдут

---

## 🆘 Если что-то пошло не так

### Frontend не собрался (недостаточно памяти):
```bash
# Увеличьте SWAP до 4GB
sudo swapoff /swapfile
sudo fallocate -l 4G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Попробуйте собрать вручную
cd /var/www/sunny-sioux-care/frontend
export NODE_OPTIONS="--max_old_space_size=800"
yarn build
```

### Backend не запускается:
```bash
# Проверьте логи
pm2 logs sunnysiouxcare-backend

# Проверьте .env файл
cat /var/www/sunny-sioux-care/backend/.env

# Перезапустите
pm2 restart sunnysiouxcare-backend
```

### SSL не получен (DNS ещё не обновился):
```bash
# Подождите 10-30 минут и попробуйте снова
sudo certbot --nginx -d ваш-домен.com -d www.ваш-домен.com
```

---

## 🔄 Обновление проекта

Когда нужно обновить код с GitHub:

```bash
cd /var/www/sunny-sioux-care

# Скачать изменения
git pull origin main

# Обновить backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
pm2 restart sunnysiouxcare-backend

# Обновить frontend
cd ../frontend
yarn install
yarn build
sudo systemctl reload nginx
```

---

## 💾 Резервное копирование

### Создать backup:
```bash
# Backup базы данных (если используете локальный MongoDB)
mongodump --out=/backup/mongodb-$(date +%Y%m%d)

# Backup .env файлов
sudo cp /var/www/sunny-sioux-care/backend/.env /backup/backend-env-$(date +%Y%m%d).env
```

### MongoDB Atlas (облачный):
- Автоматические backup уже настроены
- Восстановление через интерфейс Atlas

---

## 📞 Поддержка

**GitHub:** https://github.com/mrolivershea-cyber/sunny-sioux-care
**Документация:** См. файлы в репозитории

---

Готово! Один curl - и ваш сайт работает! 🚀🎉
