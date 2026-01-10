#!/bin/bash
# =====================================================
# Скрипт автоматического обновления Канбан Доски
# =====================================================

echo "🚀 Начинаю обновление Канбан Доски..."

# 1. Проверка что мы в правильной директории
if [ ! -f "index.html" ]; then
    echo "❌ Ошибка: index.html не найден. Убедитесь, что вы в корневой директории проекта."
    exit 1
fi

# 2. Проверка наличия git
if ! command -v git &> /dev/null; then
    echo "❌ Ошибка: git не установлен"
    exit 1
fi

# 3. Сохранить текущую ветку
CURRENT_BRANCH=$(git branch --show-current)
echo "📌 Текущая ветка: $CURRENT_BRANCH"

# 4. Получить изменения с GitHub
echo "📥 Загружаю изменения из GitHub..."
git fetch origin

# 5. Показать что изменилось
echo ""
echo "📋 Изменения, которые будут применены:"
git log HEAD..origin/$CURRENT_BRANCH --oneline --decorate

# 6. Подтверждение обновления
read -p "Продолжить обновление? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Обновление отменено"
    exit 0
fi

# 7. Создать резервную копию config.js (если есть реальные ключи)
if [ -f "js/config.js" ]; then
    echo "💾 Создаю резервную копию config.js..."
    cp js/config.js js/config.js.backup
fi

# 8. Выполнить git pull
echo "⬇️  Применяю обновления..."
git pull origin $CURRENT_BRANCH

# 9. Проверка результата
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Обновление выполнено успешно!"

    # 10. Восстановить config.js если он был изменен
    if [ -f "js/config.js.backup" ]; then
        echo "🔍 Проверяю config.js..."
        if ! grep -q "your-project-url.supabase.co" js/config.js; then
            echo "ℹ️  config.js содержит реальные ключи и не был изменен"
            rm js/config.js.backup
        else
            echo "⚠️  config.js был обновлен до шаблона, восстанавливаю ваши ключи..."
            mv js/config.js.backup js/config.js
            echo "✅ Ваши ключи восстановлены"
        fi
    fi

    echo ""
    echo "📝 Что дальше:"
    echo "   1. Проверьте js/config.js - убедитесь что там ваши ключи Supabase"
    echo "   2. Откройте сайт в браузере и проверьте работу"
    echo "   3. Если нужно, очистите кеш браузера (Cmd+Shift+R)"
    echo ""
    echo "📊 Версия после обновления:"
    git log -1 --oneline
else
    echo "❌ Ошибка при обновлении!"
    echo "Восстанавливаю config.js из резервной копии..."
    if [ -f "js/config.js.backup" ]; then
        mv js/config.js.backup js/config.js
    fi
    exit 1
fi
