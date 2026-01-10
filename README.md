# 🎯 Канбан Доска

Простая и мощная система управления задачами с drag-and-drop интерфейсом.

## 🌟 Возможности

- ✅ Простая авторизация по имени (без email/пароля)
- ✅ Drag & Drop перемещение задач между колонками (ToDo, In Progress, Done)
- ✅ Создание, редактирование и удаление задач
- ✅ Назначение исполнителей и постановщиков
- ✅ Категории задач (bug, feature, improvement, documentation, testing, other)
- ✅ Дедлайны с визуальной индикацией
- ✅ Два режима просмотра: канбан-доска и таблица
- ✅ Фильтрация пользователей по источнику приложения
- ✅ Красивый современный интерфейс

## 🚀 Быстрый старт

### 1. Требования

- Сервер с поддержкой статических файлов (Apache, Nginx, или любой хостинг)
- Аккаунт Supabase (или self-hosted Supabase)
- Git (для обновлений)

### 2. Установка на сервер

#### Вариант A: Через FTP/SFTP

1. Скачайте ZIP архив репозитория с GitHub
2. Загрузите все файлы на ваш сервер через FTP клиент (FileZilla, Cyberduck и т.д.)
3. Убедитесь, что `index.html` находится в корне веб-директории

#### Вариант B: Через SSH (рекомендуется)

```bash
# 1. Подключитесь к серверу по SSH
ssh user@your-server.com

# 2. Перейдите в директорию сайта
cd /var/www/html  # или путь к вашей веб-директории

# 3. Клонируйте репозиторий
git clone https://github.com/brandgrossmeister8-cmd/4_Kanban.git kanban

# 4. Перейдите в директорию
cd kanban

# 5. Дайте права на выполнение скрипту обновления
chmod +x deploy.sh
```

### 3. Настройка Supabase

#### 3.1 Выполните SQL миграции

В Supabase Dashboard → SQL Editor выполните по порядку:

1. **database/schema.sql** - Создание основных таблиц (если еще не создано)
2. **database/add_app_source.sql** - Добавление поля app_source для фильтрации

#### 3.2 Отключите RLS для таблицы задач

```sql
ALTER TABLE canban_tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
```

#### 3.3 Настройте конфигурацию

Отредактируйте файл `js/config.js` и вставьте ваши ключи:

```javascript
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key-here';
```

Получить ключи: Supabase Dashboard → Settings → API

### 4. Готово!

Откройте в браузере: `https://your-domain.com/kanban/auth.html`

## 🔄 Автоматическое обновление

### Первичная настройка на сервере

```bash
# 1. Перейдите в директорию приложения
cd /path/to/kanban

# 2. Настройте git (один раз)
git config pull.rebase false

# 3. Создайте резервную копию config.js перед первым обновлением
cp js/config.js js/config.js.production
```

### Обновление приложения

Когда вы внесли изменения и запушили на GitHub, обновите сервер:

```bash
# Способ 1: Автоматический скрипт (рекомендуется)
./deploy.sh

# Способ 2: Ручное обновление
git pull origin main
```

### Скрипт deploy.sh делает:

1. ✅ Проверяет текущую ветку
2. ✅ Показывает список изменений
3. ✅ Спрашивает подтверждение
4. ✅ Создает резервную копию config.js
5. ✅ Выполняет git pull
6. ✅ Восстанавливает ваши ключи если нужно
7. ✅ Показывает версию после обновления

## 📁 Структура проекта

```
4_Kanban/
├── index.html              # Главная страница (канбан доска)
├── auth.html              # Страница входа
├── styles.css             # Стили приложения
├── deploy.sh              # Скрипт автообновления
├── .gitignore             # Исключения для Git
├── .env.example           # Пример файла переменных окружения
├── README.md              # Документация
│
├── js/
│   ├── config.js          # Конфигурация Supabase (⚠️ не коммитить с реальными ключами!)
│   ├── supabase.js        # Инициализация Supabase клиента
│   ├── auth.js            # Логика авторизации
│   └── script.js          # Основная логика приложения
│
└── database/
    ├── schema.sql         # Основная схема БД
    ├── add_app_source.sql # Миграция: добавление app_source
    ├── check_database.sql # Диагностика БД
    └── check_tables.sql   # Проверка структуры таблиц
```

## 🔐 Безопасность

### ⚠️ ВАЖНО: Защита ключей Supabase

**НЕ коммитьте файл config.js с реальными ключами в Git!**

#### Правильная работа с ключами:

1. **На локальной машине:**
```bash
# Создайте config.js с реальными ключами
nano js/config.js

# Добавьте config.js в .gitignore (уже добавлено)
# Коммитьте только config.js.example с placeholder'ами
```

2. **На сервере:**
```bash
# Создайте config.js с реальными ключами один раз
nano js/config.js

# При обновлении через deploy.sh скрипт автоматически сохранит ваши ключи
```

3. **Если случайно закоммитили ключи:**
```bash
# Удалите config.js из git
git rm --cached js/config.js

# Сбросьте ключи в Supabase Dashboard → Settings → API → Reset API Keys
```

## 🛠 Команды для работы

### Разработка

```bash
# Запустить локальный сервер (Python 3)
python3 -m http.server 8080

# Открыть в браузере
open http://localhost:8080/auth.html
```

### Обновление на сервере

```bash
# SSH подключение
ssh user@your-server.com

# Перейти в директорию
cd /path/to/kanban

# Обновить приложение
./deploy.sh

# Или вручную
git pull origin main
```

### Git команды

```bash
# Проверить статус
git status

# Добавить изменения
git add .

# Создать коммит
git commit -m "Описание изменений"

# Запушить на GitHub
git push origin main

# Посмотреть историю
git log --oneline -10
```

## 📝 SQL миграции

### Выполнены:

- ✅ Создание таблиц profiles и canban_tasks
- ✅ Добавление поля app_source для фильтрации пользователей
- ✅ Отключение RLS для таблиц

### Проверка структуры БД:

```bash
# В Supabase SQL Editor выполните
SELECT * FROM information_schema.tables
WHERE table_schema = 'public';

# Проверить пользователей
SELECT id, full_name, app_source FROM profiles;

# Проверить задачи
SELECT id, title, status FROM canban_tasks;
```

## 🐛 Решение проблем

### Задачи не перетаскиваются

1. Очистите кеш браузера: `Cmd+Shift+R` (Mac) или `Ctrl+Shift+R` (Windows)
2. Проверьте версию в URL: `?v=20` должна быть актуальной

### Ошибки при создании/редактировании/удалении

1. Проверьте что RLS отключен:
```sql
ALTER TABLE canban_tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
```

2. Проверьте консоль браузера (F12) на наличие ошибок

### Не загружаются пользователи

1. Выполните миграцию `database/add_app_source.sql`
2. Проверьте что пользователи помечены как kanban:
```sql
SELECT full_name, app_source FROM profiles;
```

### Config.js сбросился после обновления

```bash
# Восстановите из резервной копии
cp js/config.js.production js/config.js
```

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте консоль браузера (F12)
2. Проверьте логи Supabase Dashboard → Logs
3. Создайте issue на GitHub

## 📄 Лицензия

MIT License

---

**Версия:** 20
**Последнее обновление:** 2026-01-10
