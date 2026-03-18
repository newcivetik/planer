# Универсальные UX-паттерны для планировщика задач

Справочник лучших практик, основанный на анализе Todoist, TickTick, Things 3, Any.do, Microsoft To Do, Apple Reminders и других успешных приложений.

---

## 1. Паттерны навигации

### 1.1 Нижняя панель вкладок (Bottom Tab Bar)

**Что это:** Горизонтальная панель внизу экрана с 3-5 основными разделами приложения.

**Почему работает:**
- **Закон Фиттса** — элементы в зоне большого пальца (thumb zone) легче нажимать одной рукой
- **Закон Хика** — 3-5 вариантов оптимальны для быстрого выбора без перегрузки
- **Эффект видимости** — постоянно видимые вкладки напоминают пользователю обо всех возможностях

**Оптимальное количество вкладок:** 4-5 (Todoist: 5, TickTick: 5, Any.do: 4)

**Типичная структура для планировщика:**
1. Сегодня / Входящие
2. Календарь
3. [FAB — кнопка добавления]
4. Проекты / Списки
5. Профиль / Настройки

**Реализация во Flutter:**
```dart
// Используйте NavigationBar (Material 3) вместо устаревшего BottomNavigationBar
NavigationBar(
  selectedIndex: _currentIndex,
  onDestinationSelected: (index) => setState(() => _currentIndex = index),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.today), label: 'Сегодня'),
    NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Календарь'),
    NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Проекты'),
    NavigationDestination(icon: Icon(Icons.person_outline), label: 'Профиль'),
  ],
)
```

**Примеры из приложений:**
- **Todoist** — 5 вкладок: Сегодня, Входящие, Поиск, Обзор, Навигация
- **TickTick** — 5 вкладок: Фокус, Привычки, Задачи, Календарь, Ещё
- **Things 3** — боковое меню (sidebar) на iPad, упрощённая навигация на iPhone

### 1.2 Кнопка быстрого добавления (FAB — Floating Action Button)

**Что это:** Круглая «плавающая» кнопка, обычно внизу справа или по центру нижней панели.

**Почему работает:**
- **Принцип заметности (Prominence)** — яркий акцентный цвет и возвышение (elevation) выделяют кнопку
- **Единственное главное действие** — одна FAB на экран, всегда означает «создать»

**Правила размещения:**
- Только одна FAB на экран
- Только для позитивных действий (создать, добавить, поделиться) — НИКОГДА для удаления
- Нижний правый угол (стандарт Material Design) или центр нижней панели (с выемкой)

**Реализация во Flutter:**
```dart
Scaffold(
  floatingActionButton: FloatingActionButton(
    onPressed: () => _showQuickAddSheet(context),
    child: const Icon(Icons.add),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  bottomNavigationBar: NavigationBar(...),
)
```

**Примеры:**
- **Todoist** — красная FAB "+" внизу справа
- **TickTick** — синяя FAB по центру нижней панели
- **Google Tasks** — голубая FAB внизу справа

---

## 2. Паттерны создания задач

### 2.1 Быстрое добавление (Quick Add) — нижний модальный лист

**Что это:** Нажатие на FAB открывает Bottom Sheet с полем ввода названия и минимальными опциями.

**Почему работает:**
- **Закон наименьшего усилия** — пользователь может создать задачу за 2 тапа (FAB + ввод + Enter)
- **Прогрессивное раскрытие (Progressive Disclosure)** — показываем сначала только название, а дату/приоритет/проект — по запросу
- **Снижение когнитивной нагрузки** — не отвлекаем от контекста, задача добавляется без ухода с текущего экрана

**Структура Quick Add:**
```
[Поле ввода названия задачи]
[Иконка: дата] [Иконка: приоритет] [Иконка: проект] [Иконка: напоминание]
                                                    [Кнопка: Отправить ->]
```

**Реализация во Flutter:**
```dart
void _showQuickAddSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // важно для клавиатуры
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: QuickAddTaskSheet(),
    ),
  );
}
```

**Примеры:**
- **Todoist** — Quick Add с парсингом естественного языка ("Купить молоко завтра в 15:00 p1")
- **TickTick** — Bottom Sheet с полем ввода и иконками быстрых опций
- **Things 3** — Inline добавление прямо в списке (поле появляется вверху)

### 2.2 Ввод на естественном языке (Natural Language Input)

**Что это:** Парсинг фраз вроде «Купить молоко завтра в 15:00» для автоматического извлечения даты, времени и контекста.

**Почему работает:**
- **Принцип соответствия ментальной модели** — пользователь думает фразами, а не заполняет формы
- **Скорость ввода** — одно предложение быстрее 4 отдельных полей

**Реализация во Flutter:**
```dart
// Пакеты для парсинга дат из текста:
// - chrono (Dart порт) или собственный парсер
// - nlp_date_parser (если доступен)
// - Интеграция с серверным NLP (GPT API / Dialogflow)

// Базовый подход — регулярные выражения:
final regexTomorrow = RegExp(r'завтра', caseSensitive: false);
final regexTime = RegExp(r'в (\d{1,2}):?(\d{2})?');
```

**Примеры:**
- **Todoist** — лидер в NLP для задач; распознаёт даты, приоритеты, метки, проекты
- **TickTick** — парсит даты и время из текста задачи
- **Any.do** — базовый парсинг дат

### 2.3 Inline-создание в списке

**Что это:** Поле ввода появляется прямо в списке задач (обычно сверху или снизу).

**Почему работает:**
- **Принцип близости (Proximity)** — создание задачи в том же контексте, где она будет отображаться
- **Нулевое переключение контекста** — не нужно переходить на другой экран

**Реализация во Flutter:**
```dart
// В SliverList или ListView добавить первым/последним элементом:
TextField(
  decoration: InputDecoration(
    hintText: '+ Добавить задачу',
    border: InputBorder.none,
    prefixIcon: Icon(Icons.add, color: Colors.grey),
  ),
  onSubmitted: (value) => _createTask(value),
)
```

**Примеры:**
- **Things 3** — inline ввод в начале каждого списка
- **Microsoft To Do** — поле "Добавить задачу" внизу списка
- **Apple Reminders** — inline ввод

---

## 3. Паттерны отображения задач

### 3.1 Формат списка (List View)

**Что это:** Вертикальный список задач с checkbox, названием и метаданными.

**Почему работает:**
- **Сканирование по F-паттерну** — глаз движется сверху вниз по левому краю; чекбокс слева, текст справа
- **Высокая информационная плотность** — больше задач на экране = лучший обзор дня
- **Привычность** — бумажный список дел существует сотни лет

**Структура элемента списка:**
```
[Checkbox] [Название задачи]                    [Дата/Приоритет]
           [Проект • Метки • Подзадачи]
```

**Реализация во Flutter:**
```dart
ListTile(
  leading: Checkbox(
    value: task.isCompleted,
    onChanged: (v) => _toggleTask(task),
    shape: const CircleBorder(), // круглый чекбокс как в Todoist
  ),
  title: Text(task.title),
  subtitle: Text('${task.project} • ${task.tags.join(", ")}'),
  trailing: _buildPriorityIndicator(task.priority),
)
```

### 3.2 Формат карточек (Card View)

**Что это:** Каждая задача в отдельной карточке с тенью и скруглёнными углами.

**Почему работает:**
- **Гештальт-принцип замкнутости** — карточка визуально группирует связанную информацию
- **Иерархия глубиной (Elevation)** — тени создают ощущение слоёв и интерактивности

**Реализация во Flutter:**
```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [checkbox, title]),
        const SizedBox(height: 8),
        Row(children: [dateBadge, priorityBadge, projectBadge]),
      ],
    ),
  ),
)
```

### 3.3 Группировка задач

**Что это:** Логическое разделение задач на секции.

**Почему работает:**
- **Гештальт-принцип группировки** — мозг легче обрабатывает категоризированную информацию
- **Снижение когнитивной нагрузки** — вместо 50 задач подряд — 5 групп по 10

**Типы группировки:**
| Тип | Когда использовать | Пример |
|-----|-------------------|--------|
| По дате | Экран "Сегодня" / "Предстоящие" | Сегодня, Завтра, На этой неделе |
| По приоритету | Фильтр приоритетов | Срочные, Высокие, Средние, Низкие |
| По проекту | Общий вид | Работа, Дом, Покупки |
| По меткам | Поиск/фильтр | #срочно, #звонки, #идеи |

**Реализация во Flutter:**
```dart
// SliverList + SliverStickyHeader (пакет: sliver_tools)
// или CustomScrollView с заголовками секций
CustomScrollView(
  slivers: [
    for (final group in groupedTasks.entries) ...[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(group.key, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => TaskTile(task: group.value[index]),
          childCount: group.value.length,
        ),
      ),
    ],
  ],
)
```

### 3.4 Цветовое кодирование

**Что это:** Использование цвета для визуальной категоризации.

**Приоритеты (стандарт de facto):**
| Приоритет | Цвет | Пример (Todoist) |
|-----------|-------|------------------|
| P1 — Критичный | Красный (#FF4444) | Красный флажок |
| P2 — Высокий | Оранжевый (#FF8C00) | Оранжевый флажок |
| P3 — Средний | Синий (#4488FF) | Голубой флажок |
| P4 — Низкий | Серый / без цвета | Без флажка |

**Цвета проектов:** Todoist предлагает палитру из ~20 цветов на выбор пользователя для каждого проекта.

**Почему работает:**
- **Предвнимательная обработка (Pre-attentive processing)** — цвет воспринимается мозгом до осознанного анализа (за 200мс)
- **Ассоциативная память** — красный = срочно (из светофора/знаков)

---

## 4. Паттерны завершения задач

### 4.1 Анимация чекбокса

**Что это:** Визуальная обратная связь при нажатии на чекбокс.

**Почему работает:**
- **Оперантное обусловливание (Скиннер)** — мгновенное вознаграждение закрепляет поведение
- **Эффект завершения (Zeigarnik)** — завершённая задача снижает когнитивное напряжение

**Типы анимаций:**
1. **Круглый чекбокс с заливкой** — круг заполняется цветом приоритета (Todoist)
2. **Галочка с пружинным эффектом** — чекмарк появляется с bounce-анимацией
3. **Зачёркивание текста** — текст задачи зачёркивается слева направо
4. **Исчезновение элемента** — задача плавно уменьшается и исчезает (через 1-2 сек.)

**Реализация во Flutter:**
```dart
// Анимированный чекбокс
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutBack, // пружинный эффект
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: isCompleted ? priorityColor : Colors.transparent,
    border: Border.all(color: priorityColor, width: 2),
  ),
  child: isCompleted
    ? const Icon(Icons.check, size: 16, color: Colors.white)
    : null,
)

// Зачёркивание текста
Text(
  task.title,
  style: TextStyle(
    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
    color: task.isCompleted ? Colors.grey : Colors.black,
  ),
)

// Удаление из списка с анимацией — пакет: flutter_slidable
// или AnimatedList с SlideTransition / FadeTransition
```

### 4.2 Праздничные микро-взаимодействия (Celebration)

**Что это:** Визуальные/тактильные награды за продуктивные действия.

**Почему работает:**
- **Дофаминовый цикл** — неожиданная награда усиливает мотивацию больше, чем ожидаемая
- **Переменное подкрепление (Variable Ratio Schedule)** — случайные награды формируют самую устойчивую привычку

**Типы наград:**
| Тип | Когда | Пример |
|-----|-------|--------|
| Хаптик (вибрация) | Каждое завершение | Лёгкая вибрация при тапе |
| Конфетти | Все задачи дня завершены | Confetti-анимация по экрану |
| Звук | Каждое завершение (опционально) | Мягкий "тинк" |
| Юникорн | Случайно | Asana: единорог пролетает по экрану |
| Мотивационная фраза | Inbox Zero | "Отлично! Все задачи выполнены!" |

**Реализация во Flutter:**
```dart
// Пакет: confetti_widget
ConfettiWidget(
  confettiController: _confettiController,
  blastDirectionality: BlastDirectionality.explosive,
  shouldLoop: false,
  numberOfParticles: 30,
  emissionFrequency: 0.05,
)

// Хаптик: пакет haptic_feedback или HapticFeedback из flutter/services
import 'package:flutter/services.dart';
HapticFeedback.lightImpact();

// Звук: audioplayers
final player = AudioPlayer();
await player.play(AssetSource('sounds/complete.mp3'));
```

**Примеры:**
- **Asana** — единороги, нарвалы и прочие существа случайно пролетают при завершении задач
- **Todoist** — конфетти при достижении ежедневной цели (Karma)
- **Forest** — дерево вырастает при завершении фокус-сессии

### 4.3 Поддержка отмены (Undo)

**Что это:** Snackbar с кнопкой «Отменить» после завершения/удаления задачи.

**Почему работает:**
- **Безопасный выход (Safe Exit)** — пользователь не боится нажимать, зная что можно отменить
- **Закон Хика** — не нужен диалог подтверждения «Вы уверены?», что ускоряет работу

**Реализация во Flutter:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Задача завершена'),
    action: SnackBarAction(
      label: 'ОТМЕНИТЬ',
      onPressed: () => _undoComplete(task),
    ),
    duration: const Duration(seconds: 5),
    behavior: SnackBarBehavior.floating,
  ),
);
```

---

## 5. Паттерны пустого состояния (Empty States)

### 5.1 Мотивационные пустые состояния

**Что это:** Экран, который появляется когда список задач пуст.

**Почему работает:**
- **Эффект пустого холста** — пустота вызывает тревогу; иллюстрация и текст снимают её
- **Призыв к действию (CTA)** — кнопка «Добавить первую задачу» снижает трение нулевого шага
- **Положительное подкрепление** — фраза «Все задачи выполнены!» вознаграждает за продуктивность

**Два типа пустых состояний:**

**Тип 1 — Первый запуск (Onboarding):**
```
[Иллюстрация: рабочее место / чекбоксы]
"Начните с первой задачи"
"Нажмите +, чтобы добавить задачу"
[Кнопка: Добавить задачу]
```

**Тип 2 — Inbox Zero (Все задачи выполнены):**
```
[Иллюстрация: пляж / отдых / счастливый персонаж]
"Отлично! На сегодня всё!"
"Наслаждайтесь свободным временем"
```

**Реализация во Flutter:**
```dart
if (tasks.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lottie-анимация или SVG иллюстрация
        Lottie.asset('assets/animations/empty_inbox.json', width: 200),
        const SizedBox(height: 24),
        Text(
          isFirstRun ? 'Добро пожаловать!' : 'Всё выполнено!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isFirstRun
            ? 'Создайте свою первую задачу'
            : 'Наслаждайтесь свободным временем',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        if (isFirstRun) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showQuickAddSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Добавить задачу'),
          ),
        ],
      ],
    ),
  );
}
```

**Пакеты:**
- `lottie` — для анимированных иллюстраций (бесплатные анимации на LottieFiles.com)
- `flutter_svg` — для статичных SVG-иллюстраций (unDraw.co, Storyset.com)

**Примеры:**
- **Todoist** — иллюстрация с текстом "Наслаждайтесь свободным днём" при пустом Inbox
- **Things 3** — минималистичный текст без иллюстрации
- **Microsoft To Do** — яркие иллюстрации, разные для каждого списка

---

## 6. Паттерны прогресса и статистики

### 6.1 Кольца прогресса (Progress Rings)

**Что это:** Круговая диаграмма, показывающая процент выполнения дневной цели.

**Почему работает:**
- **Эффект близости к цели (Goal Gradient Effect)** — чем ближе кольцо к замыканию, тем сильнее мотивация закончить
- **Визуализация прогресса** — абстрактная «продуктивность» становится осязаемой
- **Якорь Apple Watch** — пользователи уже привыкли к кольцам активности

**Реализация во Flutter:**
```dart
// Пакет: percent_indicator или syncfusion_flutter_gauges
CircularPercentIndicator(
  radius: 60,
  lineWidth: 8,
  percent: completedTasks / totalTasks,
  center: Text('${(completedTasks / totalTasks * 100).round()}%'),
  progressColor: Theme.of(context).colorScheme.primary,
  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
  circularStrokeCap: CircularStrokeCap.round,
  animation: true,
  animationDuration: 800,
)
```

### 6.2 Серии (Streaks)

**Что это:** Счётчик последовательных дней выполнения задач.

**Почему работает:**
- **Эффект невозвратных затрат (Sunk Cost)** — чем длиннее серия, тем больнее её прервать
- **Визуальная цепочка (Don't Break the Chain, метод Сайнфелда)** — видимая серия мотивирует продолжать
- **Социальное сравнение** — серии можно делить с друзьями

**Реализация во Flutter:**
```dart
// Компонент отображения серии
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
    const SizedBox(width: 4),
    Text(
      '$streakDays',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    const SizedBox(width: 4),
    Text('дн.', style: TextStyle(color: Colors.grey[600])),
  ],
)

// Тепловая карта активности (как на GitHub)
// Пакет: flutter_heatmap_calendar
```

### 6.3 Панель статистики (Stats Dashboard)

**Что это:** Экран с графиками и числовыми показателями продуктивности.

**Метрики для отображения:**
| Метрика | Визуализация | Психологический эффект |
|---------|-------------|----------------------|
| Задач выполнено сегодня | Число + кольцо прогресса | Немедленная обратная связь |
| Задач выполнено за неделю | Столбчатая диаграмма по дням | Тренды и паттерны |
| Текущая серия | Число + огонёк | Невозвратные затраты |
| Самый продуктивный день | Текст | Самопознание |
| Распределение по проектам | Круговая диаграмма | Баланс жизни |

**Реализация во Flutter:**
```dart
// Пакет: fl_chart (лучший для Flutter)
BarChart(
  BarChartData(
    barGroups: weekData.map((day) => BarChartGroupData(
      x: day.weekday,
      barRods: [
        BarChartRodData(toY: day.completedTasks.toDouble(), color: primaryColor),
      ],
    )).toList(),
  ),
)

// Альтернативы: syncfusion_flutter_charts, graphic
```

**Примеры:**
- **Todoist** — Karma-система с баллами, уровнями и графиком продуктивности
- **TickTick** — подробная статистика с тепловой картой, графиками по неделям
- **Habitica** — полная RPG-система с уровнями, золотом и экипировкой

---

## 7. Паттерны цвета и темы

### 7.1 Тёмный / Светлый режим

**Что это:** Два визуальных режима с переключением.

**Почему работает:**
- **Снижение усталости глаз** — тёмный режим при низком освещении
- **Экономия батареи** — на OLED экранах тёмные пиксели выключены
- **Персонализация** — выбор создаёт чувство контроля

**Ключевые правила тёмной темы:**
- Фон НЕ чисто чёрный (#000000), а тёмно-серый (#121212)
- Текст НЕ чисто белый (#FFFFFF), а слегка приглушённый (#E0E0E0)
- Акцентные цвета — десатурированные версии светлой темы
- Контраст текст/фон минимум 4.5:1
- Тени заменяются на осветление поверхностей (elevation overlay)

**Реализация во Flutter:**
```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system, // следует системным настройкам
)
```

### 7.2 Система цветов категорий

**Что это:** Палитра цветов для проектов/меток, выбираемая пользователем.

**Почему работает:**
- **Предвнимательная обработка** — цвет считывается за 200мс, быстрее текста
- **Пространственная память** — «красный проект = работа» запоминается автоматически

**Рекомендуемая палитра (12-20 цветов):**
```dart
static const List<Color> projectColors = [
  Color(0xFFE53935), // Красный
  Color(0xFFFF7043), // Оранжевый
  Color(0xFFFFA726), // Жёлтый
  Color(0xFF66BB6A), // Зелёный
  Color(0xFF26A69A), // Бирюзовый
  Color(0xFF42A5F5), // Голубой
  Color(0xFF5C6BC0), // Индиго
  Color(0xFFAB47BC), // Фиолетовый
  Color(0xFFEC407A), // Розовый
  Color(0xFF8D6E63), // Коричневый
  Color(0xFF78909C), // Серо-голубой
  Color(0xFF9E9E9E), // Серый
];
```

### 7.3 Кастомизация акцентного цвета

**Что это:** Пользователь выбирает основной акцентный цвет приложения.

**Почему работает:**
- **Эффект владения (Endowment Effect)** — персонализированное приложение ценнее «стандартного»
- **IKEA-эффект** — вложенное усилие повышает привязанность

**Реализация во Flutter:**
```dart
// ColorScheme.fromSeed автоматически генерирует всю палитру из одного цвета
ColorScheme.fromSeed(
  seedColor: userSelectedColor, // один цвет от пользователя
  brightness: Brightness.light,
)
// Результат: primary, secondary, tertiary, surface, background и т.д.
// Всё гармонично, не нужно подбирать вручную
```

**Примеры:**
- **Todoist** — ~10 тем на выбор (красная, оранжевая, голубая, фиолетовая и т.д.)
- **TickTick** — кастомизация темы и акцентного цвета
- **Microsoft To Do** — фоновые изображения для каждого списка

---

## 8. Паттерны анимаций и жестов

### 8.1 Свайп-жесты (Swipe Actions)

**Что это:** Горизонтальный свайп по задаче для быстрых действий.

**Почему работает:**
- **Прямое манипулирование (Direct Manipulation)** — действие физически связано с объектом
- **Скорость** — быстрее, чем открыть меню и выбрать действие
- **Тактильная обратная связь** — движение пальца = совершённое действие

**Стандартная конфигурация:**
| Направление | Короткий свайп | Длинный свайп |
|-------------|----------------|---------------|
| Вправо | Завершить задачу | Завершить задачу |
| Влево | Перенести на завтра | Удалить |

**Реализация во Flutter:**
```dart
// Пакет: flutter_slidable (лучший для свайпов)
Slidable(
  startActionPane: ActionPane(
    motion: const BehindMotion(),
    children: [
      SlidableAction(
        onPressed: (_) => _completeTask(task),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: Icons.check,
        label: 'Готово',
      ),
    ],
  ),
  endActionPane: ActionPane(
    motion: const BehindMotion(),
    children: [
      SlidableAction(
        onPressed: (_) => _scheduleTask(task),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: Icons.calendar_today,
        label: 'Завтра',
      ),
      SlidableAction(
        onPressed: (_) => _deleteTask(task),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: Icons.delete,
        label: 'Удалить',
      ),
    ],
  ),
  child: TaskTile(task: task),
)
```

**Примеры:**
- **Todoist** — настраиваемые свайпы (завершить, перенести, удалить, напомнить)
- **TickTick** — 4 настраиваемых свайп-действия (короткий/длинный, лево/право)
- **Apple Mail** — эталонный свайп-интерфейс (архивировать, пометить, удалить)

### 8.2 Анимации появления списка (Staggered Animation)

**Что это:** Элементы списка появляются последовательно с задержкой (обычно 50-100мс между элементами).

**Почему работает:**
- **Принцип последовательности** — направляет внимание пользователя сверху вниз
- **Восприятие скорости** — анимированный список кажется быстрее, чем мгновенное появление
- **Полировка** — создаёт ощущение «дорогого» приложения

**Реализация во Flutter:**
```dart
// Подход через AnimationController + Interval
class StaggeredListAnimation extends StatefulWidget { ... }

// Или пакет: flutter_staggered_animations
AnimationConfiguration.staggeredList(
  position: index,
  duration: const Duration(milliseconds: 375),
  child: SlideAnimation(
    verticalOffset: 50.0,
    child: FadeInAnimation(child: TaskTile(task: task)),
  ),
)
```

### 8.3 Переходы между экранами

**Что это:** Анимация при навигации между страницами.

**Рекомендуемые длительности:**
- Простые переходы: 200-300мс
- Сложные переходы: 300-500мс
- Микро-анимации: 100-200мс

**Реализация во Flutter:**
```dart
// Hero-анимация для задачи (из списка в детали)
Hero(
  tag: 'task_${task.id}',
  child: TaskTile(task: task),
)

// Shared Element Transition (Flutter 3.x)
// Или пакет: animations (от Flutter team)
// OpenContainer — карточка раскрывается в полноэкранный вид
OpenContainer(
  closedBuilder: (context, action) => TaskCard(task: task, onTap: action),
  openBuilder: (context, action) => TaskDetailPage(task: task),
  closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
)
```

### 8.4 Pull-to-Refresh

**Что это:** Потянуть список вниз для обновления.

**Реализация во Flutter:**
```dart
RefreshIndicator(
  onRefresh: () async => await _refreshTasks(),
  child: ListView(...),
)
```

---

## 9. Паттерны премиального ощущения

### 9.1 Типографика

**Что это:** Выбор шрифтов, определяющий «характер» приложения.

**Почему работает:**
- **Эффект эстетики-юзабилити** — красивые интерфейсы воспринимаются как более удобные
- **Визуальная иерархия** — размеры и начертания шрифтов направляют внимание

**Рекомендации:**
| Элемент | Размер | Начертание | Пример шрифта |
|---------|--------|-----------|---------------|
| Заголовок экрана | 28-32sp | Bold/SemiBold | Inter, SF Pro |
| Заголовок секции | 18-20sp | SemiBold | Inter, SF Pro |
| Название задачи | 16sp | Regular/Medium | Inter, SF Pro |
| Метаданные | 12-14sp | Regular | Inter, SF Pro |

**Премиальные шрифты для Flutter:**
```dart
// google_fonts пакет
import 'package:google_fonts/google_fonts.dart';

ThemeData(
  textTheme: GoogleFonts.interTextTheme(), // чистый, современный
  // или GoogleFonts.nunitoTextTheme()     // мягкий, дружелюбный
  // или GoogleFonts.poppinsTextTheme()     // геометрический, стильный
)
```

### 9.2 Пространство и отступы

**Что это:** Система последовательных отступов (spacing system).

**Почему работает:**
- **Закон Прагнанца** — мозг предпочитает простые, упорядоченные формы
- **Воздух = роскошь** — больше пустого пространства = ощущение качества (аналогия с luxury-брендами)

**Система отступов (кратно 4 или 8):**
```dart
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

### 9.3 Тени и глубина

**Что это:** Система elevation для создания визуальных слоёв.

**Реализация во Flutter:**
```dart
// Material 3 автоматически управляет elevation
// Для карточек задач: elevation 0-1 (минимализм)
// Для FAB: elevation 6
// Для модальных листов: elevation 3

// Кастомная тень для "дорогого" вида:
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  ),
)
```

### 9.4 Glassmorphism / Размытие

**Что это:** Полупрозрачные элементы с размытым фоном (эффект матового стекла).

**Почему работает:**
- **Глубина и слоистость** — создаёт 3D-ощущение без скевоморфизма
- **Контекст** — размытый контент под панелью напоминает о том, что за ней
- **Премиальность** — ассоциируется с iOS / Apple Design

**Где применять:** AppBar, нижняя панель, модальные листы, карточки.

**Реализация во Flutter:**
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: content,
    ),
  ),
)

// ВАЖНО: blur дорогой по производительности!
// Использовать ограниченно — только на статичных элементах
// Всегда оборачивать в ClipRRect для ограничения зоны перерисовки
```

### 9.5 Кастомные иллюстрации

**Что это:** Уникальные иллюстрации для пустых состояний, онбординга и достижений.

**Бесплатные ресурсы:**
- **unDraw.co** — SVG-иллюстрации с кастомизацией цвета
- **Storyset.com** — анимированные иллюстрации
- **LottieFiles.com** — Lottie-анимации (JSON-формат, идеально для Flutter)
- **Icons8 Ouch** — стильные иллюстрации

---

## 10. Паттерны доступности (Accessibility)

### 10.1 Масштабирование шрифтов

**Что это:** Поддержка системных настроек размера текста.

**Почему важно:**
- ~15% пользователей меняют размер текста в системных настройках
- Юридические требования (WCAG 2.2, ADA, EAA)

**Реализация во Flutter:**
```dart
// Flutter автоматически масштабирует Text через MediaQuery.textScaleFactor
// НО нужно ограничить максимальный масштаб для сохранения layout:
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(
      MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.5),
    ),
  ),
  child: child,
)

// Используйте sp (не dp) для шрифтов — они уже масштабируемые в Flutter
```

### 10.2 Контрастность

**Что это:** Достаточная разница между текстом и фоном.

**Минимальные коэффициенты (WCAG AA):**
- Обычный текст (< 18sp): 4.5:1
- Крупный текст (>= 18sp bold или >= 24sp): 3:1
- Интерактивные элементы: 3:1

**Реализация во Flutter:**
```dart
// Material 3 ColorScheme автоматически обеспечивает контрастность:
// colorScheme.onSurface для текста на surface
// colorScheme.onPrimary для текста на primary
// Всегда используйте on* цвета для текста!

Text(
  'Текст задачи',
  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
)
```

### 10.3 Поддержка Screen Reader (VoiceOver / TalkBack)

**Что это:** Озвучивание элементов интерфейса для слабовидящих.

**Реализация во Flutter:**
```dart
// Semantics — ключевой виджет для accessibility
Semantics(
  label: 'Задача: ${task.title}',
  hint: task.isCompleted ? 'Выполнена' : 'Двойное нажатие для завершения',
  checked: task.isCompleted,
  child: TaskTile(task: task),
)

// Для чекбокса:
Semantics(
  label: 'Отметить задачу как выполненную',
  child: Checkbox(value: task.isCompleted, onChanged: ...),
)

// Для свайпов — обязательно альтернативный доступ:
// Кнопки в контекстном меню (long press) для тех, кто не может свайпать
```

### 10.4 Размеры тач-целей

**Что это:** Минимальный размер интерактивных элементов.

**Стандарты:**
- Apple: минимум 44x44 pt
- Google: минимум 48x48 dp
- WCAG 2.2: минимум 24x24 CSS px (уровень AA), 44x44 (AAA)

**Реализация во Flutter:**
```dart
// Material 3 автоматически обеспечивает 48dp для большинства виджетов
// Для кастомных элементов:
SizedBox(
  width: 48,
  height: 48,
  child: InkWell(
    onTap: () => ...,
    borderRadius: BorderRadius.circular(24),
    child: const Icon(Icons.more_vert, size: 24),
  ),
)
```

---

## Сводная таблица: что берём из каждого приложения

| Приложение | Сильная сторона | Что заимствовать |
|------------|----------------|------------------|
| **Todoist** | NLP-ввод, кросс-платформенность, Karma | Quick Add с парсингом языка, система серий |
| **Things 3** | Идеальный дизайн, простота | Whitespace, типографика, минимализм |
| **TickTick** | Всё-в-одном (задачи + привычки + Pomodoro) | Свайп-настройки, тепловая карта |
| **Any.do** | Красивый дизайн, планирование дня | Morning routine — обзор дня утром |
| **Microsoft To Do** | Интеграция, My Day | Концепция "Мой день" — ежедневный фокус-список |
| **Apple Reminders** | Нативность, простота | Группировка по смарт-спискам |
| **Habitica** | Геймификация | RPG-элементы для мотивации |
| **Forest** | Фокус-таймер | Визуальная метафора для фокус-режима |

---

## Приоритеты реализации

### Фаза 1 — Must Have (MVP):
1. Нижняя навигация с 4-5 вкладками
2. FAB для Quick Add (bottom sheet)
3. Список задач с чекбоксами и группировкой по дате
4. Свайп-жесты (завершить, удалить)
5. Тёмная/светлая тема (ThemeMode.system)
6. Анимация чекбокса + зачёркивание
7. Undo через Snackbar
8. Пустые состояния с иллюстрациями

### Фаза 2 — Should Have:
1. Цветовое кодирование проектов и приоритетов
2. Staggered-анимации списков
3. Кастомизация акцентного цвета
4. Кольцо прогресса на экране "Сегодня"
5. Базовая статистика (задач за день/неделю)
6. Hero-анимации переходов
7. Accessibility (Semantics, тач-цели)

### Фаза 3 — Nice to Have:
1. NLP-парсинг естественного языка
2. Серии (streaks) + тепловая карта
3. Конфетти/празднование при выполнении всех задач
4. Glassmorphism-элементы
5. Расширенная статистика с графиками
6. Хаптик-обратная связь
7. Звуки завершения
8. Кастомные Lottie-анимации

---

*Документ создан на основе анализа лучших практик UX-дизайна 2025-2026 и реальных примеров из ведущих приложений для управления задачами.*
