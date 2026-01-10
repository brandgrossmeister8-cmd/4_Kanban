-- =====================================================
-- Сделать поле email необязательным
-- =====================================================

-- Убрать ограничение NOT NULL для колонки email
ALTER TABLE profiles ALTER COLUMN email DROP NOT NULL;

-- Также отключаем RLS для упрощения работы
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Готово!
SELECT 'Email теперь необязательное поле, RLS отключен' as status;
