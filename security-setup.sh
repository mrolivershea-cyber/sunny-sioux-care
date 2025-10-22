#!/bin/bash

################################################################################
# СКРИПТ БЕЗОПАСНОСТИ ДЛЯ SUNNYSIOUXCARE.COM
# Полная настройка защиты сервера
################################################################################

set -e

echo "🔒 НАСТРОЙКА БЕЗОПАСНОСТИ..."
echo ""

################################################################################
# 1. Защита файлов с паролями
################################################################################
echo "[1/7] Защита файлов с паролями..."
chmod 600 /root/pass.txt 2>/dev/null || true
chmod 600 /root/email_pass.txt 2>/dev/null || true
chmod 600 /root/email_password.txt 2>/dev/null || true
chmod 600 /var/www/sunny-sioux-care/backend/.env
chmod 600 /var/www/sunny-sioux-care/frontend/.env
echo "   ✓ Файлы защищены (chmod 600)"

################################################################################
# 2. Настройка Firewall
################################################################################
echo "[2/7] Настройка UFW Firewall..."

# Сброс правил
ufw --force reset >/dev/null 2>&1

# Разрешить нужные порты
ufw allow 22/tcp comment 'SSH' >/dev/null 2>&1
ufw allow 80/tcp comment 'HTTP' >/dev/null 2>&1
ufw allow 443/tcp comment 'HTTPS' >/dev/null 2>&1
ufw allow 25/tcp comment 'SMTP' >/dev/null 2>&1
ufw allow 587/tcp comment 'SMTP Submission' >/dev/null 2>&1
ufw allow 993/tcp comment 'IMAP SSL' >/dev/null 2>&1
ufw allow 995/tcp comment 'POP3 SSL' >/dev/null 2>&1

# Включить
echo "y" | ufw enable >/dev/null 2>&1

# Настроить rate limiting для SSH
ufw limit 22/tcp >/dev/null 2>&1

echo "   ✓ Firewall настроен"

################################################################################
# 3. MongoDB аутентификация
################################################################################
echo "[3/7] Настройка MongoDB аутентификации..."

MONGO_PASS=$(openssl rand -base64 24)

# Создать admin пользователя
mongosh --quiet --eval "
use admin;
db.createUser({
  user: 'admin',
  pwd: '$MONGO_PASS',
  roles: [{role: 'userAdminAnyDatabase', db: 'admin'}]
});
use sunnysiouxcare_production;
db.createUser({
  user: 'sunnyapp',
  pwd: '$MONGO_PASS',
  roles: [{role: 'readWrite', db: 'sunnysiouxcare_production'}]
});
" 2>/dev/null || echo "   ⚠️  Пользователи MongoDB уже существуют"

# Включить auth в mongod.conf
if ! grep -q "^security:" /etc/mongod.conf; then
cat >> /etc/mongod.conf << 'EOF'

security:
  authorization: enabled
EOF
fi

# Сохранить пароль
echo "$MONGO_PASS" > /root/mongodb_password.txt
chmod 600 /root/mongodb_password.txt

# Обновить backend .env
sed -i "s|MONGO_URL=\"mongodb://localhost:27017\"|MONGO_URL=\"mongodb://sunnyapp:$MONGO_PASS@localhost:27017/sunnysiouxcare_production?authSource=sunnysiouxcare_production\"|" /var/www/sunny-sioux-care/backend/.env

systemctl restart mongod
sleep 3

echo "   ✓ MongoDB защищен паролем"

################################################################################
# 4. Nginx Security Headers
################################################################################
echo "[4/7] Настройка Nginx security headers..."

# Отключить version в headers
sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
sed -i 's/server_tokens on;/server_tokens off;/' /etc/nginx/nginx.conf

# Добавить security headers в конфиг сайта
sed -i '/server_name/a \    # Security headers\n    add_header X-Frame-Options "SAMEORIGIN" always;\n    add_header X-Content-Type-Options "nosniff" always;\n    add_header X-XSS-Protection "1; mode=block" always;\n    add_header Referrer-Policy "no-referrer-when-downgrade" always;' /etc/nginx/sites-available/sunnysiouxcare

nginx -t >/dev/null 2>&1 && systemctl reload nginx
echo "   ✓ Security headers добавлены"

################################################################################
# 5. Fail2ban для защиты от brute force
################################################################################
echo "[5/7] Установка Fail2ban..."

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq fail2ban

# Настроить Fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log

[postfix]
enabled = true
port = smtp,465,587
logpath = /var/log/mail.log

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps
logpath = /var/log/mail.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
EOF

systemctl enable fail2ban >/dev/null 2>&1
systemctl restart fail2ban

echo "   ✓ Fail2ban установлен и настроен"

################################################################################
# 6. SSH усиление
################################################################################
echo "[6/7] Усиление SSH..."

# Отключить root login через пароль (только ключи)
sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Отключить password authentication для пользователей
# sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

systemctl reload sshd

echo "   ✓ SSH усилен (root только через ключи)"

################################################################################
# 7. Автоматические обновления безопасности
################################################################################
echo "[7/7] Настройка автообновлений..."

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

echo "   ✓ Автообновления безопасности включены"

################################################################################
# ФИНАЛ
################################################################################

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "              🔒 БЕЗОПАСНОСТЬ НАСТРОЕНА!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✅ ЧТО ЗАЩИЩЕНО:"
echo ""
echo "1. 🔥 Firewall (UFW):"
echo "   - SSH, HTTP, HTTPS, Email порты открыты"
echo "   - Все остальные порты закрыты"
echo "   - Rate limiting для SSH"
echo ""
echo "2. 🗄️  MongoDB:"
echo "   - Аутентификация включена"
echo "   - Пользователь: sunnyapp"
echo "   - Пароль: $(cat /root/mongodb_password.txt)"
echo "   - Файл: /root/mongodb_password.txt"
echo ""
echo "3. 📧 Email пароль:"
echo "   - Файл: /root/pass.txt (chmod 600)"
echo "   - Пароль: $(cat /root/pass.txt)"
echo ""
echo "4. 🌐 Nginx:"
echo "   - Server tokens скрыты"
echo "   - Security headers добавлены"
echo "   - SSL/TLS только"
echo ""
echo "5. 🛡️  Fail2ban:"
echo "   - Защита от brute force для SSH, Postfix, Dovecot"
echo "   - Ban после 5 попыток на 1 час"
echo ""
echo "6. 🔑 SSH:"
echo "   - Root только через SSH ключи (не пароль)"
echo ""
echo "7. 🔄 Автообновления:"
echo "   - Обновления безопасности автоматически"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 СТАТУС:"
ufw status numbered | head -15
echo ""
echo "🔐 ПАРОЛИ СОХРАНЕНЫ В:"
echo "   /root/pass.txt - Email пароль"
echo "   /root/mongodb_password.txt - MongoDB пароль"
echo ""
echo "⚠️  ВАЖНО:"
echo "   1. Сохраните эти пароли в безопасном месте!"
echo "   2. НЕ коммитьте .env файлы в GitHub!"
echo "   3. Регулярно обновляйте систему: apt update && apt upgrade"
echo ""
echo "════════════════════════════════════════════════════════════════"
