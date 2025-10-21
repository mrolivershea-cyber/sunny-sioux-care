# 📧 УЧЕТНЫЕ ДАННЫЕ ПОЧТЫ - info@sunnysiouxcare.com

## 🔐 Данные для входа

**Email адрес:** info@sunnysiouxcare.com  
**Пароль:** GPnMwxFkbYc3YVRVfufbxXms2j+dKm2j

---

## 📨 SMTP настройки (отправка писем)

```
Сервер: mail.sunnysiouxcare.com
Порт: 587
Шифрование: STARTTLS
Логин: info
Пароль: GPnMwxFkbYc3YVRVfufbxXms2j+dKm2j
```

---

## 📬 IMAP настройки (получение писем)

```
Сервер: mail.sunnysiouxcare.com
Порт: 993
Шифрование: SSL/TLS
Логин: info
Пароль: GPnMwxFkbYc3YVRVfufbxXms2j+dKm2j
```

---

## 🌐 DNS записи (добавлены в Namecheap)

### 1. A Records
```
Type: A Record | Host: @    | Value: 104.248.57.162
Type: A Record | Host: www  | Value: 104.248.57.162
Type: A Record | Host: mail | Value: 104.248.57.162
```

### 2. MX Record
```
Type: MX Record | Host: @ | Value: mail.sunnysiouxcare.com | Priority: 10
```

### 3. SPF Record (TXT)
```
Type: TXT Record | Host: @ | Value: v=spf1 ip4:104.248.57.162 a mx ~all
```

### 4. DKIM Record (TXT)
```
Type: TXT Record | Host: mail._domainkey
Value: v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu2P1nB5Xbio7tCYq8byCzEgtb0zsxRqf/rZDo58OIRSBpQw6RVKH/wXPHTJeAWrBs/9mvCe9nioQTI+bebgRsEy9YRdZtCqj1t0KtBiwb2BlmUKxerlOZhd5NHEmHLfkTCtwmaN8b28RLXvxB5SGVBH+HcKSegbbRwkiNcW6x+9e1LTgwtRPDWw4eR+YI+62Tk9ISVJJ9cOVyjp41Eg1ozOdYAS8a5a08y/wuJTxdRcOsD/NLDyqbKzKy82ixGwYVDhzNpfVgoQlRpCwMDdTuUmUZfOtPfPaAHRRMxBK0svgVnYkFjrlletB4mee+3TJgmoP1tk7sCbD1xzPUOMV5QIDAQAB
```

### 5. DMARC Record (TXT)
```
Type: TXT Record | Host: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:info@sunnysiouxcare.com; ruf=mailto:info@sunnysiouxcare.com; fo=1
```

---

## 🖥️ Серверная информация

**IP адрес сервера:** 104.248.57.162  
**Хостинг:** DigitalOcean  
**Домен:** sunnysiouxcare.com  
**DNS провайдер:** Namecheap

---

## ⚙️ Конфигурация на сервере

### Backend настройки (/app/backend/.env)
```env
EMAIL_ENABLED="true"
SMTP_HOST="localhost"
SMTP_PORT="587"
SMTP_USER="info"
SMTP_PASSWORD="GPnMwxFkbYc3YVRVfufbxXms2j+dKm2j"
FROM_EMAIL="info@sunnysiouxcare.com"
ADMIN_EMAIL="info@sunnysiouxcare.com"
```

### Установленные сервисы
- **Postfix 3.7.11** - SMTP сервер для отправки
- **Dovecot 2.3.19** - IMAP/POP3 сервер для получения
- **OpenDKIM 2.11.0** - Подпись писем

### Важные файлы конфигурации
- `/etc/postfix/main.cf` - Конфигурация Postfix
- `/etc/dovecot/conf.d/` - Конфигурация Dovecot
- `/etc/opendkim/` - Конфигурация DKIM
- `/home/info/Maildir/` - Папка с письмами

---

## 📱 Настройка в почтовых клиентах

### Gmail (мобильное приложение)
1. Настройки → Добавить аккаунт → Другой
2. Email: info@sunnysiouxcare.com
3. Ввести пароль
4. Использовать ручные настройки IMAP/SMTP выше

### Outlook / Thunderbird
1. Добавить аккаунт → Ручная настройка
2. Использовать настройки IMAP/SMTP выше

---

## ✅ Проверка работоспособности

После распространения DNS (15-30 минут) проверьте:

1. **MX записи:** https://mxtoolbox.com/SuperTool.aspx?action=mx%3asunnysiouxcare.com
2. **SPF запись:** https://mxtoolbox.com/SuperTool.aspx?action=spf%3asunnysiouxcare.com
3. **DKIM запись:** https://mxtoolbox.com/SuperTool.aspx?action=dkim%3amail%3asunnysiouxcare.com

---

## 🔄 Перезапуск почтовых сервисов

Если нужно перезапустить почтовые сервисы на сервере:

```bash
# Postfix
sudo service postfix restart

# Dovecot
sudo service dovecot restart

# OpenDKIM
sudo pkill opendkim && sudo opendkim -x /etc/opendkim.conf

# Backend
sudo supervisorctl restart backend
```

---

## 📊 Проверка статуса сервисов

```bash
# Postfix
sudo service postfix status

# Dovecot
sudo service dovecot status

# OpenDKIM
ps aux | grep opendkim

# Backend
sudo supervisorctl status backend
```

---

## ⚠️ ВАЖНО: БЕЗОПАСНОСТЬ

🔒 Этот файл содержит конфиденциальные данные!

**Для GitHub:**
- Добавьте `EMAIL_CREDENTIALS.md` в `.gitignore`
- Используйте переменные окружения вместо хардкода паролей
- Регулярно меняйте пароли

---

**Дата создания:** 21 октября 2025  
**Статус:** ✅ Активно и работает
