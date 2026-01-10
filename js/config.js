// =====================================================
// Конфигурация Supabase для Канбан Доски
// =====================================================

// ВАЖНО: Замените эти значения на ваши реальные данные из Supabase Dashboard
// Как получить эти данные:
// 1. Откройте Supabase Dashboard
// 2. Перейдите в Settings → API
// 3. Скопируйте Project URL и anon/public key

// URL вашего Supabase проекта
const SUPABASE_URL = 'https://rita-supabase.tw1.ru';

// Публичный (anon) ключ Supabase
// Это безопасно использовать на клиенте, так как RLS защищает данные
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjA5NDU5MjAwLCJleHAiOjI1MjQ2MDgwMDB9.D_JcDEM7eo2s0PDguXXpVg7ZsB37b7QXqcV6jBMYLu0';

// =====================================================
// ИНСТРУКЦИИ ПО НАСТРОЙКЕ:
// =====================================================
//
// 1. Откройте Supabase Dashboard: https://app.supabase.com
// 2. Выберите ваш проект
// 3. Нажмите на иконку Settings (⚙️) слева
// 4. Выберите API в меню настроек
// 5. Найдите раздел "Project URL" и скопируйте URL
// 6. Вставьте URL выше вместо 'https://YOUR_PROJECT_ID.supabase.co'
// 7. Найдите раздел "Project API keys"
// 8. Скопируйте "anon" / "public" ключ (НЕ service_role!)
// 9. Вставьте ключ выше вместо 'YOUR_ANON_KEY_HERE'
// 10. Сохраните файл
//
// =====================================================
// ПРИМЕР правильно заполненных значений:
// =====================================================
// const SUPABASE_URL = 'https://abcdefghijklmnop.supabase.co';
// const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
// =====================================================

// БЕЗОПАСНОСТЬ:
// ✅ anon key безопасен для использования на клиенте
// ✅ Row Level Security (RLS) защищает данные
// ❌ НИКОГДА не используйте service_role ключ на клиенте!
// ❌ НИКОГДА не коммитьте в Git файлы с реальными ключами
// =====================================================
