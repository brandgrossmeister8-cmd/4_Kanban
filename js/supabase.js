// =====================================================
// Инициализация Supabase клиента
// =====================================================
// Этот файл создаёт глобальный объект supabase для работы с базой данных

// Импорт createClient из Supabase SDK (загружается через CDN в HTML)
// SDK автоматически экспортирует функцию createClient в window.supabase

// Проверка, что конфигурация загружена
if (typeof SUPABASE_URL === 'undefined' || typeof SUPABASE_ANON_KEY === 'undefined') {
  console.error('❌ ОШИБКА: Конфигурация Supabase не загружена!');
  console.error('Убедитесь, что файл config.js подключён ПЕРЕД supabase.js в HTML');
  throw new Error('Supabase config not loaded');
}

// Проверка, что конфигурация заполнена
if (SUPABASE_URL === 'https://YOUR_PROJECT_ID.supabase.co' ||
    SUPABASE_ANON_KEY === 'YOUR_ANON_KEY_HERE') {
  console.error('❌ ОШИБКА: Конфигурация Supabase не настроена!');
  console.error('Откройте файл js/config.js и замените значения на реальные');
  console.error('Инструкции есть в файле database/README.md');

  // Показать пользователю понятное сообщение
  document.body.innerHTML = `
    <div style="
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    ">
      <div style="
        background: white;
        padding: 40px;
        border-radius: 12px;
        max-width: 500px;
        box-shadow: 0 10px 25px rgba(0,0,0,0.2);
      ">
        <h2 style="color: #e74c3c; margin-top: 0;">⚠️ Настройка не завершена</h2>
        <p style="color: #333; line-height: 1.6;">
          Пожалуйста, настройте подключение к Supabase:
        </p>
        <ol style="color: #555; line-height: 1.8;">
          <li>Откройте файл <code>js/config.js</code></li>
          <li>Замените <code>SUPABASE_URL</code> на ваш URL проекта</li>
          <li>Замените <code>SUPABASE_ANON_KEY</code> на ваш ключ</li>
          <li>Сохраните файл и обновите страницу</li>
        </ol>
        <p style="color: #666; font-size: 0.9rem; margin-top: 20px;">
          📖 Подробные инструкции в файле <code>database/README.md</code>
        </p>
      </div>
    </div>
  `;

  throw new Error('Supabase config not configured');
}

// Инициализация Supabase клиента
let supabaseClient;

try {
  // Проверка, что Supabase SDK загружен
  if (typeof window.supabase === 'undefined' || !window.supabase.createClient) {
    throw new Error('Supabase SDK not loaded');
  }

  // Создание клиента Supabase
  supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

} catch (error) {
  console.error('❌ Ошибка инициализации Supabase:', error);
  console.error('Убедитесь, что Supabase SDK подключён в HTML перед этим файлом');

  // Показать понятное сообщение пользователю
  alert('Ошибка подключения к базе данных. Проверьте консоль браузера.');
  throw error;
}

// Экспортируем клиент в глобальную переменную window.supabase для использования в других файлах
// Заменяем объект window.supabase (SDK) на наш клиент
window.supabase = supabaseClient;

// =====================================================
// Полезные функции для отладки
// =====================================================

// Проверка статуса подключения
window.checkSupabaseConnection = async function() {
  try {
    const { data, error } = await supabaseClient.from('profiles').select('count');
    if (error) throw error;
    return true;
  } catch (error) {
    console.error('❌ Ошибка подключения к базе данных:', error);
    return false;
  }
};

// Получить текущего пользователя
window.getCurrentUser = async function() {
  const { data: { user } } = await supabaseClient.auth.getUser();
  return user;
};

// Вывести информацию о Supabase в консоль
window.supabaseInfo = function() {
  return {
    url: SUPABASE_URL,
    hasKey: !!SUPABASE_ANON_KEY,
    isInitialized: !!supabaseClient
  };
};

// =====================================================
// Проверка текущего пользователя из localStorage
// =====================================================

window.getCurrentKanbanUser = function() {
  const userId = localStorage.getItem('kanban_user_id');
  const userName = localStorage.getItem('kanban_user_name');

  if (userId && userName) {
    return {
      id: userId, // UUID как строка
      full_name: userName
    };
  }
  return null;
};

// =====================================================
// Готово! Теперь можно использовать supabase во всех файлах
// =====================================================
