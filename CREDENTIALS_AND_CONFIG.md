# 🔐 SunnySiouxCare.com - Учётные данные и конфигурация

## 🌐 Основная информация

**Название сайта:** Sunny Sioux Care
**Домен:** sunnysiouxcare.com
**Адрес:** 2110 Summit St, Sioux City, IA 51104
**Email:** info@sunnysiouxcare.com

---

## 💳 PayPal Credentials

### Production (Live)
```
Client ID: AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg
Client Secret: ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x
Mode: live
```

### Payment Links (Direct)
```
Infant Care ($1200/month):
https://www.paypal.com/ncp/payment/9JJPVWE34GT22

Toddler & Preschool ($950/month):
https://www.paypal.com/ncp/payment/ULN9NX35HA8SY

School-Age Care ($600/month):
https://www.paypal.com/ncp/payment/DHYRTHK8ZUN8C
```

### Donate Button
```
Hosted Button ID: B6XLRY6MY435A
URL: https://www.paypal.com/ncp/payment/HM37DQCLPVWKG
```

---

## 📧 Email Configuration (Для настройки)

После покупки домена и настройки почтового сервера:

```env
EMAIL_ENABLED="true"
SMTP_HOST="mail.sunnysiouxcare.com"
SMTP_PORT="587"
SMTP_USER="info@sunnysiouxcare.com"
SMTP_PASSWORD="[ВАШ_ПАРОЛЬ]"
FROM_EMAIL="noreply@sunnysiouxcare.com"
ADMIN_EMAIL="info@sunnysiouxcare.com"
```

**Для The Bat:**
- Входящая почта (IMAP): mail.sunnysiouxcare.com:993 (SSL)
- Исходящая почта (SMTP): mail.sunnysiouxcare.com:587 (STARTTLS)

---

## 🗄️ MongoDB

```
Connection String: mongodb://localhost:27017
Database Name: sunnysiouxcare_production

Collections:
- enrollment_registrations  (регистрации на программы)
- invoice_requests          (PayPal инвойсы)
- contact_submissions       (контактные формы)
```

---

## 🎨 Тарифные планы

### Infant Care
- Возраст: 6 weeks - 12 months
- Цена: $1,200/month
- PayPal Link: /9JJPVWE34GT22

### Toddler & Preschool ⭐ MOST POPULAR
- Возраст: 1 - 5 years
- Цена: $950/month
- PayPal Link: /ULN9NX35HA8SY

### School-Age Care
- Возраст: 5 - 12 years
- Цена: $600/month
- PayPal Link: /DHYRTHK8ZUN8C

---

## 🔄 Автоматические процессы

### Payment Monitor (Cron Job)
- **Частота:** Каждые 10 минут
- **Функция:** Проверяет неоплаченные регистрации
- **Действие:** Автоматически создаёт PayPal инвойс если оплата не прошла
- **Логика:** 
  1. Ищет регистрации старше 10 минут со статусом "pending"
  2. Создаёт PayPal инвойс с полными данными клиента
  3. Отправляет инвойс на email клиента
  4. Обновляет статус на "invoice_sent"

---

## 🌍 DNS Записи

После покупки домена настройте:

```
A     @                 [IP_ВАШЕГО_СЕРВЕРА]
A     www               [IP_ВАШЕГО_СЕРВЕРА]
CNAME mail              @
MX    @                 mail.sunnysiouxcare.com  (priority: 10)
TXT   @                 "v=spf1 mx ~all"
```

---

## 📂 Структура файлов на сервере

```
/var/www/sunnysiouxcare/
├── frontend/
│   ├── build/              # Production build
│   ├── src/
│   ├── package.json
│   └── .env               # REACT_APP_BACKEND_URL
│
├── backend/
│   ├── venv/              # Python virtual environment
│   ├── server.py
│   ├── models.py
│   ├── paypal_service.py
│   ├── email_service.py
│   ├── payment_monitor.py
│   ├── requirements.txt
│   └── .env              # MongoDB, PayPal, Email config
│
└── logs/                 # Application logs
```

---

## 🚀 Команды для управления

### Backend (PM2)
```bash
pm2 start ecosystem.config.js    # Запуск
pm2 stop sunnysiouxcare-backend  # Остановка
pm2 restart sunnysiouxcare-backend # Перезапуск
pm2 logs sunnysiouxcare-backend  # Логи
pm2 monit                        # Мониторинг
```

### Nginx
```bash
sudo systemctl restart nginx     # Перезапуск
sudo systemctl reload nginx      # Перезагрузка конфигурации
sudo nginx -t                    # Проверка конфигурации
sudo tail -f /var/log/nginx/error.log # Логи ошибок
```

### MongoDB
```bash
sudo systemctl restart mongod    # Перезапуск
sudo systemctl status mongod     # Статус
mongosh                          # MongoDB shell
```

### SSL Certificate
```bash
sudo certbot renew               # Обновление сертификата
sudo certbot certificates        # Просмотр сертификатов
```

---

## 📊 API Endpoints

### Public Endpoints
```
GET  /api/                      # Health check
POST /api/contact               # Contact form
POST /api/register-enrollment   # Plan registration
POST /api/create-invoice        # Custom invoice
```

### Backend URL
- Development: http://localhost:8001
- Production: https://sunnysiouxcare.com/api

---

## 🔍 Мониторинг и логи

### Проверка работы cron job
```bash
# Просмотр логов payment monitor
pm2 logs sunnysiouxcare-backend | grep "payment_monitor"

# Должны видеть каждые 10 минут:
# "Starting payment monitoring check..."
# "Found X pending registrations"
# "Payment monitoring check completed"
```

### Проверка PayPal интеграции
1. Откройте https://sunnysiouxcare.com
2. Выберите тариф "Select Plan"
3. Заполните форму регистрации
4. Проверьте MongoDB - должна появиться запись в `enrollment_registrations`
5. Через 10 минут проверьте логи - должен создаться инвойс

### Проверка Donate кнопки
1. Откройте https://sunnysiouxcare.com
2. Прокрутите до секции "Support Our Mission"
3. Должна отображаться PayPal Donate кнопка

---

## 🆘 Быстрое решение проблем

### Сайт не открывается
```bash
# Проверьте Nginx
sudo systemctl status nginx
sudo nginx -t

# Проверьте SSL
sudo certbot certificates
```

### Backend не работает
```bash
# Проверьте PM2
pm2 status
pm2 logs sunnysiouxcare-backend

# Перезапустите
pm2 restart sunnysiouxcare-backend
```

### PayPal не работает
1. Проверьте `.env` файл - правильные credentials
2. Проверьте PAYPAL_MODE="live"
3. Проверьте логи backend

### Email не отправляются
1. Проверьте EMAIL_ENABLED="true" в .env
2. Проверьте SMTP credentials
3. Проверьте логи backend

---

## 📱 Контакты для поддержки

**Для технических вопросов:**
- Проверьте `/app/DEPLOYMENT_GUIDE.md`
- Проверьте `/app/EMAIL_SETUP_INSTRUCTIONS.md`
- Проверьте логи: `pm2 logs sunnysiouxcare-backend`

**PayPal Dashboard:**
- https://www.paypal.com/
- https://developer.paypal.com/dashboard/

---

## ✅ Быстрый чеклист запуска

- [ ] Домен куплен и настроен DNS
- [ ] Сервер настроен (Ubuntu 22.04)
- [ ] MongoDB работает
- [ ] Backend запущен через PM2
- [ ] Frontend собран и размещён
- [ ] Nginx настроен с SSL
- [ ] Сайт открывается по HTTPS
- [ ] PayPal кнопки работают
- [ ] Donate кнопка отображается
- [ ] Cron job проверяет платежи каждые 10 минут
- [ ] Email настроен (опционально)

---

## 🎉 Всё готово!

Сайт полностью настроен и готов к работе!

**Убедитесь:**
✅ Все PayPal credentials правильные
✅ DNS записи настроены
✅ SSL сертификат активен
✅ Backend cron job работает
✅ Email настроен (если нужно)
