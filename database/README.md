# База данных Канбан Доски - Инструкции по настройке

## Шаг 1: Создание проекта в Supabase

1. Перейдите на [supabase.com](https://supabase.com)
2. Нажмите "Start your project"
3. Войдите через GitHub или создайте аккаунт
4. Нажмите "New project"
5. Заполните данные:
   - **Name**: `kanban-board` (или любое другое название)
   - **Database Password**: придумайте надёжный пароль и сохраните его
   - **Region**: выберите ближайший регион
   - **Pricing Plan**: Free (бесплатно)
6. Нажмите "Create new project"
7. Подождите 2-3 минуты, пока проект создаётся

## Шаг 2: Получение API ключей

После создания проекта:

1. В левом меню нажмите на **Settings** (⚙️)
2. Выберите **API**
3. Найдите и скопируйте:
   - **Project URL** (например: `https://abcdefgh.supabase.co`)
   - **anon/public key** (длинный ключ начинающийся с `eyJ...`)

**Сохраните эти данные!** Они понадобятся для файла `config.js`

## Шаг 3: Выполнение SQL скрипта

1. В Supabase Dashboard откройте **SQL Editor** (слева в меню)
2. Нажмите **New query**
3. Откройте файл `schema.sql` из этой папки
4. Скопируйте весь текст из файла
5. Вставьте в SQL Editor
6. Нажмите **Run** (или Ctrl+Enter)
7. Проверьте результат - должно появиться сообщение "Success"

### Что создаст этот скрипт:
- ✅ Таблица `profiles` (профили пользователей)
- ✅ Таблица `tasks` (задачи)
- ✅ 5 индексов для оптимизации
- ✅ Триггеры для автоматического создания профилей
- ✅ Row Level Security (RLS) политики для безопасности

## Шаг 4: Настройка аутентификации

1. В Supabase Dashboard откройте **Authentication** → **Settings**
2. Найдите раздел **Email Auth**
   - Убедитесь, что **Enable Email provider** включён ✅
3. Найдите **Email confirmation**
   - Для разработки: **отключите** "Confirm email" (уберите галочку)
   - Для продакшена: оставьте включённым и настройте SMTP
4. Найдите **Site URL**
   - Для разработки: `http://localhost:8080` (или другой порт)
   - Для продакшена: URL вашего сайта (например, `https://kanban.example.com`)
5. Нажмите **Save** внизу страницы

## Шаг 5: Проверка создания таблиц

1. Откройте **Table Editor** в левом меню
2. Вы должны увидеть две таблицы:
   - `profiles`
   - `tasks`
3. Кликните на каждую таблицу и убедитесь, что структура создана

## Шаг 6: Тестовые данные (опционально)

Если хотите добавить тестовые задачи:

1. Сначала создайте минимум 2 пользователя через форму регистрации в приложении
2. Откройте **Table Editor** → **profiles**
3. Скопируйте UUID пользователей
4. Откройте файл `seed.sql`
5. Замените `ЗАМЕНИТЕ_НА_UUID_...` на реальные UUID
6. Выполните SQL запросы в SQL Editor

## Проверка работы RLS

RLS (Row Level Security) гарантирует, что пользователи видят только свои задачи.

Проверить политики:
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public';
```

Должно быть 8 политик:
- 3 для таблицы `profiles`
- 5 для таблицы `tasks`

## Что дальше?

После настройки Supabase:

1. Скопируйте **Project URL** и **anon key**
2. Вставьте их в файл `js/config.js` (будет создан далее)
3. Продолжайте следовать плану реализации

## Полезные ссылки

- [Документация Supabase](https://supabase.com/docs)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/trigger-definition.html)

## Возможные проблемы

### Ошибка при выполнении скрипта

Если скрипт не выполняется:
1. Проверьте, что вы вставили весь текст из `schema.sql`
2. Убедитесь, что проект полностью создался (иногда нужно подождать)
3. Попробуйте выполнить скрипт по частям

### RLS блокирует запросы

Если задачи не загружаются:
1. Проверьте, что пользователь авторизован (есть JWT токен)
2. Убедитесь, что политики RLS созданы правильно
3. Проверьте логи в **Database** → **Query Performance**

### Профиль не создаётся автоматически

Если после регистрации нет профиля в таблице `profiles`:
1. Проверьте, что триггер `on_auth_user_created` создан
2. Посмотрите логи в **Database** → **Database**
3. Попробуйте пересоздать триггер

## Поддержка

Если возникли вопросы:
- [Supabase Discord](https://discord.supabase.com)
- [GitHub Issues](https://github.com/supabase/supabase/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/supabase)
