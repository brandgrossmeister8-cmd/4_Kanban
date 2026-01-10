-- =====================================================
-- Диагностика базы данных Канбан Доски
-- =====================================================

-- 1. Проверка RLS для всех таблиц
SELECT
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename IN ('profiles', 'canban_tasks');

-- 2. Проверка политик RLS
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename IN ('profiles', 'canban_tasks');

-- 3. Подсчет записей в таблицах
SELECT 'profiles' as table_name, COUNT(*) as records FROM profiles
UNION ALL
SELECT 'canban_tasks' as table_name, COUNT(*) as records FROM canban_tasks;

-- 4. Список всех задач
SELECT
    id,
    title,
    status,
    creator_id,
    assignee_id,
    created_at
FROM canban_tasks
ORDER BY created_at DESC;

-- 5. Список всех пользователей
SELECT
    id,
    full_name,
    created_at
FROM profiles
ORDER BY full_name;

-- 6. Проверка структуры таблицы canban_tasks
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'canban_tasks'
ORDER BY ordinal_position;

-- =====================================================
-- Если RLS включен для canban_tasks - отключаем
-- =====================================================
ALTER TABLE canban_tasks DISABLE ROW LEVEL SECURITY;

-- Проверяем что RLS отключен
SELECT
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename = 'canban_tasks';
