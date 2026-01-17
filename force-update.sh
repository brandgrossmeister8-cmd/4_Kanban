#!/bin/bash
# =====================================================
# Принудительное обновление до последней версии GitHub
# =====================================================

echo "🔄 Принудительное обновление Канбан Доски..."

# 1. Проверка что мы в правильной директории
if [ ! -f "index.html" ]; then
    echo "❌ Ошибка: index.html не найден"
    exit 1
fi

# 2. Показать текущую версию
echo "📊 Текущая версия на сервере:"
git log -1 --oneline

# 3. Сохранить config.js (с реальными ключами)
if [ -f "js/config.js" ]; then
    echo "💾 Сохраняю config.js..."
    cp js/config.js /tmp/kanban_config_backup.js
fi

# 4. Сбросить все локальные изменения и обновить
echo "⬇️  Загружаю последнюю версию с GitHub..."
git fetch origin
git reset --hard origin/main

# 5. Восстановить config.js
if [ -f "/tmp/kanban_config_backup.js" ]; then
    echo "🔧 Восстанавливаю config.js..."
    cp /tmp/kanban_config_backup.js js/config.js
    rm /tmp/kanban_config_backup.js
fi

# 6. Показать новую версию
echo ""
echo "✅ Обновление завершено!"
echo "📊 Новая версия:"
git log -1 --oneline

# 7. Проверить версии в HTML файлах
echo ""
echo "🔍 Проверка версий файлов:"
grep "v=" index.html | head -5

echo ""
echo "📝 Важно:"
echo "   1. Очистите кеш браузера (Ctrl+Shift+R или Cmd+Shift+R)"
echo "   2. Если используете Nginx/Apache - очистите кеш сервера"
echo "   3. Проверьте styles.css - должен быть классический дизайн"
