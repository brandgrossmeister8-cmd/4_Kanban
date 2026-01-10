-- =====================================================
-- Добавление поля app_source для разделения пользователей по каналам
-- =====================================================

-- 1. Добавить колонку app_source в таблицу profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS app_source TEXT DEFAULT 'kanban';

-- 2. Обновить существующих пользователей - пометить их как канбан-пользователей
UPDATE profiles
SET app_source = 'kanban'
WHERE app_source IS NULL;

-- 3. Создать индекс для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_profiles_app_source ON profiles(app_source);

-- 4. Проверка - показать всех пользователей с их источниками
SELECT id, full_name, app_source, created_at
FROM profiles
ORDER BY created_at DESC;

-- 5. Подсчет пользователей по источникам
SELECT
    app_source,
    COUNT(*) as count
FROM profiles
GROUP BY app_source;
