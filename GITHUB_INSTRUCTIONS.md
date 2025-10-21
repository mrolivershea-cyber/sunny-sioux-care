# 🚀 Инструкция по загрузке на GitHub

## Шаг 1: Создайте новый репозиторий на GitHub

1. Зайдите на https://github.com
2. Нажмите "New repository" (зелёная кнопка)
3. Заполните:
   - **Repository name:** `sunny-sioux-care`
   - **Description:** `Professional childcare center website with PayPal integration`
   - **Visibility:** Private (рекомендуется) или Public
   - **НЕ** ставьте галочки "Add README" или "Add .gitignore" - они уже есть!
4. Нажмите "Create repository"

## Шаг 2: Получите URL репозитория

После создания GitHub покажет URL вашего репозитория:
```
https://github.com/YOUR_USERNAME/sunny-sioux-care.git
```

Скопируйте этот URL!

## Шаг 3: Подключите локальный проект к GitHub

Выполните в терминале на вашей машине разработки:

```bash
cd /app

# Добавьте remote origin (замените YOUR_USERNAME на ваш GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/sunny-sioux-care.git

# Проверьте remote
git remote -v

# Создайте и переключитесь на main branch (если нужно)
git branch -M main

# Загрузите на GitHub
git push -u origin main
```

**Примечание:** GitHub может попросить авторизацию. Используйте:
- Personal Access Token (рекомендуется)
- SSH ключ
- GitHub CLI

## Шаг 4: Создание Personal Access Token (если нужно)

Если GitHub просит авторизацию:

1. Зайдите на https://github.com/settings/tokens
2. Нажмите "Generate new token" → "Generate new token (classic)"
3. Дайте название: "Sunny Sioux Care Deploy"
4. Выберите scopes:
   - [x] repo (full control)
5. Нажмите "Generate token"
6. **СКОПИРУЙТЕ токен** (он больше не отобразится!)

При `git push` используйте:
- Username: ваш GitHub username
- Password: скопированный токен

## Шаг 5: Проверьте загрузку

1. Откройте https://github.com/YOUR_USERNAME/sunny-sioux-care
2. Должны увидеть все файлы проекта
3. README.md должен красиво отображаться на главной странице

## 📁 Что будет загружено

✅ Загружается:
- Frontend код (React app)
- Backend код (FastAPI)
- Документация (README, DEPLOYMENT_GUIDE, etc.)
- Конфигурационные файлы (package.json, requirements.txt)
- .env.example файлы (шаблоны)

❌ НЕ загружается (в .gitignore):
- node_modules/
- venv/
- .env файлы (с секретами!)
- build/
- logs/
- Временные файлы

## 🔐 Важно о безопасности

**НИКОГДА не коммитьте файлы с секретами:**
- ❌ `.env` с настоящими паролями
- ❌ PayPal Client Secret
- ❌ Email пароли
- ❌ API ключи

Всё это уже в `.gitignore`!

## 🌿 Работа с ветками (опционально)

Для разработки новых функций создавайте ветки:

```bash
# Создать новую ветку для функции
git checkout -b feature/new-payment-method

# Работайте, коммитьте изменения
git add .
git commit -m "Add new payment method"

# Загрузите ветку на GitHub
git push origin feature/new-payment-method

# На GitHub создайте Pull Request для ревью
```

## 📝 Типичные команды Git

```bash
# Проверить статус
git status

# Добавить изменения
git add .

# Сделать коммит
git commit -m "Описание изменений"

# Загрузить на GitHub
git push

# Скачать изменения
git pull

# Посмотреть историю
git log --oneline

# Посмотреть изменения
git diff

# Отменить изменения (до commit)
git restore filename
```

## 🔄 Обновление репозитория

После изменений в коде:

```bash
cd /app

# Добавить все изменения
git add .

# Сделать коммит с описанием
git commit -m "Update: описание того что изменили"

# Загрузить на GitHub
git push
```

## 🏷️ Создание релизов

Для версионирования:

```bash
# Создать тег версии
git tag -a v1.0.0 -m "Version 1.0.0 - Initial release"

# Загрузить тег на GitHub
git push origin v1.0.0
```

## 📦 Клонирование на сервер

Когда будете разворачивать на production сервере:

```bash
# На сервере
cd /var/www/
git clone https://github.com/YOUR_USERNAME/sunny-sioux-care.git
cd sunny-sioux-care

# Создать .env файлы из примеров
cp frontend/.env.example frontend/.env
cp backend/.env.example backend/.env

# Отредактировать с реальными значениями
nano frontend/.env
nano backend/.env

# Установить и запустить (см. DEPLOYMENT_GUIDE.md)
```

## 🆘 Решение проблем

### "Permission denied (publickey)"
Настройте SSH ключ:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Добавьте ключ на GitHub: Settings → SSH and GPG keys
```

### "Authentication failed"
Используйте Personal Access Token вместо пароля.

### "Remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/sunny-sioux-care.git
```

### Случайно закоммитили .env с секретами
```bash
# Удалить файл из Git (но оставить локально)
git rm --cached backend/.env
git commit -m "Remove .env from tracking"
git push

# Немедленно смените все пароли/ключи!
```

## ✅ Готово!

Ваш проект Sunny Sioux Care теперь на GitHub! 🎉

**Следующие шаги:**
1. Защитите main ветку (Settings → Branches → Branch protection rules)
2. Добавьте коллабораторов если нужно (Settings → Collaborators)
3. Настройте GitHub Actions для CI/CD (опционально)
4. Разверните на production сервер следуя DEPLOYMENT_GUIDE.md

---

**Ссылка на ваш репозиторий:**
https://github.com/YOUR_USERNAME/sunny-sioux-care

(Замените YOUR_USERNAME на ваш GitHub username)
