let tasks = JSON.parse(localStorage.getItem('kanbanTasks')) || [];
let currentColumn = '';
let taskIdCounter = tasks.length > 0 ? Math.max(...tasks.map(t => t.id)) + 1 : 1;
let editingTaskId = null;

function init() {
    renderAllTasks();
    setupDragAndDrop();
    updateAllCounts();
}

function addTask(column) {
    currentColumn = column;
    editingTaskId = null;
    document.querySelector('.modal-content h2').textContent = 'Новая задача';
    document.getElementById('modal').classList.add('active');
    document.getElementById('task-title').focus();
}

function editTask(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;

    editingTaskId = taskId;
    currentColumn = task.status;

    document.querySelector('.modal-content h2').textContent = 'Редактирование задачи';
    document.getElementById('task-title').value = task.title;
    document.getElementById('task-description').value = task.description || '';
    document.getElementById('task-category').value = task.category || '';
    document.getElementById('task-creator').value = task.creator || '';
    document.getElementById('task-assignee').value = task.assignee || '';

    if (task.deadline) {
        document.getElementById('task-has-deadline').checked = true;
        document.getElementById('task-deadline').value = task.deadline;
        document.getElementById('deadline-group').style.display = 'block';
    } else {
        document.getElementById('task-has-deadline').checked = false;
        document.getElementById('task-deadline').value = '';
        document.getElementById('deadline-group').style.display = 'none';
    }

    document.getElementById('modal').classList.add('active');
    document.getElementById('task-title').focus();
}

function toggleDeadlineInput() {
    const checkbox = document.getElementById('task-has-deadline');
    const deadlineGroup = document.getElementById('deadline-group');
    deadlineGroup.style.display = checkbox.checked ? 'block' : 'none';
}

function closeModal() {
    document.getElementById('modal').classList.remove('active');
    document.getElementById('task-title').value = '';
    document.getElementById('task-description').value = '';
    document.getElementById('task-category').value = '';
    document.getElementById('task-creator').value = '';
    document.getElementById('task-assignee').value = '';
    document.getElementById('task-has-deadline').checked = false;
    document.getElementById('task-deadline').value = '';
    document.getElementById('deadline-group').style.display = 'none';
    editingTaskId = null;
    document.querySelector('.modal-content h2').textContent = 'Новая задача';
}

function saveTask() {
    const title = document.getElementById('task-title').value.trim();
    const description = document.getElementById('task-description').value.trim();
    const category = document.getElementById('task-category').value;
    const creator = document.getElementById('task-creator').value.trim();
    const assignee = document.getElementById('task-assignee').value.trim();
    const hasDeadline = document.getElementById('task-has-deadline').checked;
    const deadline = hasDeadline ? document.getElementById('task-deadline').value : null;

    if (!title) {
        alert('Пожалуйста, введите название задачи');
        return;
    }

    if (editingTaskId !== null) {
        // Редактируем существующую задачу
        const task = tasks.find(t => t.id === editingTaskId);
        if (task) {
            task.title = title;
            task.description = description;
            task.category = category;
            task.creator = creator;
            task.assignee = assignee;
            task.deadline = deadline;

            saveTasks();
            renderAllTasks();
            updateAllCounts();
        }
    } else {
        // Создаем новую задачу
        const task = {
            id: taskIdCounter++,
            title: title,
            description: description,
            category: category,
            creator: creator,
            assignee: assignee,
            deadline: deadline,
            status: currentColumn
        };

        tasks.push(task);
        saveTasks();
        renderTask(task);
        updateCount(currentColumn);
    }

    closeModal();
}

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

    // Добавляем класс для просроченных задач
    if (isOverdue) {
        taskElement.classList.add('task-overdue');
    }

    taskElement.innerHTML = `
        <div class="task-title">${escapeHtml(task.title)}</div>
        ${task.category ? `<div class="task-category ${categoryClass}">${categoryNames[task.category] || task.category}</div>` : ''}
        ${task.description ? `<div class="task-description">${escapeHtml(task.description)}</div>` : ''}
        <div class="task-meta">
            ${task.creator ? `<div class="task-person"><strong>Постановщик:</strong> ${escapeHtml(task.creator)}</div>` : ''}
            ${task.assignee ? `<div class="task-person"><strong>Исполнитель:</strong> ${escapeHtml(task.assignee)}</div>` : ''}
        </div>
        ${deadlineHtml}
        <div class="task-actions">
            <button class="task-edit" onclick="editTask(${task.id})">Редактировать</button>
            <button class="task-delete" onclick="deleteTask(${task.id})">Удалить</button>
        </div>
    `;

    const container = document.getElementById(`${task.status}-tasks`);
    container.appendChild(taskElement);

    setupTaskDrag(taskElement);
}

function renderAllTasks() {
    document.querySelectorAll('.tasks').forEach(container => {
        container.innerHTML = '';
    });

    tasks.forEach(task => renderTask(task));
}

function deleteTask(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;

    if (confirm('Вы уверены, что хотите удалить эту задачу?')) {
        tasks = tasks.filter(t => t.id !== taskId);
        saveTasks();

        const taskElement = document.querySelector(`[data-task-id="${taskId}"]`);
        if (taskElement) {
            const status = taskElement.closest('.column').dataset.status;
            taskElement.remove();
            updateCount(status);
        }
    }
}

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
    const taskId = e.target.dataset.taskId;
    const task = tasks.find(t => t.id === parseInt(taskId));

    console.log('=== DRAG START ===');
    console.log('Task ID:', taskId);
    console.log('Task Title:', task?.title);
    console.log('Current Status:', task?.status);
    console.log('Element:', e.target);

    e.target.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/html', e.target.innerHTML);
}

function handleDragEnd(e) {
    console.log('=== DRAG END ===');
    console.log('Element:', e.target);
    e.target.classList.remove('dragging');
}

function handleDragOver(e) {
    if (e.preventDefault) {
        e.preventDefault();
    }

    const columnStatus = e.currentTarget.closest('.column')?.dataset.status;
    console.log('--- Drag Over:', columnStatus);

    e.dataTransfer.dropEffect = 'move';
    e.currentTarget.classList.add('drag-over');

    return false;
}

function handleDragLeave(e) {
    const columnStatus = e.currentTarget.closest('.column')?.dataset.status;
    console.log('--- Drag Leave:', columnStatus);
    e.currentTarget.classList.remove('drag-over');
}

function handleDrop(e) {
    if (e.stopPropagation) {
        e.stopPropagation();
    }

    console.log('=== DROP EVENT ===');

    e.currentTarget.classList.remove('drag-over');

    const draggingTask = document.querySelector('.dragging');
    if (!draggingTask) {
        console.error('No dragging task found!');
        return;
    }

    const newColumn = e.currentTarget.closest('.column');
    const oldColumn = draggingTask.closest('.column');
    const newStatus = newColumn.dataset.status;
    const oldStatus = oldColumn.dataset.status;
    const taskId = parseInt(draggingTask.dataset.taskId);

    console.log('Task ID:', taskId);
    console.log('Old Status:', oldStatus);
    console.log('New Status:', newStatus);

    if (newStatus !== oldStatus) {
        console.log('Moving task to new column...');
        e.currentTarget.appendChild(draggingTask);

        const task = tasks.find(t => t.id === taskId);
        if (task) {
            console.log('Task found in array:', task);
            task.status = newStatus;
            saveTasks();
            console.log('Task status updated and saved');
        } else {
            console.error('Task not found in tasks array!');
        }

        updateCount(oldStatus);
        updateCount(newStatus);
        console.log('Counts updated');
    } else {
        console.log('Same column - no action needed');
    }

    console.log('Current tasks state:', tasks);
    console.log('=================');

    return false;
}

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

function saveTasks() {
    localStorage.setItem('kanbanTasks', JSON.stringify(tasks));
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeModal();
    }
});

document.getElementById('task-title').addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        saveTask();
    }
});

document.getElementById('task-has-deadline').addEventListener('change', toggleDeadlineInput);

window.addEventListener('load', init);
