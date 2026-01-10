-- =====================================================
-- Канбан Доска - SQL Schema для Supabase (PostgreSQL)
-- =====================================================
-- Выполните этот скрипт в Supabase SQL Editor
-- Порядок выполнения важен!
-- =====================================================

-- ================
-- 1. ТАБЛИЦА ПРОФИЛЕЙ ПОЛЬЗОВАТЕЛЕЙ
-- ================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Комментарии к таблице
COMMENT ON TABLE profiles IS 'Профили пользователей, расширяют auth.users';
COMMENT ON COLUMN profiles.id IS 'UUID пользователя из auth.users';
COMMENT ON COLUMN profiles.email IS 'Email пользователя';
COMMENT ON COLUMN profiles.full_name IS 'Полное имя пользователя';

-- ================
-- 2. ТАБЛИЦА ЗАДАЧ
-- ================

CREATE TABLE IF NOT EXISTS tasks (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT CHECK (category IN ('bug', 'feature', 'improvement', 'documentation', 'testing', 'other')),
  creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  assignee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  deadline TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('todo', 'in-progress', 'done')) DEFAULT 'todo',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Комментарии к таблице
COMMENT ON TABLE tasks IS 'Задачи канбан доски';
COMMENT ON COLUMN tasks.id IS 'Уникальный идентификатор задачи';
COMMENT ON COLUMN tasks.title IS 'Название задачи (обязательное)';
COMMENT ON COLUMN tasks.description IS 'Описание задачи (опционально)';
COMMENT ON COLUMN tasks.category IS 'Категория задачи';
COMMENT ON COLUMN tasks.creator_id IS 'ID постановщика задачи';
COMMENT ON COLUMN tasks.assignee_id IS 'ID исполнителя задачи';
COMMENT ON COLUMN tasks.deadline IS 'Срок выполнения задачи';
COMMENT ON COLUMN tasks.status IS 'Статус задачи (todo, in-progress, done)';

-- ================
-- 3. ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ
-- ================

-- Индекс для быстрого поиска задач по исполнителю
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON tasks(assignee_id);

-- Индекс для быстрого поиска задач по создателю
CREATE INDEX IF NOT EXISTS idx_tasks_creator ON tasks(creator_id);

-- Индекс для быстрого поиска задач по статусу
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);

-- Индекс для быстрого поиска задач по дедлайну
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline);

-- Композитный индекс для частых запросов (assignee + status)
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_status ON tasks(assignee_id, status);

-- ================
-- 4. ТРИГГЕР ДЛЯ АВТОМАТИЧЕСКОГО ОБНОВЛЕНИЯ updated_at
-- ================

-- Функция для обновления поля updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для таблицы profiles
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Триггер для таблицы tasks
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================
-- 5. ТРИГГЕР ДЛЯ АВТОМАТИЧЕСКОГО СОЗДАНИЯ ПРОФИЛЯ
-- ================

-- Функция для создания профиля при регистрации нового пользователя
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', 'Пользователь')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Триггер на создание нового пользователя в auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ================
-- 6. ROW LEVEL SECURITY (RLS)
-- ================

-- Включить RLS для таблицы profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Включить RLS для таблицы tasks
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- ================
-- 7. ПОЛИТИКИ RLS ДЛЯ ТАБЛИЦЫ PROFILES
-- ================

-- Политика: все аутентифицированные пользователи могут видеть все профили
-- (необходимо для выбора постановщика/исполнителя)
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- Политика: пользователи могут обновлять только свой профиль
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Политика: пользователи могут вставлять свой профиль
-- (на случай ручного создания, хотя обычно создается через триггер)
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- ================
-- 8. ПОЛИТИКИ RLS ДЛЯ ТАБЛИЦЫ TASKS
-- ================

-- Политика: пользователи видят только задачи, где они исполнители
DROP POLICY IF EXISTS "Users can view tasks where they are assignee" ON tasks;
CREATE POLICY "Users can view tasks where they are assignee"
ON tasks FOR SELECT
TO authenticated
USING (assignee_id = auth.uid());

-- Политика: пользователи могут создавать задачи
-- (creator_id должен совпадать с текущим пользователем)
DROP POLICY IF EXISTS "Users can create tasks" ON tasks;
CREATE POLICY "Users can create tasks"
ON tasks FOR INSERT
TO authenticated
WITH CHECK (creator_id = auth.uid());

-- Политика: пользователи могут обновлять задачи, где они создатель или исполнитель
DROP POLICY IF EXISTS "Users can update their tasks" ON tasks;
CREATE POLICY "Users can update their tasks"
ON tasks FOR UPDATE
TO authenticated
USING (creator_id = auth.uid() OR assignee_id = auth.uid())
WITH CHECK (creator_id = auth.uid() OR assignee_id = auth.uid());

-- Политика: пользователи могут удалять задачи, где они создатель
DROP POLICY IF EXISTS "Users can delete tasks they created" ON tasks;
CREATE POLICY "Users can delete tasks they created"
ON tasks FOR DELETE
TO authenticated
USING (creator_id = auth.uid());

-- ================
-- 9. ЗАВЕРШЕНИЕ
-- ================

-- Вывод сообщения об успешном создании схемы
DO $$
BEGIN
  RAISE NOTICE 'Схема базы данных успешно создана!';
  RAISE NOTICE 'Таблицы: profiles, tasks';
  RAISE NOTICE 'Индексы: создано 5 индексов';
  RAISE NOTICE 'Триггеры: автоматическое создание профилей и обновление updated_at';
  RAISE NOTICE 'RLS: включен для всех таблиц с соответствующими политиками';
END $$;

-- =====================================================
-- ДОПОЛНИТЕЛЬНЫЕ ПОЛЕЗНЫЕ ЗАПРОСЫ
-- =====================================================

-- Проверить количество пользователей
-- SELECT COUNT(*) as total_users FROM profiles;

-- Проверить количество задач
-- SELECT COUNT(*) as total_tasks FROM tasks;

-- Проверить задачи конкретного пользователя
-- SELECT * FROM tasks WHERE assignee_id = auth.uid();

-- Проверить все политики RLS
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public';

-- =====================================================
-- ИНСТРУКЦИИ ПО ИСПОЛЬЗОВАНИЮ
-- =====================================================

-- 1. Скопируйте весь этот скрипт
-- 2. Откройте Supabase Dashboard -> SQL Editor
-- 3. Вставьте скрипт и нажмите "Run"
-- 4. Проверьте логи на наличие ошибок
-- 5. Готово! Теперь можно настраивать аутентификацию

-- =====================================================
-- НАСТРОЙКА АУТЕНТИФИКАЦИИ В SUPABASE
-- =====================================================

-- После выполнения скрипта:
-- 1. Перейдите в Authentication -> Settings
-- 2. Включите Email Provider
-- 3. Отключите "Confirm email" для разработки (или настройте SMTP)
-- 4. Установите Site URL (URL вашего приложения)
-- 5. Добавьте Redirect URLs если нужно

-- =====================================================
