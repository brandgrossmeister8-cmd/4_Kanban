// =====================================================
// Канбан Доска - Основной скрипт с интеграцией Supabase
// =====================================================

// Глобальные переменные
let currentUser = null;
let allUsers = [];
let tasks = [];
let currentFilters = {};
let currentColumn = '';
let editingTaskId = null;

// Переменные для табличного вида
let currentView = 'board'; // 'board' или 'table'
let sortColumn = null;
let sortDirection = 'asc';

// =====================================================
// Инициализация приложения
// =====================================================

async function init() {
    console.log('Инициализация приложения...');

    // Проверка аутентификации через localStorage
    const userId = localStorage.getItem('kanban_user_id');
    const userName = localStorage.getItem('kanban_user_name');

    if (!userId || !userName) {
        // Нет авторизации - редирект на страницу входа
        console.log('Пользователь не авторизован, редирект на auth.html');
        window.location.href = 'auth.html';
        return;
    }

    currentUser = {
        id: userId, // UUID как строка
        full_name: userName
    };
    console.log('Пользователь авторизован:', currentUser.full_name);

    // Загрузка данных
    try {
        await loadUserProfile();
        await loadAllUsers();
        await loadTasks();
    } catch (error) {
        console.error('Ошибка загрузки данных:', error);
        alert('Ошибка загрузки данных. Перезагрузите страницу.');
        return;
    }

    // Инициализация UI
    setupDragAndDrop();
    updateAllCounts();
    populateUserDropdowns();

    console.log('Приложение инициализировано');
}

// =====================================================
// Загрузка данных
// =====================================================

// Загрузка профиля пользователя
async function loadUserProfile() {
    // Отображение имени пользователя в header
    document.getElementById('user-name').textContent = currentUser.full_name;
    console.log('Профиль загружен:', currentUser.full_name);
}

// Загрузка всех пользователей (для выпадающих списков)
async function loadAllUsers() {
    const { data, error } = await supabase
        .from('profiles')
        .select('id, full_name')
        .eq('app_source', 'kanban')
        .order('full_name');

    if (error) {
        console.error('Ошибка загрузки пользователей:', error);
        throw error;
    }

    allUsers = data;
    console.log('Загружено канбан-пользователей:', allUsers.length);
}

// Загрузка задач с фильтрами
async function loadTasks(filters = {}) {
    let query = supabase
        .from('canban_tasks')
        .select('*');

    // Применение фильтров
    if (filters.creator_id) {
        query = query.eq('creator_id', filters.creator_id);
    }

    if (filters.assignee_id) {
        query = query.eq('assignee_id', filters.assignee_id);
    }

    if (filters.category) {
        query = query.eq('category', filters.category);
    }

    if (filters.deadline_from) {
        query = query.gte('deadline', filters.deadline_from);
    }

    if (filters.deadline_to) {
        query = query.lte('deadline', filters.deadline_to);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) {
        console.error('Ошибка загрузки задач:', error);
        alert('Ошибка загрузки задач');
        return;
    }

    tasks = data;
    console.log('Загружено задач:', tasks.length);

    renderAllTasks();
    updateAllCounts();

    // Обновить табличный вид если он активен
    if (currentView === 'table') {
        renderTableView();
    }
}

// =====================================================
// Заполнение выпадающих списков
// =====================================================

function populateUserDropdowns() {
    // Выпадающий список исполнителя в модальном окне
    const assigneeSelect = document.getElementById('task-assignee');
    assigneeSelect.innerHTML = '<option value="">Выберите исполнителя</option>';

    allUsers.forEach(user => {
        const option = document.createElement('option');
        option.value = user.id;
        option.textContent = user.full_name;
        assigneeSelect.appendChild(option);
    });

    // Постановщик - текущий пользователь (disabled)
    const creatorSelect = document.getElementById('task-creator');
    const currentUserProfile = allUsers.find(u => u.id === currentUser.id);
    creatorSelect.innerHTML = `<option value="${currentUser.id}" selected>${
        currentUserProfile?.full_name || 'Вы'
    }</option>`;

    // Фильтры
    const filterCreator = document.getElementById('filter-creator');
    const filterAssignee = document.getElementById('filter-assignee');

    filterCreator.innerHTML = '<option value="">Все постановщики</option>';
    filterAssignee.innerHTML = '<option value="">Все исполнители</option>';

    allUsers.forEach(user => {
        const option1 = document.createElement('option');
        option1.value = user.id;
        option1.textContent = user.full_name;
        filterCreator.appendChild(option1);

        const option2 = document.createElement('option');
        option2.value = user.id;
        option2.textContent = user.full_name;
        filterAssignee.appendChild(option2);
    });
}

// =====================================================
// Фильтрация
// =====================================================

async function applyFilters() {
    currentFilters = {
        creator_id: document.getElementById('filter-creator').value || undefined,
        assignee_id: document.getElementById('filter-assignee').value || undefined,
        category: document.getElementById('filter-category').value || undefined,
        status: document.getElementById('filter-status').value || undefined,
        deadline_from: document.getElementById('filter-deadline-from').value || undefined,
        deadline_to: document.getElementById('filter-deadline-to').value || undefined,
    };

    console.log('Применение фильтров:', currentFilters);
    await loadTasks(currentFilters);
}

function clearFilters() {
    document.getElementById('filter-creator').value = '';
    document.getElementById('filter-assignee').value = '';
    document.getElementById('filter-category').value = '';
    document.getElementById('filter-status').value = '';
    document.getElementById('filter-deadline-from').value = '';
    document.getElementById('filter-deadline-to').value = '';

    currentFilters = {};
    console.log('Фильтры сброшены');
    loadTasks();
}

// =====================================================
// Управление задачами
// =====================================================

function addTask(column) {
    currentColumn = column;
    editingTaskId = null;
    document.querySelector('.modal-content h2').textContent = 'Новая задача';

    // Очистка формы
    document.getElementById('task-title').value = '';
    document.getElementById('task-description').value = '';
    document.getElementById('task-category').value = '';
    document.getElementById('task-assignee').value = '';
    document.getElementById('task-has-deadline').checked = false;
    document.getElementById('task-deadline').value = '';
    document.getElementById('deadline-group').style.display = 'none';

    document.getElementById('modal').classList.add('active');
    document.getElementById('task-title').focus();
}

function addTaskFromTable() {
    addTask('todo'); // По умолчанию
}

async function editTask(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;

    editingTaskId = taskId;
    currentColumn = task.status;

    document.querySelector('.modal-content h2').textContent = 'Редактирование задачи';
    document.getElementById('task-title').value = task.title;
    document.getElementById('task-description').value = task.description || '';
    document.getElementById('task-category').value = task.category || '';
    document.getElementById('task-assignee').value = task.assignee_id;

    if (task.deadline) {
        document.getElementById('task-has-deadline').checked = true;
        // Преобразование UTC в local datetime
        const deadline = new Date(task.deadline);
        const localDatetime = new Date(deadline.getTime() - deadline.getTimezoneOffset() * 60000)
            .toISOString().slice(0, 16);
        document.getElementById('task-deadline').value = localDatetime;
        document.getElementById('deadline-group').style.display = 'block';
    } else {
        document.getElementById('task-has-deadline').checked = false;
        document.getElementById('task-deadline').value = '';
        document.getElementById('deadline-group').style.display = 'none';
    }

    document.getElementById('modal').classList.add('active');
    document.getElementById('task-title').focus();
}

async function saveTask() {
    const title = document.getElementById('task-title').value.trim();
    const description = document.getElementById('task-description').value.trim();
    const category = document.getElementById('task-category').value;
    const assignee_id = document.getElementById('task-assignee').value;
    const hasDeadline = document.getElementById('task-has-deadline').checked;
    const deadline = hasDeadline ? document.getElementById('task-deadline').value : null;

    // Валидация
    if (!title) {
        alert('Пожалуйста, введите название задачи');
        return;
    }

    if (!assignee_id) {
        alert('Пожалуйста, выберите исполнителя');
        return;
    }

    const taskData = {
        title,
        description: description || null,
        category: category || null,
        creator_id: currentUser.id,
        assignee_id,
        deadline: deadline || null,
        status: currentColumn
    };

    try {
        if (editingTaskId !== null) {
            // Обновление существующей задачи
            const { error } = await supabase
                .from('canban_tasks')
                .update(taskData)
                .eq('id', editingTaskId);

            if (error) throw error;
            console.log('Задача обновлена:', editingTaskId);

        } else {
            // Создание новой задачи
            const { error } = await supabase
                .from('canban_tasks')
                .insert([taskData]);

            if (error) throw error;
            console.log('Задача создана');
        }

        closeModal();
        await loadTasks(currentFilters);

    } catch (error) {
        console.error('Ошибка сохранения задачи:', error);
        alert('Ошибка при сохранении задачи: ' + error.message);
    }
}

async function deleteTask(taskId) {
    if (!confirm('Вы уверены, что хотите удалить эту задачу?')) {
        return;
    }

    try {
        const { error } = await supabase
            .from('canban_tasks')
            .delete()
            .eq('id', taskId);

        if (error) throw error;

        console.log('Задача удалена:', taskId);
        await loadTasks(currentFilters);

    } catch (error) {
        console.error('Ошибка удаления задачи:', error);
        alert('Ошибка при удалении задачи: ' + error.message);
    }
}

async function changeTaskStatus(taskId, newStatus) {
    try {
        const { error } = await supabase
            .from('canban_tasks')
            .update({ status: newStatus })
            .eq('id', taskId);

        if (error) throw error;

        console.log('Статус задачи изменен:', taskId, newStatus);
        await loadTasks(currentFilters);

    } catch (error) {
        console.error('Ошибка изменения статуса:', error);
        alert('Ошибка при изменении статуса: ' + error.message);
    }
}

// =====================================================
// Модальное окно
// =====================================================

function closeModal() {
    document.getElementById('modal').classList.remove('active');
    editingTaskId = null;
    document.querySelector('.modal-content h2').textContent = 'Новая задача';
}

function toggleDeadlineInput() {
    const checkbox = document.getElementById('task-has-deadline');
    const deadlineGroup = document.getElementById('deadline-group');
    deadlineGroup.style.display = checkbox.checked ? 'block' : 'none';
}

// =====================================================
// Отрисовка задач (канбан вид)
// =====================================================

function renderTask(task) {
    const taskElement = document.createElement('div');
    taskElement.className = 'task';
    taskElement.draggable = true;
    taskElement.dataset.taskId = task.id;

    const categoryNames = {
        'bug': 'Ошибка',
        'feature': 'Новая функция',
        'improvement': 'Улучшение',
        'documentation': 'Документация',
        'testing': 'Тестирование',
        'other': 'Другое'
    };

    const categoryClass = task.category ? `category-${task.category}` : '';

    let deadlineHtml = '';
    let isOverdue = false;
    if (task.deadline) {
        const deadlineDate = new Date(task.deadline);
        const now = new Date();
        isOverdue = deadlineDate < now;
        const deadlineClass = isOverdue ? 'deadline-overdue' : 'deadline-normal';
        const formattedDate = deadlineDate.toLocaleString('ru-RU', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        deadlineHtml = `<div class="task-deadline ${deadlineClass}">⏰ ${formattedDate}</div>`;
    }

    if (isOverdue) {
        taskElement.classList.add('task-overdue');
    }

    // Поиск пользователей по ID
    const creator = allUsers.find(u => u.id === task.creator_id);
    const assignee = allUsers.find(u => u.id === task.assignee_id);
    const creatorName = creator?.full_name || 'Неизвестно';
    const assigneeName = assignee?.full_name || 'Неизвестно';

    taskElement.innerHTML = `
        <div class="task-title">${escapeHtml(task.title)}</div>
        ${task.category ? `<div class="task-category ${categoryClass}">${categoryNames[task.category] || task.category}</div>` : ''}
        ${task.description ? `<div class="task-description">${escapeHtml(task.description)}</div>` : ''}
        <div class="task-meta">
            <div class="task-person"><strong>Постановщик:</strong> ${escapeHtml(creatorName)}</div>
            <div class="task-person"><strong>Исполнитель:</strong> ${escapeHtml(assigneeName)}</div>
        </div>
        ${deadlineHtml}
        <div class="task-status-selector">
            <label>Статус:</label>
            <select class="status-dropdown" onchange="changeTaskStatus('${task.id}', this.value)">
                <option value="todo" ${task.status === 'todo' ? 'selected' : ''}>К выполнению</option>
                <option value="in-progress" ${task.status === 'in-progress' ? 'selected' : ''}>В работе</option>
                <option value="done" ${task.status === 'done' ? 'selected' : ''}>Готово</option>
            </select>
        </div>
        <div class="task-actions">
            <button class="task-edit" onclick="editTask('${task.id}')">Редактировать</button>
            <button class="task-delete" onclick="deleteTask('${task.id}')">Удалить</button>
        </div>
    `;

    const container = document.getElementById(`${task.status}-tasks`);
    container.appendChild(taskElement);

    setupTaskDrag(taskElement);
}

function renderAllTasks() {
    // Очистка всех колонок
    document.querySelectorAll('.tasks').forEach(container => {
        container.innerHTML = '';
    });

    // Отрисовка задач
    tasks.forEach(task => renderTask(task));
}

// =====================================================
// Переключение видов
// =====================================================

function switchView(view) {
    currentView = view;

    if (view === 'board') {
        document.getElementById('board-view').style.display = 'block';
        document.getElementById('table-view').style.display = 'none';
        document.getElementById('view-board').classList.add('active');
        document.getElementById('view-table').classList.remove('active');
    } else {
        document.getElementById('board-view').style.display = 'none';
        document.getElementById('table-view').style.display = 'block';
        document.getElementById('view-board').classList.remove('active');
        document.getElementById('view-table').classList.add('active');
        renderTableView();
    }
}

// =====================================================
// Табличный вид
// =====================================================

function renderTableView() {
    const tbody = document.getElementById('table-tasks-body');
    tbody.innerHTML = '';

    const categoryNames = {
        'bug': 'Ошибка',
        'feature': 'Новая функция',
        'improvement': 'Улучшение',
        'documentation': 'Документация',
        'testing': 'Тестирование',
        'other': 'Другое'
    };

    const statusNames = {
        'todo': 'К выполнению',
        'in-progress': 'В работе',
        'done': 'Готово'
    };

    // Сортировка задач если выбран столбец
    let sortedTasks = [...tasks];
    if (sortColumn) {
        sortedTasks.sort((a, b) => {
            let aVal = a[sortColumn];
            let bVal = b[sortColumn];

            // Для creator и assignee - ищем пользователей по ID
            if (sortColumn === 'creator') {
                const aCreator = allUsers.find(u => u.id === a.creator_id);
                const bCreator = allUsers.find(u => u.id === b.creator_id);
                aVal = aCreator?.full_name || '';
                bVal = bCreator?.full_name || '';
            } else if (sortColumn === 'assignee') {
                const aAssignee = allUsers.find(u => u.id === a.assignee_id);
                const bAssignee = allUsers.find(u => u.id === b.assignee_id);
                aVal = aAssignee?.full_name || '';
                bVal = bAssignee?.full_name || '';
            }

            // Сравнение
            if (aVal < bVal) return sortDirection === 'asc' ? -1 : 1;
            if (aVal > bVal) return sortDirection === 'asc' ? 1 : -1;
            return 0;
        });
    }

    sortedTasks.forEach(task => {
        const row = document.createElement('tr');

        // Проверка просрочки
        let isOverdue = false;
        let deadlineText = '-';
        if (task.deadline) {
            const deadlineDate = new Date(task.deadline);
            const now = new Date();
            isOverdue = deadlineDate < now;
            deadlineText = deadlineDate.toLocaleString('ru-RU', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        if (isOverdue) {
            row.classList.add('row-overdue');
        }

        const createdAt = new Date(task.created_at).toLocaleString('ru-RU', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });

        // Поиск пользователей по ID
        const creator = allUsers.find(u => u.id === task.creator_id);
        const assignee = allUsers.find(u => u.id === task.assignee_id);

        row.innerHTML = `
            <td>${task.id}</td>
            <td class="td-title">${escapeHtml(task.title)}</td>
            <td>${escapeHtml(task.description || '-')}</td>
            <td>
                ${task.category ? `<span class="table-category category-${task.category}">${categoryNames[task.category]}</span>` : '-'}
            </td>
            <td>${escapeHtml(creator?.full_name || '-')}</td>
            <td>${escapeHtml(assignee?.full_name || '-')}</td>
            <td class="table-deadline ${isOverdue ? 'overdue' : ''}">${deadlineText}</td>
            <td>
                <span class="table-status status-${task.status}">${statusNames[task.status]}</span>
            </td>
            <td>${createdAt}</td>
            <td class="table-actions">
                <button class="task-edit" onclick="editTask('${task.id}')">✏️</button>
                <button class="task-delete" onclick="deleteTask('${task.id}')">🗑️</button>
            </td>
        `;

        tbody.appendChild(row);
    });
}

function sortTable(column) {
    if (sortColumn === column) {
        // Переключение направления сортировки
        sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
        sortColumn = column;
        sortDirection = 'asc';
    }

    // Обновление иконок сортировки
    document.querySelectorAll('.tasks-table th').forEach(th => {
        th.classList.remove('sorted-asc', 'sorted-desc');
    });

    const currentTh = event.target.closest('th');
    currentTh.classList.add(sortDirection === 'asc' ? 'sorted-asc' : 'sorted-desc');

    renderTableView();
}

// =====================================================
// Drag and Drop
// =====================================================

function setupTaskDrag(taskElement) {
    taskElement.addEventListener('dragstart', handleDragStart);
    taskElement.addEventListener('dragend', handleDragEnd);
}

function setupDragAndDrop() {
    const columns = document.querySelectorAll('.tasks');

    columns.forEach(column => {
        column.addEventListener('dragover', handleDragOver);
        column.addEventListener('drop', handleDrop);
        column.addEventListener('dragleave', handleDragLeave);
    });
}

function handleDragStart(e) {
    e.target.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/html', e.target.innerHTML);
}

function handleDragEnd(e) {
    e.target.classList.remove('dragging');
}

function handleDragOver(e) {
    if (e.preventDefault) {
        e.preventDefault();
    }

    e.dataTransfer.dropEffect = 'move';
    e.currentTarget.classList.add('drag-over');

    return false;
}

function handleDragLeave(e) {
    e.currentTarget.classList.remove('drag-over');
}

async function handleDrop(e) {
    if (e.stopPropagation) {
        e.stopPropagation();
    }

    e.currentTarget.classList.remove('drag-over');

    const draggingTask = document.querySelector('.dragging');
    if (!draggingTask) return;

    const newColumn = e.currentTarget.closest('.column');
    const oldColumn = draggingTask.closest('.column');
    const newStatus = newColumn.dataset.status;
    const oldStatus = oldColumn.dataset.status;
    const taskId = draggingTask.dataset.taskId;

    if (newStatus !== oldStatus) {
        try {
            // Обновление статуса в БД
            const { error } = await supabase
                .from('canban_tasks')
                .update({ status: newStatus })
                .eq('id', taskId);

            if (error) throw error;

            console.log('Статус задачи обновлён:', taskId, newStatus);

            // Перерисовка задач
            await loadTasks(currentFilters);

        } catch (error) {
            console.error('Ошибка при перемещении задачи:', error);
            alert('Ошибка при перемещении задачи');
        }
    }

    return false;
}

// =====================================================
// Счётчики задач
// =====================================================

function updateCount(status) {
    const count = tasks.filter(t => t.status === status).length;
    const column = document.querySelector(`[data-status="${status}"]`);
    if (column) {
        column.querySelector('.count').textContent = count;
    }
}

function updateAllCounts() {
    updateCount('todo');
    updateCount('in-progress');
    updateCount('done');
}

// =====================================================
// Вспомогательные функции
// =====================================================

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// =====================================================
// Выход из системы
// =====================================================

async function logout() {
    if (!confirm('Вы уверены, что хотите выйти?')) {
        return;
    }

    // Очистка данных пользователя из localStorage
    localStorage.removeItem('kanban_user_id');
    localStorage.removeItem('kanban_user_name');

    console.log('Пользователь вышел');
    window.location.href = 'auth.html';
}

// =====================================================
// Обработчики событий
// =====================================================

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeModal();
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const taskTitle = document.getElementById('task-title');
    const taskHasDeadline = document.getElementById('task-has-deadline');

    if (taskTitle) {
        taskTitle.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                saveTask();
            }
        });
    }

    if (taskHasDeadline) {
        taskHasDeadline.addEventListener('change', toggleDeadlineInput);
    }
});

// =====================================================
// Запуск приложения
// =====================================================

window.addEventListener('load', init);

console.log('Script.js загружен');
