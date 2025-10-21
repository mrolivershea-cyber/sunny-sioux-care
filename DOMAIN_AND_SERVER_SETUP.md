# 🌐 Пошаговая инструкция: Домен + Сервер для SunnySiouxCare.com

## Шаг 1: Покупка Droplet на DigitalOcean

### Рекомендуемая конфигурация:

**1. Choose an image:**
- ✅ **Ubuntu 22.04 LTS x64** (самая стабильная)

**2. Choose a plan:**
- **Regular** (SSD)
- **Рекомендую:** $12/month
  - 2 GB RAM
  - 1 vCPU
  - 50 GB SSD
  - 2 TB Transfer

**Минимум (если бюджет ограничен):**
- $6/month
  - 1 GB RAM
  - 1 vCPU
  - 25 GB SSD
  - 1 TB Transfer

**3. Choose a datacenter region:**
- ✅ **New York 1** (ближе к Sioux City, IA)
- Или **San Francisco 3** (тоже хороший вариант)

**4. Authentication:**
- ✅ **SSH Key** (безопаснее) - создайте если нет
- Или **Password** (проще, но менее безопасно)

**5. Hostname:**
- Введите: `sunnysiouxcare`

**6. Нажмите "Create Droplet"**

### После создания:
- Получите IP адрес (например: `123.45.67.89`)
- Скопируйте этот IP - он понадобится для DNS!

---

## Шаг 2: Настройка DNS на Namecheap

### Зайдите в Namecheap Dashboard:

1. **Domain List** → Найдите ваш домен → **MANAGE**

2. **Advanced DNS** → Add new records:

### Добавьте записи:

**A Record #1:**
```
Type: A Record
Host: @
Value: ВАШ_IP_DIGITALOCEAN (например: 123.45.67.89)
TTL: Automatic
```

**A Record #2:**
```
Type: A Record
Host: www
Value: ВАШ_IP_DIGITALOCEAN (например: 123.45.67.89)
TTL: Automatic
```

**Для email (потом, после настройки Mail-in-a-Box):**
```
Type: A Record
Host: mail
Value: ВАШ_IP_DIGITALOCEAN
TTL: Automatic
```

```
Type: MX Record
Host: @
Value: mail.sunnysiouxcare.com
Priority: 10
TTL: Automatic
```

```
Type: TXT Record
Host: @
Value: v=spf1 mx ~all
TTL: Automatic
```

**3. Сохраните изменения**

⚠️ **Важно:** DNS изменения могут занять 5-60 минут!

---

## Шаг 3: Первое подключение к серверу

### Через SSH:

**Если используете Windows:**
Скачайте **PuTTY** или используйте **PowerShell**

**MacOS/Linux:**
Откройте терминал

```bash
# Подключение
ssh root@ВАШ_IP_DIGITALOCEAN

# Первый раз попросит подтвердить - введите: yes
```

**Если используете пароль:**
Введите пароль который DigitalOcean отправил на email

---

## Шаг 4: Начальная настройка сервера

После подключения выполните:

```bash
# Обновление системы
apt update && apt upgrade -y

# Установка базовых пакетов
apt install -y curl wget git nano htop ufw

# Настройка Firewall
ufw allow OpenSSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable

# Создание пользователя (опционально, но безопаснее)
adduser deploy
usermod -aG sudo deploy
```

---

## Шаг 5: Проверка домена

Через 10-15 минут после настройки DNS:

```bash
# Проверьте что домен указывает на ваш сервер
ping sunnysiouxcare.com

# Должны увидеть ваш IP
```

**Или откройте в браузере:**
http://ваш-ip-адрес

Должны увидеть страницу по умолчанию Nginx (после установки).

---

## Шаг 6: Установка проекта

Теперь следуйте инструкциям из **DEPLOYMENT_GUIDE.md**:

```bash
# Установка MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod

# Установка Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Установка Yarn
npm install -g yarn

# Установка PM2
npm install -g pm2

# Установка Python 3.11
apt install -y python3.11 python3.11-venv python3-pip

# Установка Nginx
apt install -y nginx
systemctl start nginx
systemctl enable nginx

# Клонирование проекта
cd /var/www/
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git
cd sunny-sioux-care
```

---

## 📋 Чеклист

- [ ] Создан Droplet на DigitalOcean (Ubuntu 22.04, $12/month)
- [ ] Получен IP адрес сервера
- [ ] DNS записи добавлены на Namecheap (A, www, MX, TXT)
- [ ] Подключился к серверу по SSH
- [ ] Обновил систему (apt update && upgrade)
- [ ] Настроил Firewall (ufw)
- [ ] Домен пингуется и указывает на сервер
- [ ] Установил MongoDB, Node.js, Python, Nginx
- [ ] Клонировал проект с GitHub

---

## 🆘 Если что-то не работает

**Домен не открывается:**
- Подождите 30-60 минут (DNS распространение)
- Проверьте: `ping sunnysiouxcare.com`
- Проверьте DNS: https://dnschecker.org/

**Не могу подключиться по SSH:**
- Проверьте IP адрес
- Проверьте что Droplet запущен (Running)
- Попробуйте reset password в DigitalOcean

**Firewall блокирует:**
```bash
ufw status
ufw allow 80/tcp
ufw allow 443/tcp
```

---

## ⏭️ Следующие шаги

После выполнения всех пунктов выше:

1. **Следуйте DEPLOYMENT_GUIDE.md** - установка приложения
2. **Настройте .env файлы** с реальными данными
3. **Получите SSL сертификат** (Let's Encrypt)
4. **Запустите приложение** (PM2 + Nginx)
5. **Настройте email** (EMAIL_SETUP_INSTRUCTIONS.md)

---

## 💰 Стоимость

**DigitalOcean:** $12/месяц = $144/год
**Namecheap домен:** $10-15/год
**SSL сертификат:** БЕСПЛАТНО (Let's Encrypt)

**Итого:** ~$155-160/год

---

## 📞 Поддержка

Если возникнут проблемы на любом этапе - напишите мне, помогу!

**Полезные ссылки:**
- DigitalOcean: https://cloud.digitalocean.com/
- Namecheap: https://www.namecheap.com/
- GitHub проект: https://github.com/mrolivershea-cyber/sunny-sioux-care
- DNS Checker: https://dnschecker.org/
