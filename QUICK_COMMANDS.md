# ⚡ ШПАРГАЛКА - Установка и обновление одной командой

## 🆕 НОВАЯ УСТАНОВКА

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/sunny-sioux-care/main/install-from-github.sh | sudo bash
```

**Замените YOUR-USERNAME на ваш GitHub username!**

---

## 🔄 ОБНОВЛЕНИЕ

```bash
cd /var/www/sunny-sioux-care
sudo bash update-from-github.sh
```

Или:

```bash
ssh root@104.248.57.162 "cd /var/www/sunny-sioux-care && bash update-from-github.sh"
```

---

## 📂 После первой установки загрузите скрипты в GitHub:

```bash
cd /var/www/sunny-sioux-care
git add install-from-github.sh update-from-github.sh INSTALL_UPDATE_SCRIPTS.md
git commit -m "Add universal install/update scripts"
git push origin main
```

---

## 🎯 Что дальше?

1. **После установки** - заполните `.env` файлы
2. **Регулярно обновляйте** - просто запустите `update-from-github.sh`
3. **Автоматизируйте** - создайте cron job для автообновлений

### Пример cron для автообновления (каждую ночь в 3:00):
```bash
0 3 * * * cd /var/www/sunny-sioux-care && bash update-from-github.sh >> /var/log/auto-update.log 2>&1
```

---

**Вот и всё! Просто! 🚀**
