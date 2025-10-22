#!/bin/bash

###############################################################################
# 🚀 Универсальный скрипт установки SunnySiouxCare с GitHub
# Версия: 2.0
# Дата: 21 октября 2025
# Использование: curl -fsSL https://raw.githubusercontent.com/mrolivershea-cyber/sunny-sioux-care/main/install-from-github.sh | sudo bash
###############################################################################

set -e  # Остановить при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
PROJECT_DIR="/var/www/sunny-sioux-care"
GITHUB_REPO="https://github.com/mrolivershea-cyber/sunny-sioux-care.git"
GITHUB_BRANCH="main"

###############################################################################
# Функции
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

###############################################################################
# Проверка системы
###############################################################################

check_system() {
    log_info "Проверка системы..."
    
    # Проверить ОС
    if [ ! -f /etc/os-release ]; then
        log_error "Неподдерживаемая ОС"
        exit 1
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_warning "ОС не Ubuntu/Debian, могут быть проблемы"
    fi
    
    # Проверить права root
    if [ "$EUID" -ne 0 ]; then 
        log_error "Запустите с sudo"
        exit 1
    fi
    
    log_success "Система: $PRETTY_NAME"
}

###############################################################################
# Проверка существующей установки
###############################################################################

check_existing() {
    if [ -d "$PROJECT_DIR" ]; then
        log_warning "Проект уже существует в $PROJECT_DIR"
        echo
        echo "Выберите действие:"
        echo "  1) Удалить и переустановить (все данные будут потеряны!)"
        echo "  2) Обновить существующий проект (рекомендуется)"
        echo "  3) Отмена"
        echo
        read -p "Ваш выбор (1/2/3): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                log_warning "Удаление существующего проекта..."
                # Создать бэкап на всякий случай
                BACKUP_FILE="/var/www/sunny-sioux-care-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
                tar -czf "$BACKUP_FILE" "$PROJECT_DIR" 2>/dev/null || true
                log_info "Бэкап создан: $BACKUP_FILE"
                
                rm -rf "$PROJECT_DIR"
                log_success "Старый проект удален"
                ;;
            2)
                log_info "Запуск обновления..."
                if [ -f "$PROJECT_DIR/update-from-github.sh" ]; then
                    bash "$PROJECT_DIR/update-from-github.sh"
                else
                    log_error "Скрипт обновления не найден"
                    log_info "Скачайте update-from-github.sh из репозитория"
                fi
                exit 0
                ;;
            3)
                log_info "Установка отменена"
                exit 0
                ;;
            *)
                log_error "Неверный выбор"
                exit 1
                ;;
        esac
    fi
}

###############################################################################
# Установка системных зависимостей
###############################################################################

install_system_dependencies() {
    log_info "Установка системных зависимостей..."
    
    # Обновить список пакетов
    apt-get update -qq
    
    # Установить базовые пакеты
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        git \
        python3.11 \
        python3.11-venv \
        python3-pip \
        nginx \
        supervisor \
        certbot \
        python3-certbot-nginx \
        ufw \
        gnupg \
        build-essential
    
    # Установить MongoDB
    log_info "Установка MongoDB 7.0..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    apt-get update -qq
    apt-get install -y mongodb-org
    systemctl enable mongod
    systemctl start mongod
    
    # Установить Node.js 20
    if ! command -v node &> /dev/null || [ "$(node -v | cut -d'.' -f1 | sed 's/v//')" -lt 20 ]; then
        log_info "Установка Node.js 20..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi
    
    # Установить Yarn
    if ! command -v yarn &> /dev/null; then
        npm install -g yarn
    fi
    
    log_success "Системные зависимости установлены"
}

###############################################################################
# Установка почтового сервера
###############################################################################

install_email_server() {
    log_info "Установка почтового сервера (Postfix + Dovecot + OpenDKIM)..."
    
    # Установить пакеты
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        postfix \
        dovecot-core \
        dovecot-imapd \
        dovecot-pop3d \
        opendkim \
        opendkim-tools \
        mailutils
    
    # Создать email пользователя
    EMAIL_USER="info"
    EMAIL_PASSWORD=$(openssl rand -base64 24)
    useradd -m -s /bin/bash "$EMAIL_USER" 2>/dev/null || true
    echo "$EMAIL_USER:$EMAIL_PASSWORD" | chpasswd
    mkdir -p /home/$EMAIL_USER/Maildir/{cur,new,tmp}
    chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir
    chmod -R 700 /home/$EMAIL_USER/Maildir
    
    # Сохранить пароль
    echo "$EMAIL_PASSWORD" > /root/email_password.txt

###############################################################################
# Настройка почтового сервера
###############################################################################

configure_email_server() {
    if [ ! -f /root/email_password.txt ]; then
        log_info "Почтовый сервер не установлен, пропускаем настройку"
        return
    fi
    
    log_info "Настройка почтового сервера..."
    
    EMAIL_PASSWORD=$(cat /root/email_password.txt)
    DOMAIN="sunnysiouxcare.com"
    
    # Настроить Postfix
    cat > /etc/postfix/main.cf << 'EOFPOSTFIX'
myhostname = mail.sunnysiouxcare.com
mydomain = sunnysiouxcare.com
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
relayhost =
mynetworks = 127.0.0.0/8
inet_interfaces = all
inet_protocols = all
home_mailbox = Maildir/

smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level=may

smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes

smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
EOFPOSTFIX

    # Добавить submission порт
    grep -q "^submission inet" /etc/postfix/master.cf || cat >> /etc/postfix/master.cf << 'EOFSUB'

submission inet n - y - - smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
EOFSUB

    # Настроить Dovecot
    sed -i 's|mail_location = .*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf 2>/dev/null || true
    sed -i 's|#disable_plaintext_auth = yes|disable_plaintext_auth = yes|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true
    sed -i 's|auth_mechanisms = plain|auth_mechanisms = plain login|' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true
    
    # Простой 10-master.conf
    cat > /etc/dovecot/conf.d/10-master.conf << 'EOFMASTER'
service imap-login {
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOFMASTER

    # Запустить сервисы
    systemctl restart postfix dovecot 2>/dev/null || true
    
    log_success "Почтовый сервер настроен"
}

    chmod 600 /root/email_password.txt
    
    log_success "Почтовый сервер установлен"
    log_info "Email: info@sunnysiouxcare.com | Пароль в /root/email_password.txt"
}

###############################################################################
# Клонирование репозитория
###############################################################################

clone_repository() {
    log_info "Клонирование репозитория с GitHub..."
    
    mkdir -p /var/www
    cd /var/www
    
    git clone "$GITHUB_REPO" sunny-sioux-care
    cd sunny-sioux-care
    git checkout "$GITHUB_BRANCH"
    
    log_success "Репозиторий склонирован"
}

###############################################################################
# Настройка Backend
###############################################################################

setup_backend() {
    log_info "Настройка Backend..."
    
    cd "$PROJECT_DIR/backend"
    
    # Создать виртуальное окружение
    python3.11 -m venv venv
    source venv/bin/activate
    
    # Установить зависимости
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Создать .env если не существует
    if [ ! -f .env ]; then
        cp .env.example .env
        log_warning "Создан backend/.env - ЗАПОЛНИТЕ СВОИМИ ДАННЫМИ!"
        
        echo
        log_info "Необходимо настроить:"
        echo "  • PAYPAL_CLIENT_ID"
        echo "  • PAYPAL_CLIENT_SECRET"
        echo "  • EMAIL_ENABLED и SMTP настройки (если нужна почта)"
        echo
        read -p "Нажмите Enter когда заполните .env..."
    fi
    
    deactivate
    
    log_success "Backend настроен"
}

###############################################################################
# Настройка Frontend
###############################################################################

setup_frontend() {
    log_info "Настройка Frontend..."
    
    cd "$PROJECT_DIR/frontend"
    
    # Установить зависимости
    yarn install
    
    # Создать .env если не существует
    if [ ! -f .env ]; then
        cp .env.example .env
        log_warning "Создан frontend/.env"
        
        # Запросить домен
        echo
        read -p "Введите ваш домен (например: https://sunnysiouxcare.com): " DOMAIN
        sed -i "s|https://sunny-installer.preview.emergentagent.com|$DOMAIN|g" .env
    fi
    
    # Собрать frontend
    log_info "Сборка frontend (может занять несколько минут)..."
    export NODE_OPTIONS="--max-old-space-size=1024"
    yarn build
    
    log_success "Frontend настроен и собран"
}

###############################################################################
# Настройка Supervisor
###############################################################################

setup_supervisor() {
    log_info "Настройка Supervisor..."
    
    # Backend
    cat > /etc/supervisor/conf.d/sunny-backend.conf << EOF
[program:backend]
directory=$PROJECT_DIR/backend
command=$PROJECT_DIR/backend/venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8001
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/backend.err.log
stdout_logfile=/var/log/supervisor/backend.out.log
environment=PYTHONPATH="$PROJECT_DIR/backend"
EOF
    
    # Frontend (статичный, но можно добавить dev сервер если нужно)
    
    supervisorctl reread
    supervisorctl update
    supervisorctl start backend
    
    log_success "Supervisor настроен"
}

###############################################################################
# Настройка Nginx
###############################################################################

setup_nginx() {
    log_info "Настройка Nginx..."
    
    echo
    read -p "Введите ваш домен (например: sunnysiouxcare.com): " DOMAIN
    
    cat > /etc/nginx/sites-available/sunnysiouxcare << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Frontend
    root $PROJECT_DIR/frontend/build;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOF
    
    # Включить сайт
    ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Проверить конфигурацию
    nginx -t
    systemctl restart nginx
    
    log_success "Nginx настроен"
    
    # SSL
    log_info "Настроить SSL сертификат Let's Encrypt?"
    read -p "Настроить SSL? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Установка SSL сертификата..."
        certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email || log_warning "SSL не установлен, настройте вручную"
    fi
}

###############################################################################
# Настройка firewall
###############################################################################

setup_firewall() {
    log_info "Настройка firewall..."
    
    # Разрешить нужные порты
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 587/tcp  # SMTP
    ufw allow 993/tcp  # IMAP
    ufw allow 25/tcp   # SMTP (получение)
    
    # Включить firewall
    echo "y" | ufw enable || true
    
    log_success "Firewall настроен"
}

###############################################################################
# Финальная проверка
###############################################################################

final_check() {
    log_info "Финальная проверка..."
    
    sleep 3
    
    # Проверить сервисы
    supervisorctl status
    
    # Проверить backend
    if curl -f -s http://localhost:8001/api/status > /dev/null 2>&1; then
        log_success "✓ Backend работает"
    else
        log_warning "⚠ Backend не отвечает"
    fi
    
    # Проверить Nginx
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx работает"
    else
        log_warning "⚠ Nginx не работает"
    fi
}

###############################################################################
# Главная функция
###############################################################################

main() {
    clear
    echo "═══════════════════════════════════════════════════════════"
    echo "  🚀 Установка SunnySiouxCare.com с GitHub"
    echo "═══════════════════════════════════════════════════════════"
    echo
    
    check_system
    check_existing
    install_system_dependencies
    install_email_server
    configure_email_server
    clone_repository
    setup_backend
    setup_frontend
    setup_supervisor
    setup_nginx
    setup_firewall
    final_check
    
    echo
    echo "═══════════════════════════════════════════════════════════"
    log_success "✅ Установка завершена успешно!"
    echo "═══════════════════════════════════════════════════════════"
    echo
    log_info "📋 Что дальше:"
    echo "  1. Заполните backend/.env (PayPal ключи, email настройки)"
    echo "  2. Перезапустите backend: sudo supervisorctl restart backend"
    echo "  3. Настройте DNS для вашего домена"
    echo "  4. Настройте почтовый сервер (см. EMAIL_SERVER_SUCCESS.md)"
    echo
    log_info "📂 Проект установлен в: $PROJECT_DIR"
    log_info "📖 Документация:"
    echo "  • README.md - Основная документация"
    echo "  • EMAIL_SERVER_SUCCESS.md - Настройка почты"
    echo "  • DNS_EMAIL_SETUP.md - Настройка DNS"
    echo
    log_info "🔄 Для обновления в будущем:"
    echo "  cd $PROJECT_DIR && sudo bash update-from-github.sh"
    echo
    log_success "Готово! 🎉"
    echo
}

###############################################################################
# Обработка ошибок
###############################################################################

trap 'log_error "Ошибка при установке! Проверьте логи выше."' ERR

###############################################################################
# Запуск
###############################################################################

main "$@"
