# 🚀 Автоматическая установка на сервер

Этот файл содержит инструкции для автоматической установки Канбан Доски на ваш сервер с SSL сертификатами.

## ⚡ Быстрая установка (одна команда)

### Способ 1: Автоматическая установка через curl

```bash
# 1. Подключитесь к серверу
ssh root@93.183.81.133

# 2. Запустите установку одной командой
curl -sSL https://raw.githubusercontent.com/brandgrossmeister8-cmd/4_Kanban/main/install.sh | bash
```

### Способ 2: Ручная загрузка скрипта

```bash
# 1. Подключитесь к серверу
ssh root@93.183.81.133

# 2. Скачайте скрипт
wget https://raw.githubusercontent.com/brandgrossmeister8-cmd/4_Kanban/main/install.sh

# 3. Дайте права на выполнение
chmod +x install.sh

# 4. Запустите
./install.sh
```

## 📋 Что скрипт делает автоматически

1. ✅ Проверяет и устанавливает зависимости (git, nginx, certbot)
2. ✅ Запрашивает параметры установки (домен, email, ключи Supabase)
3. ✅ Создает директорию `/var/www/ваш-домен`
4. ✅ Клонирует репозиторий с GitHub
5. ✅ Настраивает `config.js` с вашими ключами
6. ✅ Создает резервную копию `config.js.production`
7. ✅ Настраивает Nginx для вашего домена
8. ✅ Устанавливает SSL сертификат от Let's Encrypt
9. ✅ Настраивает автообновление SSL (через cron)
10. ✅ Устанавливает правильные права доступа

## 🎯 Параметры, которые нужно подготовить

Перед запуском скрипта подготовьте:

1. **Домен**: `canban.brandgrossmeister.ru`
2. **Email**: ваш email для SSL сертификата
3. **Supabase URL**: `https://rita-supabase.tw1.ru`
4. **Supabase Anon Key**: ваш публичный ключ из Supabase Dashboard → Settings → API

## 📝 Пример установки

```bash
# Подключение к серверу
ssh root@93.183.81.133

# Запуск установки
curl -sSL https://raw.githubusercontent.com/brandgrossmeister8-cmd/4_Kanban/main/install.sh | bash

# Скрипт спросит:
# Введите ваш домен: canban.brandgrossmeister.ru
# Введите email для SSL: your@email.com
# Введите Supabase URL: https://rita-supabase.tw1.ru
# Введите Supabase Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Подтвердите: y

# Скрипт установит всё автоматически!
```

## ✅ После установки

### 1. Выполните SQL миграцию

Откройте Supabase SQL Editor и выполните:

```sql
-- 1. Добавить app_source (если еще не добавлено)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS app_source TEXT DEFAULT 'kanban';

UPDATE profiles
SET app_source = 'kanban'
WHERE app_source IS NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_app_source ON profiles(app_source);

-- 2. Отключить RLS
ALTER TABLE canban_tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
```

### 2. Проверьте работу приложения

Откройте в браузере:
```
https://canban.brandgrossmeister.ru/auth.html
```

### 3. Проверьте SSL сертификат

Сертификат должен быть валидным и выданным Let's Encrypt.

## 🔄 Обновление приложения

После установки вы можете обновлять приложение через GitHub:

```bash
# На вашем компьютере: внесите изменения и запушьте
git add .
git commit -m "Описание изменений"
git push origin main

# На сервере: обновите
ssh root@93.183.81.133
cd /var/www/canban.brandgrossmeister.ru
./deploy.sh
```

## 🛠 Полезные команды

### Проверка статуса

```bash
# Проверить работу Nginx
systemctl status nginx

# Проверить логи приложения
tail -f /var/log/nginx/canban.brandgrossmeister.ru-error.log
tail -f /var/log/nginx/canban.brandgrossmeister.ru-access.log

# Проверить SSL сертификат
certbot certificates
```

### Управление Nginx

```bash
# Перезапустить Nginx
systemctl restart nginx

# Проверить конфигурацию
nginx -t

# Перезагрузить конфигурацию
systemctl reload nginx
```

### Управление SSL

```bash
# Обновить сертификат вручную
certbot renew

# Список сертификатов
certbot certificates

# Тест обновления
certbot renew --dry-run
```

## 🐛 Решение проблем

### Ошибка: "Домен не указывает на сервер"

Проверьте DNS записи:
```bash
dig canban.brandgrossmeister.ru
nslookup canban.brandgrossmeister.ru
```

Домен должен указывать на IP: `93.183.81.133`

### Ошибка установки SSL

Если автоматическая установка SSL не удалась:

```bash
# Установите SSL вручную
certbot --nginx -d canban.brandgrossmeister.ru
```

### Приложение не работает

```bash
# Проверьте логи
tail -100 /var/log/nginx/canban.brandgrossmeister.ru-error.log

# Проверьте config.js
cat /var/www/canban.brandgrossmeister.ru/js/config.js

# Проверьте права
ls -la /var/www/canban.brandgrossmeister.ru/
```

### Восстановление config.js

Если config.js сбросился после обновления:

```bash
cp /var/www/canban.brandgrossmeister.ru/js/config.js.production \
   /var/www/canban.brandgrossmeister.ru/js/config.js
```

## 🔐 Безопасность

### Защита ключей Supabase

- ✅ `config.js` НЕ коммитится в Git (.gitignore)
- ✅ Резервная копия хранится в `config.js.production`
- ✅ При обновлении через `deploy.sh` ключи сохраняются автоматически

### Рекомендации

1. Регулярно обновляйте систему:
```bash
apt-get update && apt-get upgrade -y
```

2. Настройте firewall:
```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

3. Включите fail2ban для защиты от брутфорса:
```bash
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте логи: `/var/log/nginx/`
2. Проверьте консоль браузера (F12)
3. Создайте issue на GitHub

---

**Версия:** 1.0
**Последнее обновление:** 2026-01-10
