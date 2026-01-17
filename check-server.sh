#!/bin/bash
# =====================================================
# Диагностика состояния файлов на сервере
# =====================================================

echo "🔍 Диагностика Канбан Доски на сервере..."
echo ""

# 1. Проверка текущей версии
echo "📊 Текущий коммит на сервере:"
git log -1 --oneline
echo ""

# 2. Проверка статуса git
echo "📋 Статус git:"
git status --short
echo ""

# 3. Проверка versions в HTML
echo "🔢 Версии файлов в index.html:"
grep "v=" index.html
echo ""

# 4. Проверка дизайна в styles.css
echo "🎨 Проверка дизайна в styles.css:"
echo "Ищу классический фиолетовый градиент (#667eea)..."
if grep -q "#667eea" styles.css; then
    echo "✅ Найден классический дизайн"
else
    echo "❌ Классический дизайн НЕ найден"
fi

echo "Ищу киберпанк дизайн (--neon-cyan)..."
if grep -q "neon-cyan" styles.css; then
    echo "⚠️  Найден киберпанк дизайн (нужно обновить!)"
else
    echo "✅ Киберпанк дизайн отсутствует"
fi
echo ""

# 5. Показать первые 15 строк styles.css
echo "📄 Первые 15 строк styles.css:"
head -15 styles.css
echo ""

# 6. Проверка различий с origin/main
echo "🔄 Различия с GitHub (origin/main):"
git fetch origin
if git diff --quiet origin/main; then
    echo "✅ Сервер синхронизирован с GitHub"
else
    echo "⚠️  Есть различия! Показываю измененные файлы:"
    git diff --name-only origin/main
fi
echo ""

# 7. Рекомендации
echo "💡 Рекомендации:"
echo "   1. Если есть различия с GitHub - запустите: bash force-update.sh"
echo "   2. После обновления очистите кеш браузера: Ctrl+Shift+R"
echo "   3. Если проблема остается - проверьте кеш веб-сервера (Nginx/Apache)"
