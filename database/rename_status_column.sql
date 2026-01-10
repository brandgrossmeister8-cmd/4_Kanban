-- =====================================================
-- Переименование колонки status -> task_status
-- =====================================================
-- Причина: status - зарезервированное слово в REST API
-- =====================================================

-- 1. Переименовать колонку
ALTER TABLE canban_tasks
RENAME COLUMN status TO task_status;

-- 2. Проверка структуры таблицы
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'canban_tasks'
    AND column_name = 'task_status';

-- 3. Проверить что данные сохранились
SELECT id, title, task_status, created_at
FROM canban_tasks
ORDER BY created_at DESC
LIMIT 5;

-- =====================================================
-- ГОТОВО! Теперь обновите код приложения
-- =====================================================
