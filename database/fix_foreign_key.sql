-- =====================================================
-- Удалить внешний ключ на auth.users
-- =====================================================

-- Удалить constraint, который связывает profiles.id с auth.users.id
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- Также убедимся, что id - это обычная колонка, а не ссылка на auth
-- Проверить, какой тип у id
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles';

-- Готово!
SELECT 'Foreign key constraint удален' as status;
