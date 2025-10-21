# 🚀 УНИВЕРСАЛЬНЫЕ СКРИПТЫ УСТАНОВКИ/ОБНОВЛЕНИЯ

## 📥 Два простых скрипта для работы с GitHub

### 1️⃣ `install-from-github.sh` - Новая установка
### 2️⃣ `update-from-github.sh` - Обновление существующего проекта

---

## 🆕 НОВАЯ УСТАНОВКА (на чистый сервер)

### Одна команда для установки:

```bash
curl -fsSL https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install-from-github.sh | sudo bash
```

### Что делает скрипт:
1. ✅ Проверяет систему (Ubuntu/Debian)
2. ✅ Устанавливает все зависимости (Node.js 20, Python 3.11, MongoDB, Nginx)
3. ✅ Клонирует проект с GitHub
4. ✅ Настраивает Backend (создает venv, устанавливает pip пакеты)
5. ✅ Настраивает Frontend (yarn install, yarn build)
6. ✅ Настраивает Supervisor для автозапуска
7. ✅ Настраивает Nginx с вашим доменом
8. ✅ Устанавливает SSL сертификат Let's Encrypt (опционально)
9. ✅ Настраивает firewall (UFW)
10. ✅ Предлагает установить почтовый сервер (Postfix + Dovecot)

### Время установки: ~10-15 минут

---

## 🔄 ОБНОВЛЕНИЕ (существующего проекта)

### Простое обновление одной командой:

```bash
cd /var/www/sunny-sioux-care
sudo bash update-from-github.sh
```

### Или скачайте и запустите:

```bash
curl -fsSL https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/update-from-github.sh -o /tmp/update.sh
sudo bash /tmp/update.sh
```

### Что делает скрипт обновления:
1. ✅ Создает автоматический бэкап проекта
2. ✅ Сохраняет .env файлы (пароли не теряются!)
3. ✅ Получает последние изменения из GitHub
4. ✅ Показывает список изменений перед обновлением
5. ✅ Обновляет зависимости (только если изменились)
6. ✅ Пересобирает frontend (только если изменился)
7. ✅ Перезапускает только измененные сервисы
8. ✅ Проверяет работоспособность
9. ✅ Позволяет откатиться назад при ошибке

### Время обновления: ~2-5 минут

---

## 📋 ДЕТАЛЬНЫЕ ИНСТРУКЦИИ

### Вариант 1: Установка на новый сервер

```bash
# 1. Подключитесь к серверу
ssh root@ваш-ip-адрес

# 2. Запустите скрипт установки
curl -fsSL https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install-from-github.sh | sudo bash

# 3. Следуйте инструкциям на экране:
#    - Введите домен
#    - Выберите нужно ли SSL
#    - Выберите нужен ли почтовый сервер

# 4. Заполните .env файлы
nano /var/www/sunny-sioux-care/backend/.env
# Добавьте PayPal ключи и email настройки

# 5. Перезапустите backend
sudo supervisorctl restart backend

# 6. Готово! Ваш сайт работает 🎉
```

---

### Вариант 2: Обновление существующего проекта

```bash
# 1. Подключитесь к серверу
ssh root@104.248.57.162

# 2. Перейдите в папку проекта
cd /var/www/sunny-sioux-care

# 3. Запустите скрипт обновления
sudo bash update-from-github.sh

# Скрипт спросит вас:
#   - Показать изменения? (да/нет)
#   - Продолжить обновление? (да/нет)

# 4. Всё обновится автоматически!
```

---

## 🔐 БЕЗОПАСНОСТЬ

### Скрипты ВСЕГДА сохраняют ваши данные:

✅ **Файлы .env НЕ перезаписываются** - ваши пароли в безопасности  
✅ **Автоматический бэкап** создается перед каждым обновлением  
✅ **Откат назад** возможен одной командой  

### Бэкапы хранятся в:
```
/var/www/backups/sunny-sioux-care-backup-YYYYMMDD-HHMMSS.tar.gz
```

### Откат к предыдущей версии:
```bash
cd /var/www/sunny-sioux-care
git reset --hard HEAD@{1}
sudo supervisorctl restart all
```

---

## 📊 ЧТО ОБНОВЛЯЕТСЯ АВТОМАТИЧЕСКИ

| Компонент | Новая установка | Обновление |
|-----------|----------------|------------|
| Backend код | ✅ | ✅ (только если изменился) |
| Frontend код | ✅ | ✅ (только если изменился) |
| Python зависимости | ✅ | ✅ (только если изменились) |
| Node зависимости | ✅ | ✅ (только если изменились) |
| Frontend build | ✅ | ✅ (только если нужно) |
| .env файлы | ⚠️ Создаются из примера | ❌ НЕ трогаются |
| Nginx конфиг | ✅ | ❌ (настраивается вручную) |
| SSL сертификат | ✅ (опционально) | ❌ (уже настроен) |
| Почтовый сервер | ✅ (опционально) | ❌ (уже настроен) |

---

## 🛠️ РУЧНАЯ УСТАНОВКА (если автоскрипт не подходит)

### 1. Клонировать репозиторий:
```bash
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git /var/www/sunny-sioux-care
cd /var/www/sunny-sioux-care
```

### 2. Установить Backend:
```bash
cd backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
nano .env  # Заполните данные
```

### 3. Установить Frontend:
```bash
cd ../frontend
yarn install
cp .env.example .env
nano .env  # Установите REACT_APP_BACKEND_URL
yarn build
```

### 4. Настроить Supervisor:
```bash
# Скопируйте конфигурацию из install-from-github.sh
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start backend
```

### 5. Настроить Nginx:
```bash
# Скопируйте конфигурацию из install-from-github.sh
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🔧 ПОЛЕЗНЫЕ КОМАНДЫ

### Проверить статус:
```bash
sudo supervisorctl status
sudo systemctl status nginx
sudo service postfix status
sudo service dovecot status
```

### Посмотреть логи:
```bash
sudo tail -f /var/log/supervisor/backend.out.log
sudo tail -f /var/log/supervisor/backend.err.log
```

### Перезапустить сервисы:
```bash
sudo supervisorctl restart backend
sudo supervisorctl restart all
sudo systemctl restart nginx
```

### Обновить только код (без сборки):
```bash
cd /var/www/sunny-sioux-care
git pull origin main
```

---

## 📞 ПОДДЕРЖКА

### Если что-то пошло не так:

1. **Проверьте логи:**
```bash
sudo supervisorctl status
sudo tail -100 /var/log/supervisor/backend.err.log
```

2. **Откатитесь к бэкапу:**
```bash
cd /var/www
tar -xzf backups/sunny-sioux-care-backup-XXXXXXXX.tar.gz
sudo supervisorctl restart all
```

3. **Переустановите с нуля:**
```bash
sudo rm -rf /var/www/sunny-sioux-care
curl -fsSL https://raw.githubusercontent.com/mroliversha-cyber/sunny-sioux-care/main/install-from-github.sh | sudo bash
```

---

## ✅ ЧЕКЛИСТ ПОСЛЕ УСТАНОВКИ

- [ ] Backend/.env заполнен (PayPal ключи, MongoDB, Email)
- [ ] Frontend/.env заполнен (REACT_APP_BACKEND_URL)
- [ ] Backend запущен: `sudo supervisorctl status backend`
- [ ] Nginx работает: `sudo systemctl status nginx`
- [ ] Сайт открывается в браузере
- [ ] SSL сертификат установлен (HTTPS работает)
- [ ] DNS настроены на ваш IP
- [ ] Email сервер настроен (опционально)
- [ ] Почтовые DNS записи добавлены (MX, SPF, DKIM, DMARC)

---

## 🎉 ГОТОВО!

**Новая установка:**
```bash
curl -fsSL https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install-from-github.sh | sudo bash
```

**Обновление:**
```bash
cd /var/www/sunny-sioux-care && sudo bash update-from-github.sh
```

**Вот и всё! Просто и быстро! 🚀**

---

**Дата:** 21 октября 2025  
**Версия:** 2.0  
**GitHub:** https://github.com/mrolivershea-cyber/sunny-sioux-care
