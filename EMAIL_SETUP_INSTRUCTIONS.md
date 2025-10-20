# 📧 Инструкция по настройке Email для SunnySiouxCare.com

## Что уже готово ✅
- ✅ Email сервис интегрирован в код сайта
- ✅ Автоматические уведомления при заполнении контактной формы
- ✅ Автоматическая отправка инвойсов клиентам
- ✅ Красивые HTML шаблоны писем
- ✅ Настройки в .env файле

**Сейчас email отключен** (`EMAIL_ENABLED=false`). После покупки сервера нужно просто активировать.

---

## 🛒 Шаг 1: Покупка домена и сервера

### Купить домен
- **Домен**: sunnysiouxcare.com
- **Где купить**: Namecheap.com, GoDaddy.com
- **Цена**: ~$10-15/год

### Купить VPS сервер
**Рекомендации:**
- **ОС**: Ubuntu 22.04 LTS (самая простая)
- **Минимум**: 2GB RAM, 1 CPU Core, 20GB SSD
- **Провайдеры**:
  - DigitalOcean: ~$12/мес
  - Vultr: ~$10/мес
  - Linode: ~$10/мес

---

## 📮 Шаг 2: Настройка почтового сервера (Easy Way)

### Вариант 1: Mail-in-a-Box (Рекомендую! ⭐)
**Всё в один клик: email + DNS + веб-админка**

1. Подключитесь к серверу по SSH:
```bash
ssh root@your-server-ip
```

2. Установите Mail-in-a-Box:
```bash
curl -s https://mailinabox.email/setup.sh | sudo bash
```

3. Следуйте инструкциям на экране:
   - Email администратора: `info@sunnysiouxcare.com`
   - Придумайте пароль
   - Hostname: `box.sunnysiouxcare.com`

4. После установки откройте админ панель:
```
https://box.sunnysiouxcare.com/admin
```

5. Создайте email аккаунт:
   - Логин: `info@sunnysiouxcare.com`
   - Пароль: (придумайте сложный)

---

### Вариант 2: iRedMail (Альтернатива)
```bash
wget https://github.com/iredmail/iRedMail/archive/1.6.8.tar.gz
tar xvf 1.6.8.tar.gz
cd iRedMail-1.6.8
bash iRedMail.sh
```

---

## 🌐 Шаг 3: Настройка DNS записей

В панели управления доменом (Namecheap/GoDaddy) добавьте:

### MX запись (почтовый сервер)
```
Type: MX
Name: @
Value: mail.sunnysiouxcare.com
Priority: 10
```

### A запись для почтового сервера
```
Type: A
Name: mail
Value: YOUR_SERVER_IP
```

### SPF запись (защита от спама)
```
Type: TXT
Name: @
Value: v=spf1 mx ~all
```

### DKIM и DMARC
Mail-in-a-Box автоматически создаст эти записи. Скопируйте их из админ панели.

---

## ⚙️ Шаг 4: Активация email на сайте

1. Откройте файл `/app/backend/.env`

2. Измените настройки:
```bash
# Включить email
EMAIL_ENABLED="true"

# SMTP настройки
SMTP_HOST="mail.sunnysiouxcare.com"
SMTP_PORT="587"
SMTP_USER="info@sunnysiouxcare.com"
SMTP_PASSWORD="ваш-пароль-от-email"
FROM_EMAIL="noreply@sunnysiouxcare.com"
ADMIN_EMAIL="info@sunnysiouxcare.com"
```

3. Перезапустите backend:
```bash
sudo supervisorctl restart backend
```

4. Проверьте логи:
```bash
tail -f /var/log/supervisor/backend.err.log
```

---

## 📱 Шаг 5: Настройка The Bat

После настройки сервера, используйте эти данные в The Bat:

### Входящая почта (IMAP)
- **Сервер**: mail.sunnysiouxcare.com
- **Порт**: 993
- **SSL**: Да
- **Логин**: info@sunnysiouxcare.com
- **Пароль**: ваш-пароль

### Исходящая почта (SMTP)
- **Сервер**: mail.sunnysiouxcare.com
- **Порт**: 587
- **STARTTLS**: Да
- **Логин**: info@sunnysiouxcare.com
- **Пароль**: ваш-пароль

---

## 🧪 Шаг 6: Тестирование

### Тест 1: Отправка с сервера
```bash
# На сервере
echo "Test email" | mail -s "Test" info@sunnysiouxcare.com
```

### Тест 2: Контактная форма
1. Зайдите на сайт
2. Заполните контактную форму
3. Проверьте почту info@sunnysiouxcare.com
4. Должно прийти уведомление

### Тест 3: PayPal инвойс
1. Создайте тестовый инвойс на сайте
2. Проверьте почту (которую указали)
3. Должно прийти красивое письмо с кнопкой оплаты

---

## 📊 Что работает автоматически

### Когда клиент заполняет контактную форму:
✅ Данные сохраняются в MongoDB
✅ Вам на `info@sunnysiouxcare.com` приходит красивое уведомление
✅ Клиент видит "Thank you" сообщение

### Когда создаётся PayPal инвойс:
✅ Инвойс создаётся в PayPal
✅ Данные сохраняются в MongoDB
✅ Клиенту на email приходит красивое письмо с кнопкой "Оплатить"
✅ PayPal также отправляет свой инвойс

---

## 🚨 Troubleshooting

### Email не отправляются?
1. Проверьте логи:
```bash
tail -f /var/log/supervisor/backend.err.log
```

2. Проверьте EMAIL_ENABLED:
```bash
grep EMAIL_ENABLED /app/backend/.env
```

3. Проверьте SMTP авторизацию:
```bash
telnet mail.sunnysiouxcare.com 587
```

### DNS записи не работают?
Проверьте DNS с помощью:
```bash
dig MX sunnysiouxcare.com
dig A mail.sunnysiouxcare.com
```

### Письма попадают в спам?
1. Настройте SPF, DKIM, DMARC
2. Прогрейте домен (отправляйте письма постепенно)
3. Используйте Mail-in-a-Box (он всё настроит автоматически)

---

## 💰 Стоимость

| Пункт | Цена | Период |
|-------|------|--------|
| Домен sunnysiouxcare.com | $10-15 | /год |
| VPS сервер (2GB RAM) | $10-12 | /месяц |
| Mail-in-a-Box | БЕСПЛАТНО | - |
| **ИТОГО** | ~$130-160 | /год |

Или можете использовать Google Workspace за $6/месяц = $72/год

---

## 📞 Поддержка

После настройки, если будут проблемы:
1. Проверьте логи backend
2. Проверьте логи почтового сервера: `/var/log/mail.log`
3. Проверьте DNS записи
4. Обратитесь ко мне за помощью

---

## ✅ Чеклист

- [ ] Купил домен sunnysiouxcare.com
- [ ] Купил VPS сервер
- [ ] Установил Mail-in-a-Box или iRedMail
- [ ] Настроил DNS записи (MX, A, SPF, DKIM, DMARC)
- [ ] Создал email аккаунт info@sunnysiouxcare.com
- [ ] Обновил .env файл (EMAIL_ENABLED=true)
- [ ] Перезапустил backend сервер
- [ ] Протестировал отправку email
- [ ] Настроил The Bat
- [ ] Всё работает! 🎉
