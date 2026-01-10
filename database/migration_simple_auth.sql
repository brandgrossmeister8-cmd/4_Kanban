-- =====================================================
-- Миграция: переход на простую систему входа по имени
-- =====================================================
-- Этот скрипт удаляет зависимость от Supabase Auth
-- и создаёт простую систему входа по имени пользователя
-- =====================================================

-- ================
-- 1. УДАЛЕНИЕ СТАРЫХ ТАБЛИЦ И ТРИГГЕРОВ
-- ================

-- Удалить старые триггеры
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON canban_tasks;

-- Удалить функцию создания профиля
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Удалить старые таблицы
DROP TABLE IF EXISTS canban_tasks CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ================
-- 2. НОВАЯ ТАБЛИЦА ПРОФИЛЕЙ
-- ================

CREATE TABLE IF NOT EXISTS profiles (
  id BIGSERIAL PRIMARY KEY,
  full_name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Комментарии к таблице
COMMENT ON TABLE profiles IS 'Профили пользователей (простая система по имени)';
COMMENT ON COLUMN profiles.id IS 'Уникальный идентификатор пользователя';
COMMENT ON COLUMN profiles.full_name IS 'Полное имя пользователя (уникальное)';

-- ================
-- 3. НОВАЯ ТАБЛИЦА ЗАДАЧ
-- ================

CREATE TABLE IF NOT EXISTS canban_tasks (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT CHECK (category IN ('bug', 'feature', 'improvement', 'documentation', 'testing', 'other')),
  creator_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  assignee_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  deadline TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('todo', 'in-progress', 'done')) DEFAULT 'todo',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Комментарии к таблице
COMMENT ON TABLE canban_tasks IS 'Задачи канбан доски';
COMMENT ON COLUMN canban_tasks.id IS 'Уникальный идентификатор задачи';
COMMENT ON COLUMN canban_tasks.title IS 'Название задачи (обязательное)';
COMMENT ON COLUMN canban_tasks.description IS 'Описание задачи (опционально)';
COMMENT ON COLUMN canban_tasks.category IS 'Категория задачи';
COMMENT ON COLUMN canban_tasks.creator_id IS 'ID постановщика задачи';
COMMENT ON COLUMN canban_tasks.assignee_id IS 'ID исполнителя задачи';
COMMENT ON COLUMN canban_tasks.deadline IS 'Срок выполнения задачи';
COMMENT ON COLUMN canban_tasks.status IS 'Статус задачи (todo, in-progress, done)';

-- ================
-- 4. ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ
-- ================

-- Индекс для быстрого поиска по имени пользователя
CREATE INDEX IF NOT EXISTS idx_profiles_full_name ON profiles(full_name);

-- Индекс для быстрого поиска задач по исполнителю
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON canban_tasks(assignee_id);

-- Индекс для быстрого поиска задач по создателю
CREATE INDEX IF NOT EXISTS idx_tasks_creator ON canban_tasks(creator_id);

-- Индекс для быстрого поиска задач по статусу
CREATE INDEX IF NOT EXISTS idx_tasks_status ON canban_tasks(status);

-- Индекс для быстрого поиска задач по дедлайну
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON canban_tasks(deadline);

-- Композитный индекс для частых запросов (assignee + status)
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_status ON canban_tasks(assignee_id, status);

-- ================
-- 5. ТРИГГЕР ДЛЯ АВТОМАТИЧЕСКОГО ОБНОВЛЕНИЯ updated_at
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
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Триггер для таблицы canban_tasks
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON canban_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================
-- 6. ОТКЛЮЧЕНИЕ RLS (для простоты MVP)
-- ================

-- Отключить RLS для обеих таблиц
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE canban_tasks DISABLE ROW LEVEL SECURITY;

-- Удалить все политики RLS (если остались)
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view tasks where they are assignee" ON canban_tasks;
DROP POLICY IF EXISTS "Users can create tasks" ON canban_tasks;
DROP POLICY IF EXISTS "Users can update their tasks" ON canban_tasks;
DROP POLICY IF EXISTS "Users can delete tasks they created" ON canban_tasks;

-- ================
-- 7. ТЕСТОВЫЕ ДАННЫЕ (опционально)
-- ================

-- Вставить тестового пользователя
INSERT INTO profiles (full_name)
VALUES ('Маргарита Осмаева')
ON CONFLICT (full_name) DO NOTHING;

-- ================
-- 8. ЗАВЕРШЕНИЕ
-- ================

DO $$
BEGIN
  RAISE NOTICE 'Миграция завершена успешно!';
  RAISE NOTICE 'Таблицы: profiles (BIGSERIAL id), canban_tasks';
  RAISE NOTICE 'Индексы: создано 7 индексов';
  RAISE NOTICE 'Триггеры: автоматическое обновление updated_at';
  RAISE NOTICE 'RLS: отключен для упрощения MVP';
  RAISE NOTICE 'Система: простой вход по имени пользователя';
END $$;

-- =====================================================
-- ИНСТРУКЦИИ ПО ИСПОЛЬЗОВАНИЮ
-- =====================================================

-- 1. Скопируйте весь этот скрипт
-- 2. Откройте Supabase Dashboard -> SQL Editor
-- 3. Вставьте скрипт и нажмите "Run"
-- 4. Проверьте логи на наличие ошибок
-- 5. Готово! Теперь можно использовать простую систему входа

-- =====================================================
