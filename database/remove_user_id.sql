-- =====================================================
-- Удалить колонку user_id из canban_tasks
-- =====================================================

-- Удалить колонку user_id, так как используем creator_id и assignee_id
ALTER TABLE canban_tasks DROP COLUMN IF EXISTS user_id;

-- Готово!
SELECT 'Колонка user_id удалена' as status;
