# 📧 DNS ЗАПИСИ ДЛЯ НАСТРОЙКИ ПОЧТЫ SUNNYSIOUXCARE.COM

Добавьте следующие DNS записи в вашем Namecheap аккаунте для домена sunnysiouxcare.com:

---

## 1️⃣ MX ЗАПИСЬ (для получения писем)
```
Type: MX
Host: @
Value: mail.sunnysiouxcare.com
Priority: 10
TTL: Auto или 3600
```

## 2️⃣ A ЗАПИСЬ для mail.sunnysiouxcare.com
```
Type: A
Host: mail
Value: 104.248.57.162
TTL: Auto или 3600
```

## 3️⃣ SPF ЗАПИСЬ (защита от спама)
```
Type: TXT
Host: @
Value: v=spf1 ip4:104.248.57.162 a mx ~all
TTL: Auto или 3600
```

## 4️⃣ DKIM ЗАПИСЬ (подпись писем)
```
Type: TXT
Host: mail._domainkey
Value: v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu2P1nB5Xbio7tCYq8byCzEgtb0zsxRqf/rZDo58OIRSBpQw6RVKH/wXPHTJeAWrBs/9mvCe9nioQTI+bebgRsEy9YRdZtCqj1t0KtBiwb2BlmUKxerlOZhd5NHEmHLfkTCtwmaN8b28RLXvxB5SGVBH+HcKSegbbRwkiNcW6x+9e1LTgwtRPDWw4eR+YI+62Tk9ISVJJ9cOVyjp41Eg1ozOdYAS8a5a08y/wuJTxdRcOsD/NLDyqbKzKy82ixGwYVDhzNpfVgoQlRpCwMDdTuUmUZfOtPfPaAHRRMxBK0svgVnYkFjrlletB4mee+3TJgmoP1tk7sCbD1xzPUOMV5QIDAQAB
TTL: Auto или 3600
```

⚠️ ВАЖНО: Value для DKIM должно быть в ОДНОЙ СТРОКЕ, без пробелов и переносов!

## 5️⃣ DMARC ЗАПИСЬ (политика безопасности)
```
Type: TXT
Host: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:info@sunnysiouxcare.com; ruf=mailto:info@sunnysiouxcare.com; fo=1
TTL: Auto или 3600
```

---

## 📝 ИНСТРУКЦИЯ ПО ДОБАВЛЕНИЮ В NAMECHEAP:

1. Войдите в Namecheap Dashboard
2. Перейдите в "Domain List"
3. Нажмите "Manage" рядом с sunnysiouxcare.com
4. Перейдите на вкладку "Advanced DNS"
5. Нажмите "Add New Record" для каждой записи выше
6. Введите данные согласно таблицам выше
7. Нажмите галочку ✓ для сохранения

---

## ⏱️ ВРЕМЯ РАСПРОСТРАНЕНИЯ DNS:

- DNS записи могут распространяться от 5 минут до 48 часов
- Обычно работает через 15-30 минут
- Проверить можно через: https://mxtoolbox.com/

---

## 🔐 УЧЕТНЫЕ ДАННЫЕ ДЛЯ ПОДКЛЮЧЕНИЯ К ПОЧТЕ:

### Для отправки (SMTP):
- Сервер: mail.sunnysiouxcare.com (или localhost на сервере)
- Порт: 587 (STARTTLS)
- Логин: info
- Пароль: GPnMwxFkbYc3YVRVfufbxXms2j+dKm2j
- Шифрование: STARTTLS/TLS

### Для получения (IMAP):
- Сервер: mail.sunnysiouxcare.com
- Порт: 993 (SSL/TLS)
- Логин: info
- Пароль: GPnMwxFkbYc3YVRVfufbxXms2j+dKm2j
- Шифрование: SSL/TLS

---

## 📮 НАСТРОЙКА В ПОЧТОВЫХ КЛИЕНТАХ:

### Gmail (через приложение Mail):
1. Настройки → Аккаунты → Добавить аккаунт → Другой
2. Email: info@sunnysiouxcare.com
3. Используйте настройки IMAP и SMTP выше

### Outlook / Thunderbird:
1. Добавить аккаунт → Ручная настройка
2. Используйте настройки IMAP и SMTP выше

---

## ✅ ПОСЛЕ ДОБАВЛЕНИЯ DNS ЗАПИСЕЙ:

Подождите 15-30 минут, затем проверьте:

1. **MX записи**: https://mxtoolbox.com/SuperTool.aspx?action=mx%3asunnysiouxcare.com
2. **SPF запись**: https://mxtoolbox.com/SuperTool.aspx?action=spf%3asunnysiouxcare.com
3. **DKIM запись**: https://mxtoolbox.com/SuperTool.aspx?action=dkim%3amail%3asunnysiouxcare.com

---

## 🎉 ЧТО РАБОТАЕТ СЕЙЧАС:

✅ Postfix (SMTP сервер) - запущен
✅ Dovecot (IMAP/POP3 сервер) - запущен
✅ OpenDKIM (подпись писем) - запущен
✅ Backend API с email интеграцией - включен
✅ Пользователь info@sunnysiouxcare.com - создан

После добавления DNS записей почта будет полностью работать! 🚀
