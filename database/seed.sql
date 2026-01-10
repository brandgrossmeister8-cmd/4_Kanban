-- =====================================================
-- Тестовые данные для Канбан Доски
-- =====================================================
-- ВНИМАНИЕ: Этот файл только для разработки!
-- НЕ выполняйте на продакшене!
-- =====================================================

-- Этот файл содержит примеры INSERT запросов
-- Реальные пользователи создаются через Supabase Auth
-- Этот скрипт показывает структуру данных для тестирования

-- =====================================================
-- ПРИМЕЧАНИЕ:
-- =====================================================
-- Для создания тестовых пользователей:
-- 1. Используйте форму регистрации в приложении
-- 2. Или создайте через Supabase Dashboard -> Authentication -> Users
-- 3. Профили создадутся автоматически через триггер
-- =====================================================

-- =====================================================
-- ПРИМЕР: Вставка тестовых задач
-- =====================================================
-- Замените UUID на реальные ID пользователей из вашей БД

-- Получить UUID текущего пользователя:
-- SELECT auth.uid();

-- Получить список всех пользователей:
-- SELECT id, email, full_name FROM profiles;

-- =====================================================
-- Шаблон для создания задачи:
-- =====================================================

/*
INSERT INTO tasks (
  title,
  description,
  category,
  creator_id,
  assignee_id,
  deadline,
  status
) VALUES (
  'Название задачи',
  'Описание задачи',
  'feature', -- bug, feature, improvement, documentation, testing, other
  'UUID_СОЗДАТЕЛЯ', -- Замените на реальный UUID
  'UUID_ИСПОЛНИТЕЛЯ', -- Замените на реальный UUID
  '2026-02-01 12:00:00+00', -- Дата дедлайна (необязательно)
  'todo' -- todo, in-progress, done
);
*/

-- =====================================================
-- ПРИМЕРЫ задач (закомментированы)
-- =====================================================
-- Раскомментируйте и замените UUID после создания пользователей

/*
-- Задача 1: Ошибка в авторизации
INSERT INTO tasks (title, description, category, creator_id, assignee_id, deadline, status)
VALUES (
  'Исправить ошибку входа',
  'Пользователи не могут войти через email',
  'bug',
  'ЗАМЕНИТЕ_НА_UUID_СОЗДАТЕЛЯ',
  'ЗАМЕНИТЕ_НА_UUID_ИСПОЛНИТЕЛЯ',
  NOW() + INTERVAL '3 days',
  'todo'
);

-- Задача 2: Новая функция
INSERT INTO tasks (title, description, category, creator_id, assignee_id, status)
VALUES (
  'Добавить экспорт в Excel',
  'Реализовать экспорт задач в формат Excel',
  'feature',
  'ЗАМЕНИТЕ_НА_UUID_СОЗДАТЕЛЯ',
  'ЗАМЕНИТЕ_НА_UUID_ИСПОЛНИТЕЛЯ',
  'in-progress'
);

-- Задача 3: Улучшение
INSERT INTO tasks (title, description, category, creator_id, assignee_id, status)
VALUES (
  'Оптимизировать загрузку задач',
  'Ускорить загрузку при большом количестве задач',
  'improvement',
  'ЗАМЕНИТЕ_НА_UUID_СОЗДАТЕЛЯ',
  'ЗАМЕНИТЕ_НА_UUID_ИСПОЛНИТЕЛЯ',
  'done'
);

-- Задача 4: Документация
INSERT INTO tasks (title, description, category, creator_id, assignee_id, deadline, status)
VALUES (
  'Написать руководство пользователя',
  'Создать пошаговое руководство для новых пользователей',
  'documentation',
  'ЗАМЕНИТЕ_НА_UUID_СОЗДАТЕЛЯ',
  'ЗАМЕНИТЕ_НА_UUID_ИСПОЛНИТЕЛЯ',
  NOW() + INTERVAL '1 week',
  'todo'
);

-- Задача 5: Тестирование
INSERT INTO tasks (title, description, category, creator_id, assignee_id, status)
VALUES (
  'Протестировать фильтры',
  'Проверить работу всех фильтров в разных комбинациях',
  'testing',
  'ЗАМЕНИТЕ_НА_UUID_СОЗДАТЕЛЯ',
  'ЗАМЕНИТЕ_НА_UUID_ИСПОЛНИТЕЛЯ',
  'in-progress'
);
*/

-- =====================================================
-- ПОЛЕЗНЫЕ ЗАПРОСЫ ДЛЯ ТЕСТИРОВАНИЯ
-- =====================================================

-- Удалить все задачи (для очистки)
-- DELETE FROM tasks;

-- Посчитать задачи по статусам
-- SELECT status, COUNT(*) as count
-- FROM tasks
-- GROUP BY status;

-- Посчитать задачи по категориям
-- SELECT category, COUNT(*) as count
-- FROM tasks
-- WHERE category IS NOT NULL
-- GROUP BY category;

-- Найти просроченные задачи
-- SELECT id, title, deadline, assignee_id
-- FROM tasks
-- WHERE deadline < NOW() AND status != 'done';

-- Задачи конкретного пользователя
-- SELECT t.id, t.title, t.status, t.deadline,
--        c.full_name as creator_name,
--        a.full_name as assignee_name
-- FROM tasks t
-- JOIN profiles c ON t.creator_id = c.id
-- JOIN profiles a ON t.assignee_id = a.id
-- WHERE t.assignee_id = auth.uid();

-- =====================================================
-- БЫСТРОЕ СОЗДАНИЕ ТЕСТОВЫХ ДАННЫХ
-- =====================================================

-- Функция для быстрого создания тестовой задачи
-- (после регистрации хотя бы двух пользователей)

/*
CREATE OR REPLACE FUNCTION create_test_task(
  task_title TEXT,
  task_category TEXT DEFAULT 'other',
  task_status TEXT DEFAULT 'todo'
)
RETURNS void AS $$
DECLARE
  first_user_id UUID;
  second_user_id UUID;
BEGIN
  -- Получить первых двух пользователей
  SELECT id INTO first_user_id FROM profiles ORDER BY created_at LIMIT 1;
  SELECT id INTO second_user_id FROM profiles ORDER BY created_at LIMIT 1 OFFSET 1;

  -- Если второго пользователя нет, использовать первого
  IF second_user_id IS NULL THEN
    second_user_id := first_user_id;
  END IF;

  -- Создать задачу
  INSERT INTO tasks (title, category, creator_id, assignee_id, status)
  VALUES (task_title, task_category, first_user_id, second_user_id, task_status);

  RAISE NOTICE 'Тестовая задача создана: %', task_title;
END;
$$ LANGUAGE plpgsql;

-- Использование:
-- SELECT create_test_task('Моя тестовая задача', 'feature', 'todo');
-- SELECT create_test_task('Ещё одна задача');
*/

-- =====================================================
