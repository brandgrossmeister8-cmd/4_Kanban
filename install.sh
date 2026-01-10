#!/bin/bash
# =====================================================
# Автоматическая установка Канбан Доски на сервер
# =====================================================
# Использование: curl -sSL https://raw.githubusercontent.com/brandgrossmeister8-cmd/4_Kanban/main/install.sh | bash
# =====================================================

set -e  # Остановка при ошибке

echo "🚀 Начинаю установку Канбан Доски..."
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =====================================================
# 1. ПРОВЕРКА ОКРУЖЕНИЯ
# =====================================================

echo "📋 Проверка системных требований..."

# Проверка что скрипт запущен от root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Этот скрипт должен быть запущен от root${NC}"
    echo "Используйте: sudo bash install.sh"
    exit 1
fi

# Проверка установки git
if ! command -v git &> /dev/null; then
    echo "📦 Git не установлен, устанавливаю..."
    apt-get update -qq
    apt-get install -y git
fi

# Проверка установки nginx
if ! command -v nginx &> /dev/null; then
    echo "📦 Nginx не установлен, устанавливаю..."
    apt-get update -qq
    apt-get install -y nginx
fi

# Проверка установки certbot
if ! command -v certbot &> /dev/null; then
    echo "📦 Certbot не установлен, устанавливаю..."
    apt-get update -qq
    apt-get install -y certbot python3-certbot-nginx
fi

echo -e "${GREEN}✅ Все зависимости установлены${NC}"
echo ""

# =====================================================
# 2. ВВОД ПАРАМЕТРОВ
# =====================================================

echo "📝 Настройка параметров..."
echo ""

# Домен
read -p "Введите ваш домен (например: canban.brandgrossmeister.ru): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Домен не может быть пустым${NC}"
    exit 1
fi

# Email для SSL
read -p "Введите email для SSL сертификата: " EMAIL
if [ -z "$EMAIL" ]; then
    echo -e "${RED}❌ Email не может быть пустым${NC}"
    exit 1
fi

# Supabase URL
read -p "Введите Supabase URL (например: https://rita-supabase.tw1.ru): " SUPABASE_URL
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}❌ Supabase URL не может быть пустым${NC}"
    exit 1
fi

# Supabase Anon Key
read -p "Введите Supabase Anon Key: " SUPABASE_KEY
if [ -z "$SUPABASE_KEY" ]; then
    echo -e "${RED}❌ Supabase Key не может быть пустым${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Параметры установки:${NC}"
echo "Домен: $DOMAIN"
echo "Email: $EMAIL"
echo "Supabase URL: $SUPABASE_URL"
echo ""
read -p "Всё верно? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Установка отменена"
    exit 0
fi

# =====================================================
# 3. СОЗДАНИЕ ДИРЕКТОРИИ И КЛОНИРОВАНИЕ
# =====================================================

WEB_DIR="/var/www/$DOMAIN"

echo "📁 Создаю директорию $WEB_DIR..."

# Создать директорию если не существует
mkdir -p $WEB_DIR

# Перейти в директорию
cd $WEB_DIR

# Клонировать репозиторий
echo "📥 Клонирую репозиторий с GitHub..."
if [ -d ".git" ]; then
    echo "Репозиторий уже существует, обновляю..."
    git pull origin main
else
    git clone https://github.com/brandgrossmeister8-cmd/4_Kanban.git .
fi

# Установить права
chmod +x deploy.sh
echo -e "${GREEN}✅ Репозиторий клонирован${NC}"
echo ""

# =====================================================
# 4. НАСТРОЙКА CONFIG.JS
# =====================================================

echo "⚙️  Настраиваю config.js..."

cat > js/config.js << EOF
// =====================================================
// Конфигурация Supabase для Канбан Доски
// =====================================================
// ⚠️ ВНИМАНИЕ: Этот файл содержит реальные ключи!
// НЕ коммитьте его в Git!
// =====================================================

const SUPABASE_URL = '$SUPABASE_URL';
const SUPABASE_ANON_KEY = '$SUPABASE_KEY';

console.log('✅ Config загружен:', SUPABASE_URL);
EOF

# Создать резервную копию
cp js/config.js js/config.js.production

echo -e "${GREEN}✅ config.js настроен${NC}"
echo ""

# =====================================================
# 5. НАСТРОЙКА NGINX
# =====================================================

echo "🌐 Настраиваю Nginx..."

cat > /etc/nginx/sites-available/$DOMAIN << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    root /var/www/DOMAIN_PLACEHOLDER;
    index index.html;

    # Логи
    access_log /var/log/nginx/DOMAIN_PLACEHOLDER-access.log;
    error_log /var/log/nginx/DOMAIN_PLACEHOLDER-error.log;

    # Основная локация
    location / {
        try_files $uri $uri/ =404;
    }

    # Кеширование статики
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Запрет доступа к скрытым файлам
    location ~ /\. {
        deny all;
    }

    # Запрет доступа к .git
    location ~ /\.git {
        deny all;
    }
}
EOF

# Заменить плейсхолдеры на реальный домен
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/sites-available/$DOMAIN

# Создать симлинк
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# Удалить default конфиг если существует
rm -f /etc/nginx/sites-enabled/default

# Проверить конфигурацию
nginx -t

# Перезапустить nginx
systemctl restart nginx

echo -e "${GREEN}✅ Nginx настроен${NC}"
echo ""

# =====================================================
# 6. УСТАНОВКА SSL СЕРТИФИКАТА
# =====================================================

echo "🔐 Устанавливаю SSL сертификат..."

# Получить SSL сертификат
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL сертификат установлен${NC}"
else
    echo -e "${YELLOW}⚠️  Не удалось установить SSL автоматически${NC}"
    echo "Попробуйте позже вручную: certbot --nginx -d $DOMAIN"
fi

echo ""

# =====================================================
# 7. НАСТРОЙКА ПРАВ
# =====================================================

echo "🔑 Настраиваю права доступа..."

chown -R www-data:www-data $WEB_DIR
chmod -R 755 $WEB_DIR

echo -e "${GREEN}✅ Права настроены${NC}"
echo ""

# =====================================================
# 8. АВТООБНОВЛЕНИЕ SSL
# =====================================================

echo "⏰ Настраиваю автообновление SSL..."

# Добавить задачу в cron для автообновления SSL
(crontab -l 2>/dev/null | grep -v certbot; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -

echo -e "${GREEN}✅ Автообновление SSL настроено${NC}"
echo ""

# =====================================================
# 9. ЗАВЕРШЕНИЕ
# =====================================================

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 Установка завершена успешно!${NC}"
echo "=========================================="
echo ""
echo "📌 Ваше приложение доступно по адресу:"
echo -e "${GREEN}https://$DOMAIN/auth.html${NC}"
echo ""
echo "📝 Что нужно сделать дальше:"
echo ""
echo "1. Выполните SQL миграцию в Supabase SQL Editor:"
echo "   - Откройте: $SUPABASE_URL"
echo "   - SQL Editor → Выполните database/add_app_source.sql"
echo ""
echo "2. Отключите RLS для таблиц:"
echo "   ALTER TABLE canban_tasks DISABLE ROW LEVEL SECURITY;"
echo "   ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;"
echo ""
echo "3. Откройте сайт и проверьте работу:"
echo "   https://$DOMAIN/auth.html"
echo ""
echo "📋 Полезные команды:"
echo "   - Обновить приложение: cd $WEB_DIR && ./deploy.sh"
echo "   - Проверить логи nginx: tail -f /var/log/nginx/$DOMAIN-error.log"
echo "   - Перезапустить nginx: systemctl restart nginx"
echo ""
echo "=========================================="
