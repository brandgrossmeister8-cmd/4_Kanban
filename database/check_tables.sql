-- =====================================================
-- Проверка существующих таблиц в базе данных
-- =====================================================

-- 1. Список всех таблиц в схеме public
SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Структура таблицы canban_tasks (если существует)
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'canban_tasks'
ORDER BY ordinal_position;

-- 3. Структура таблицы canban_user_tasks (если существует)
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'canban_user_tasks'
ORDER BY ordinal_position;

-- 4. Проверка внешних ключей для canban_user_tasks
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'canban_user_tasks';

-- 5. Подсчет записей в таблицах
SELECT 'profiles' as table_name, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'canban_tasks', COUNT(*) FROM canban_tasks
UNION ALL
SELECT 'canban_user_tasks', COALESCE((SELECT COUNT(*) FROM canban_user_tasks), 0);
