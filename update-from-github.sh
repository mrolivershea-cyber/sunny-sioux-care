#!/bin/bash

###############################################################################
# 🚀 Универсальный скрипт обновления SunnySiouxCare с GitHub
# Версия: 2.0
# Дата: 21 октября 2025
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
BACKUP_DIR="/var/www/backups"

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
# Создание бэкапа
###############################################################################

create_backup() {
    log_info "Создание бэкапа..."
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/sunny-sioux-care-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    # Сохранить .env файлы отдельно
    if [ -f "$PROJECT_DIR/backend/.env" ]; then
        cp "$PROJECT_DIR/backend/.env" "$BACKUP_DIR/backend.env.backup"
        log_success ".env файлы сохранены"
    fi
    
    if [ -f "$PROJECT_DIR/frontend/.env" ]; then
        cp "$PROJECT_DIR/frontend/.env" "$BACKUP_DIR/frontend.env.backup"
    fi
    
    # Создать полный бэкап (кроме node_modules)
    cd /var/www
    tar --exclude='sunny-sioux-care/node_modules' \
        --exclude='sunny-sioux-care/frontend/node_modules' \
        --exclude='sunny-sioux-care/backend/venv' \
        -czf "$BACKUP_FILE" sunny-sioux-care/ 2>/dev/null || true
    
    log_success "Бэкап создан: $BACKUP_FILE"
}

###############################################################################
# Обновление из GitHub
###############################################################################

update_from_github() {
    log_info "Обновление из GitHub..."
    
    cd "$PROJECT_DIR"
    
    # Проверить что это git репозиторий
    if [ ! -d ".git" ]; then
        log_error "Это не git репозиторий! Используйте install-from-github.sh для новой установки."
        exit 1
    fi
    
    # Проверить наличие изменений
    log_info "Проверка обновлений..."
    git fetch origin
    
    BEHIND=$(git rev-list HEAD..origin/main --count)
    
    if [ "$BEHIND" -eq 0 ]; then
        log_success "Проект уже обновлен! Нет новых изменений."
        read -p "Хотите перезапустить сервисы? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            restart_services
        fi
        exit 0
    fi
    
    log_info "Найдено обновлений: $BEHIND"
    
    # Показать что изменилось
    log_info "Изменения:"
    git log HEAD..origin/main --oneline --decorate --color
    
    echo
    read -p "Продолжить обновление? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Обновление отменено"
        exit 0
    fi
    
    # Сохранить .env файлы
    cp backend/.env /tmp/backend.env.temp 2>/dev/null || true
    cp frontend/.env /tmp/frontend.env.temp 2>/dev/null || true
    
    # Получить изменения
    log_info "Получение изменений из GitHub..."
    git stash 2>/dev/null || true
    git pull origin main
    
    # Восстановить .env файлы
    cp /tmp/backend.env.temp backend/.env 2>/dev/null || true
    cp /tmp/frontend.env.temp frontend/.env 2>/dev/null || true
    rm /tmp/*.env.temp 2>/dev/null || true
    
    log_success "Код обновлен из GitHub"
}

###############################################################################
# Обновление зависимостей
###############################################################################

update_dependencies() {
    cd "$PROJECT_DIR"
    
    # Проверить изменения в backend
    if git diff HEAD@{1} HEAD --name-only 2>/dev/null | grep -q "backend/"; then
        log_info "Обнаружены изменения в backend, обновление зависимостей..."
        
        cd backend
        
        # Проверить/создать виртуальное окружение
        if [ ! -d "venv" ]; then
            log_info "Создание виртуального окружения..."
            python3.11 -m venv venv
        fi
        
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
        deactivate
        
        log_success "Backend зависимости обновлены"
        BACKEND_UPDATED=true
    else
        log_info "Backend не изменен"
        BACKEND_UPDATED=false
    fi
    
    # Проверить изменения в frontend
    if git diff HEAD@{1} HEAD --name-only 2>/dev/null | grep -q "frontend/"; then
        log_info "Обнаружены изменения в frontend, обновление..."
        
        cd "$PROJECT_DIR/frontend"
        
        # Установить зависимости
        yarn install
        
        # Пересобрать
        log_info "Сборка frontend..."
        export NODE_OPTIONS="--max-old-space-size=1024"
        yarn build
        
        log_success "Frontend обновлен и пересобран"
        FRONTEND_UPDATED=true
    else
        log_info "Frontend не изменен"
        FRONTEND_UPDATED=false
    fi
}

###############################################################################
# Перезапуск сервисов
###############################################################################

restart_services() {
    log_info "Перезапуск сервисов..."
    
    # Перезапустить backend если изменился
    if [ "$BACKEND_UPDATED" = true ] || [ "$1" = "force" ]; then
        log_info "Перезапуск backend..."
        supervisorctl restart backend || pm2 restart backend || true
    fi
    
    # Перезапустить frontend если изменился
    if [ "$FRONTEND_UPDATED" = true ] || [ "$1" = "force" ]; then
        log_info "Перезапуск frontend..."
        supervisorctl restart frontend || pm2 restart frontend || true
    fi
    
    # Если ничего не изменилось но попросили перезапустить
    if [ "$1" = "force" ]; then
        supervisorctl restart all 2>/dev/null || pm2 restart all || true
    fi
    
    sleep 3
    
    # Проверить статус
    log_info "Статус сервисов:"
    supervisorctl status 2>/dev/null || pm2 status || true
    
    log_success "Сервисы перезапущены"
}

###############################################################################
# Проверка работоспособности
###############################################################################

health_check() {
    log_info "Проверка работоспособности..."
    
    # Проверить backend
    if curl -f -s http://localhost:8001/api/status > /dev/null 2>&1; then
        log_success "✓ Backend работает"
    else
        log_warning "⚠ Backend может не работать"
    fi
    
    # Проверить почтовые сервисы
    if systemctl is-active --quiet postfix 2>/dev/null || service postfix status > /dev/null 2>&1; then
        log_success "✓ Postfix (SMTP) работает"
    else
        log_info "○ Postfix не запущен"
    fi
    
    if systemctl is-active --quiet dovecot 2>/dev/null || service dovecot status > /dev/null 2>&1; then
        log_success "✓ Dovecot (IMAP) работает"
    else
        log_info "○ Dovecot не запущен"
    fi
    
    if pgrep -x opendkim > /dev/null; then
        log_success "✓ OpenDKIM работает"
    else
        log_info "○ OpenDKIM не запущен"
    fi
}

###############################################################################
# Откат к предыдущей версии
###############################################################################

rollback() {
    log_warning "Откат к предыдущей версии..."
    
    cd "$PROJECT_DIR"
    
    # Откатить git
    git reset --hard HEAD@{1}
    
    # Восстановить .env из бэкапа
    cp "$BACKUP_DIR/backend.env.backup" backend/.env 2>/dev/null || true
    cp "$BACKUP_DIR/frontend.env.backup" frontend/.env 2>/dev/null || true
    
    # Перезапустить сервисы
    restart_services force
    
    log_success "Откат выполнен"
}

###############################################################################
# Главная функция
###############################################################################

main() {
    echo "═══════════════════════════════════════════════════════════"
    echo "  🚀 Обновление SunnySiouxCare.com с GitHub"
    echo "═══════════════════════════════════════════════════════════"
    echo
    
    # Проверить что проект существует
    if [ ! -d "$PROJECT_DIR" ]; then
        log_error "Проект не найден в $PROJECT_DIR"
        log_info "Используйте install-from-github.sh для новой установки"
        exit 1
    fi
    
    # Создать бэкап
    create_backup
    
    # Обновить из GitHub
    update_from_github
    
    # Обновить зависимости
    update_dependencies
    
    # Перезапустить сервисы
    restart_services
    
    # Проверить работоспособность
    health_check
    
    echo
    echo "═══════════════════════════════════════════════════════════"
    log_success "✅ Обновление завершено успешно!"
    echo "═══════════════════════════════════════════════════════════"
    echo
    log_info "📋 Что было сделано:"
    echo "  • Создан бэкап в $BACKUP_DIR"
    echo "  • Код обновлен из GitHub"
    echo "  • Зависимости обновлены"
    echo "  • Сервисы перезапущены"
    echo
    log_info "🌐 Ваш сайт: https://sunny-installer.preview.emergentagent.com"
    log_info "📧 Email: info@sunnysiouxcare.com"
    echo
    log_info "📝 Логи:"
    echo "  Backend:  sudo tail -f /var/log/supervisor/backend.out.log"
    echo "  Frontend: sudo tail -f /var/log/supervisor/frontend.out.log"
    echo
    log_info "🔄 Для отката выполните: cd $PROJECT_DIR && git reset --hard HEAD@{1}"
    echo
}

###############################################################################
# Обработка ошибок
###############################################################################

trap 'log_error "Ошибка при обновлении! Для отката используйте последний бэкап в $BACKUP_DIR"' ERR

###############################################################################
# Запуск
###############################################################################

# Проверить что запущено с правами root
if [ "$EUID" -ne 0 ]; then 
    log_error "Пожалуйста, запустите с sudo: sudo bash update-from-github.sh"
    exit 1
fi

main "$@"
