// =====================================================
// Простая система входа по имени для Канбан Доски
// =====================================================
// Работает с существующей БД (UUID структура)
// Без использования Supabase Auth
// =====================================================

// Генерация UUID v4
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Проверка, что пользователь уже авторизован
async function checkExistingSession() {
    const userId = localStorage.getItem('kanban_user_id');
    const userName = localStorage.getItem('kanban_user_name');

    if (userId && userName) {
        // Пользователь уже авторизован - проверяем, что он есть в БД
        try {
            const { data, error } = await supabase
                .from('profiles')
                .select('*')
                .eq('id', userId)
                .single();

            if (!error && data) {
                // Пользователь найден - редирект на главную
                window.location.href = 'index.html';
                return;
            } else {
                // Пользователя нет в БД - очищаем localStorage
                localStorage.removeItem('kanban_user_id');
                localStorage.removeItem('kanban_user_name');
            }
        } catch (err) {
            console.error('Ошибка проверки сессии:', err);
            localStorage.removeItem('kanban_user_id');
            localStorage.removeItem('kanban_user_name');
        }
    }
}

// Вызов при загрузке страницы
window.addEventListener('load', checkExistingSession);

// =====================================================
// Вход / Регистрация
// =====================================================

async function handleLogin() {
    const fullName = document.getElementById('user-name').value.trim();

    // Валидация
    if (!fullName) {
        showError('login-error', 'Введите ваше имя');
        return;
    }

    if (fullName.length < 2) {
        showError('login-error', 'Имя должно содержать минимум 2 символа');
        return;
    }

    // Показать загрузку
    showLoading(true);
    clearErrors();

    try {
        // Попытка найти пользователя по имени
        const { data: existingUser, error: searchError } = await supabase
            .from('profiles')
            .select('*')
            .eq('full_name', fullName)
            .maybeSingle();

        if (searchError) {
            throw searchError;
        }

        let userId;
        let userName;

        if (existingUser) {
            // Пользователь найден
            userId = existingUser.id;
            userName = existingUser.full_name;
        } else {
            // Пользователь не найден - создаём нового
            const newUserId = generateUUID();

            const { data: newUser, error: insertError } = await supabase
                .from('profiles')
                .insert([
                    {
                        id: newUserId,
                        full_name: fullName,
                        app_source: 'kanban'
                    }
                ])
                .select()
                .single();

            if (insertError) {
                console.error('Ошибка создания пользователя:', insertError);

                // Проверка на ошибку RLS
                if (insertError.code === '42501' || insertError.message.includes('row-level security')) {
                    throw new Error('Не удалось создать нового пользователя из-за настроек безопасности базы данных.\n\nДля разрешения создания новых пользователей выполните в Supabase SQL Editor:\nALTER TABLE profiles DISABLE ROW LEVEL SECURITY;\n\nИли обратитесь к администратору для добавления вашего имени в базу данных.');
                }

                throw insertError;
            }

            userId = newUser.id;
            userName = newUser.full_name;
        }

        // Сохранить данные пользователя в localStorage
        localStorage.setItem('kanban_user_id', userId);
        localStorage.setItem('kanban_user_name', userName);

        // Редирект на главную страницу
        window.location.href = 'index.html';

    } catch (error) {
        console.error('Ошибка входа:', error);
        console.error('Тип ошибки:', error.name);
        console.error('Сообщение:', error.message);

        // Перевод ошибок на русский
        let errorMessage = 'Ошибка входа';

        if (error.name === 'TypeError' && error.message.includes('fetch')) {
            errorMessage = 'Не удалось подключиться к серверу Supabase. Проверьте доступность сервера и выполните SQL миграцию.';
        } else if (error.code === 'PGRST116' || error.code === '42P01') {
            errorMessage = 'Таблица profiles не найдена. Выполните SQL миграцию из файла database/migration_simple_auth.sql';
        } else if (error.message) {
            errorMessage = error.message;
        }

        showError('login-error', errorMessage);
    } finally {
        showLoading(false);
    }
}

// Обработка Enter в форме
document.addEventListener('DOMContentLoaded', () => {
    const nameInput = document.getElementById('user-name');

    if (nameInput) {
        nameInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                handleLogin();
            }
        });
    }
});

// =====================================================
// Вспомогательные функции
// =====================================================

// Показать ошибку
function showError(elementId, message) {
    const errorElement = document.getElementById(elementId);
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }
}

// Очистить все сообщения об ошибках
function clearErrors() {
    const errors = document.querySelectorAll('.error-message');
    errors.forEach(el => {
        el.textContent = '';
        el.style.display = 'none';
    });
}

// Показать/скрыть индикатор загрузки
function showLoading(show) {
    const loading = document.getElementById('loading');
    const form = document.getElementById('login-form');

    if (show) {
        if (loading) loading.style.display = 'flex';
        if (form) form.style.display = 'none';
    } else {
        if (loading) loading.style.display = 'none';
        if (form) form.style.display = 'block';
    }
}

// =====================================================
// Показать список пользователей
// =====================================================

async function toggleUsersList(event) {
    const listDiv = document.getElementById('users-list');
    const button = event ? event.target : document.querySelector('button[onclick*="toggleUsersList"]');

    if (listDiv.style.display === 'none' || !listDiv.style.display) {
        // Показать список - загрузить пользователей
        button.textContent = 'Скрыть список';
        showLoading(true);

        try {
            const { data, error } = await supabase
                .from('profiles')
                .select('full_name')
                .eq('app_source', 'kanban')
                .order('full_name');

            if (error) throw error;

            if (data && data.length > 0) {
                const html = '<h4 style="margin: 15px 0 10px 0; color: #333; font-size: 0.95rem;">Доступные пользователи:</h4>' +
                    '<ul style="list-style: none; padding: 0; margin: 0; max-height: 200px; overflow-y: auto;">' +
                    data.map(user =>
                        `<li style="padding: 10px; margin: 5px 0; background: #f8f9fa; border-radius: 6px; cursor: pointer; transition: background 0.2s;"
                         onmouseover="this.style.background='#e9ecef'"
                         onmouseout="this.style.background='#f8f9fa'"
                         onclick="document.getElementById('user-name').value='${user.full_name.replace(/'/g, "\\'")}'; document.getElementById('users-list').style.display='none'; document.querySelector('button[onclick*=toggleUsersList]').textContent='Показать список пользователей';">
                            ${user.full_name}
                        </li>`
                    ).join('') +
                    '</ul>';
                listDiv.innerHTML = html;
                listDiv.style.display = 'block';
            } else {
                listDiv.innerHTML = '<p style="color: #666; margin-top: 10px; font-size: 0.9rem;">Пользователи не найдены</p>';
                listDiv.style.display = 'block';
            }
        } catch (error) {
            console.error('Ошибка загрузки пользователей:', error);
            showError('login-error', 'Не удалось загрузить список пользователей');
            button.textContent = 'Показать список пользователей';
        } finally {
            showLoading(false);
        }
    } else {
        // Скрыть список
        listDiv.style.display = 'none';
        button.textContent = 'Показать список пользователей';
    }
}
