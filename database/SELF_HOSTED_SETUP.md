# Установка Supabase на собственном сервере (Self-Hosted)

Это руководство поможет вам установить Supabase на ваш собственный сервер.

## Требования к серверу

### Минимальные требования:
- **ОС**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **RAM**: минимум 4 GB (рекомендуется 8 GB)
- **CPU**: 2 ядра (рекомендуется 4)
- **Диск**: минимум 20 GB свободного места
- **Доступ**: SSH доступ с правами root/sudo

### Необходимое ПО:
- Docker (версия 20.10+)
- Docker Compose (версия 2.0+)
- Git

---

## Вариант 1: Быстрая установка через Docker Compose (Рекомендуется)

### Шаг 1: Подготовка сервера

Подключитесь к серверу по SSH:
```bash
ssh user@your-server.com
```

Обновите систему:
```bash
sudo apt update && sudo apt upgrade -y
```

### Шаг 2: Установка Docker

Установите Docker и Docker Compose:
```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Проверка установки
docker --version
docker-compose --version
```

Перезайдите в SSH для применения изменений группы.

### Шаг 3: Скачивание Supabase

Клонируйте репозиторий Supabase:
```bash
git clone --depth 1 https://github.com/supabase/supabase
cd supabase/docker
```

### Шаг 4: Настройка переменных окружения

Скопируйте пример конфигурации:
```bash
cp .env.example .env
```

Откройте файл `.env` для редактирования:
```bash
nano .env
```

**Обязательно измените следующие параметры:**

```env
############
# Секреты
############

# Генерируйте надёжные пароли! Используйте: openssl rand -base64 32

# JWT секрет (ОЧЕНЬ ВАЖНО!)
JWT_SECRET=ЗАМЕНИТЕ_НА_СЛУЧАЙНУЮ_СТРОКУ_MIN_32_СИМВОЛА

# Пароль PostgreSQL
POSTGRES_PASSWORD=ЗАМЕНИТЕ_НА_СЛОЖНЫЙ_ПАРОЛЬ

# Dashboard пароль (для доступа к админке)
DASHBOARD_PASSWORD=ЗАМЕНИТЕ_НА_СЛОЖНЫЙ_ПАРОЛЬ

############
# База данных
############

POSTGRES_HOST=db
POSTGRES_DB=postgres
POSTGRES_PORT=5432

############
# API
############

# URL вашего сервера (замените на ваш домен!)
API_EXTERNAL_URL=https://your-domain.com

# ANON и SERVICE ключи будут сгенерированы автоматически
# Но можно указать свои через https://supabase.com/docs/guides/self-hosting#api-keys

############
# Studio (Dashboard)
############

# Порт для Dashboard (по умолчанию 3000)
STUDIO_PORT=3000

############
# Email (SMTP)
############

# Настройте SMTP для отправки email подтверждений
SMTP_ADMIN_EMAIL=admin@your-domain.com
SMTP_HOST=smtp.your-provider.com
SMTP_PORT=587
SMTP_USER=your-smtp-user
SMTP_PASS=your-smtp-password
SMTP_SENDER_NAME=Kanban Board
```

**Генерация безопасных секретов:**
```bash
# JWT Secret
openssl rand -base64 32

# ANON Key (опционально, можно оставить автогенерацию)
openssl rand -base64 32

# SERVICE_ROLE Key (опционально)
openssl rand -base64 32
```

Сохраните файл (Ctrl+X, затем Y, затем Enter).

### Шаг 5: Запуск Supabase

Запустите все сервисы:
```bash
docker-compose up -d
```

Проверьте статус:
```bash
docker-compose ps
```

Все сервисы должны быть в состоянии `Up`.

### Шаг 6: Проверка работы

Откройте в браузере:
- **Studio (Dashboard)**: `http://your-server-ip:3000`
- **API**: `http://your-server-ip:8000`

Войдите в Dashboard используя пароль из `DASHBOARD_PASSWORD`.

### Шаг 7: Настройка Nginx (для HTTPS)

Установите Nginx:
```bash
sudo apt install nginx -y
```

Создайте конфигурацию:
```bash
sudo nano /etc/nginx/sites-available/supabase
```

Вставьте:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # API
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Studio (опционально, если нужен доступ к dashboard)
    location /studio/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Активируйте конфигурацию:
```bash
sudo ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Шаг 8: Установка SSL (Let's Encrypt)

Установите Certbot:
```bash
sudo apt install certbot python3-certbot-nginx -y
```

Получите SSL сертификат:
```bash
sudo certbot --nginx -d your-domain.com
```

Certbot автоматически настроит HTTPS редирект.

### Шаг 9: Выполнение SQL скрипта

1. Откройте Dashboard: `https://your-domain.com/studio/`
2. Войдите с паролем из `DASHBOARD_PASSWORD`
3. Перейдите в **SQL Editor**
4. Скопируйте содержимое файла `database/schema.sql`
5. Вставьте и нажмите **Run**

### Шаг 10: Получение API ключей

1. В Dashboard перейдите в **Settings** → **API**
2. Скопируйте:
   - **URL**: `https://your-domain.com`
   - **anon key**: длинный JWT токен

3. Вставьте их в `js/config.js`:
```javascript
const SUPABASE_URL = 'https://your-domain.com';
const SUPABASE_ANON_KEY = 'ваш_anon_key';
```

---

## Вариант 2: Использование готового облачного Supabase

Если установка на сервере слишком сложна, можно использовать облачный Supabase:

1. Зарегистрируйтесь на [supabase.com](https://supabase.com)
2. Создайте проект (бесплатно)
3. Следуйте инструкциям в `database/README.md`

---

## Обслуживание

### Просмотр логов:
```bash
cd ~/supabase/docker
docker-compose logs -f
```

### Остановка сервисов:
```bash
docker-compose down
```

### Обновление Supabase:
```bash
git pull
docker-compose down
docker-compose pull
docker-compose up -d
```

### Резервное копирование базы данных:
```bash
docker exec supabase-db pg_dump -U postgres postgres > backup-$(date +%Y%m%d).sql
```

### Восстановление из резервной копии:
```bash
cat backup-20260106.sql | docker exec -i supabase-db psql -U postgres -d postgres
```

---

## Решение проблем

### Порты заняты

Если порты 3000 или 8000 заняты, измените в `.env`:
```env
STUDIO_PORT=3001
KONG_HTTP_PORT=8001
```

### Недостаточно памяти

Добавьте swap:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Контейнеры не запускаются

Проверьте логи:
```bash
docker-compose logs
```

Пересоздайте контейнеры:
```bash
docker-compose down -v
docker-compose up -d
```

---

## Безопасность

✅ **Обязательно:**
- Смените все пароли по умолчанию
- Используйте HTTPS (SSL сертификат)
- Ограничьте доступ к Dashboard (только для администраторов)
- Настройте файрвол (ufw/iptables)
- Регулярно создавайте резервные копии БД

❌ **Никогда:**
- Не используйте service_role ключ на клиенте
- Не публикуйте пароли в Git
- Не открывайте PostgreSQL порт (5432) наружу

---

## Дополнительные ресурсы

- [Supabase Self-Hosting Docs](https://supabase.com/docs/guides/self-hosting)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Nginx Docs](https://nginx.org/en/docs/)

---

## Поддержка

Если возникли проблемы:
- [Supabase GitHub Issues](https://github.com/supabase/supabase/issues)
- [Supabase Discord](https://discord.supabase.com)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/supabase)
