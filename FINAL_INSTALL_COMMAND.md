# 🚀 ФИНАЛЬНАЯ КОМАНДА ДЛЯ УСТАНОВКИ

## ✅ Основной файл install.sh заменён на полностью автоматический!

---

## 📋 ЧТО ДЕЛАТЬ:

### 1️⃣ Сохраните проект в GitHub:
Используйте кнопку **"Save to Github"** в интерфейсе чата

### 2️⃣ Подключитесь к серверу:
```bash
ssh root@ваш_ip_сервера
```

### 3️⃣ Запустите команду установки:

```bash
wget -O install.sh https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install.sh && chmod +x install.sh && sudo ./install.sh
```

---

## ⚡ ЧТО ПРОИЗОЙДЁТ:

**НИКАКИХ ВОПРОСОВ!** Всё автоматически:

1. Покажет предустановленные настройки
2. Отсчитает 3 секунды
3. Начнёт автоматическую установку (5-10 минут)
4. Установит MongoDB локально на сервер
5. Настроит все сервисы
6. Получит SSL сертификат
7. Запустит сайт!

---

## 🎯 Предустановленные данные:

✅ **Домен:** sunnysiouxcare.com
✅ **Email:** info@sunnysiouxcare.com  
✅ **MongoDB:** Локальная установка (mongodb://localhost:27017)
✅ **База данных:** sunnysiouxcare
✅ **PayPal Client ID:** AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg
✅ **PayPal Secret:** ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x
✅ **PayPal Mode:** live

---

## 📦 Что устанавливается:

- [1/11] SWAP 2GB
- [2/11] Обновление системы
- [3/11] Базовые пакеты
- [4/11] Firewall (UFW)
- [5/11] **MongoDB 7.0**
- [6/11] Python 3.11
- [7/11] Node.js 18 + Yarn + PM2
- [8/11] Клонирование проекта
- [9/11] Backend настройка
- [10/11] Frontend сборка
- [11/11] Nginx + SSL

---

## ✅ После установки:

Сайт будет доступен: **https://sunnysiouxcare.com** 🎉

---

## 🆘 Если на сервере остались старые файлы:

```bash
# Удалить старую установку
sudo rm -rf /var/www/sunny-sioux-care
sudo rm -f /etc/nginx/sites-enabled/sunnysiouxcare
sudo rm -f /etc/nginx/sites-available/sunnysiouxcare

# Остановить старые процессы
pm2 delete all

# Затем запустите установку заново
wget -O install.sh https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install.sh && chmod +x install.sh && sudo ./install.sh
```

---

## 🎯 ИТОГО:

**1 команда = Работающий сайт за 10 минут без вопросов!**
