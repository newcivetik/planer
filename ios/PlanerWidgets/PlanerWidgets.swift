import WidgetKit
import SwiftUI

// MARK: - Theme Colors

struct PlanerColors {
    static let accent = Color(red: 74/255, green: 144/255, blue: 217/255)     // #4A90D9
    static let priorityLow = Color(red: 74/255, green: 144/255, blue: 217/255)
    static let priorityMedium = Color(red: 243/255, green: 156/255, blue: 18/255)
    static let priorityHigh = Color(red: 231/255, green: 76/255, blue: 60/255)

    static func priority(_ level: Int) -> Color {
        switch level {
        case 0: return priorityLow
        case 1: return priorityMedium
        case 2: return priorityHigh
        default: return priorityMedium
        }
    }
}

// MARK: - Data Models

struct TaskItem: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let priority: Int
}

// MARK: - Timeline Provider

struct PlanerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlanerEntry {
        PlanerEntry(
            date: Date(),
            progress: 65,
            completed: 3,
            total: 5,
            tasks: [
                TaskItem(title: "Пример задачи", time: "09:00", priority: 1),
                TaskItem(title: "Ещё одна задача", time: "12:00", priority: 2),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PlanerEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlanerEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.planer.planer")

        let progress = userDefaults?.integer(forKey: "progress") ?? 0
        let completed = userDefaults?.integer(forKey: "completed") ?? 0
        let total = userDefaults?.integer(forKey: "total") ?? 0

        var tasks: [TaskItem] = []
        if let tasksJson = userDefaults?.string(forKey: "tasks"),
           let data = tasksJson.data(using: .utf8),
           let taskArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            tasks = taskArray.map { dict in
                TaskItem(
                    title: dict["title"] as? String ?? "",
                    time: dict["time"] as? String ?? "",
                    priority: dict["priority"] as? Int ?? 1
                )
            }
        }

        let entry = PlanerEntry(
            date: Date(),
            progress: progress,
            completed: completed,
            total: total,
            tasks: tasks
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct PlanerEntry: TimelineEntry {
    let date: Date
    let progress: Int
    let completed: Int
    let total: Int
    let tasks: [TaskItem]
}

// MARK: - Progress Ring Component

struct ProgressRing: View {
    let progress: Int
    let lineWidth: CGFloat
    let size: CGFloat
    let fontSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(PlanerColors.accent.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(progress) / 100)
                .stroke(
                    PlanerColors.accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            Text("\(progress)%")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Task Row Component

struct TaskRow: View {
    let task: TaskItem
    let showTime: Bool

    init(task: TaskItem, showTime: Bool = true) {
        self.task = task
        self.showTime = showTime
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(PlanerColors.priority(task.priority))
                .frame(width: 7, height: 7)
            Text(task.title)
                .font(.system(size: 13))
                .lineLimit(1)
                .foregroundColor(.primary)
            Spacer()
            if showTime && !task.time.isEmpty {
                Text(task.time)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Container Background Modifier

extension View {
    @ViewBuilder
    func widgetContainerBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                background()
            }
        } else {
            self.background {
                background()
            }
        }
    }
}

// MARK: - Small Widget (Progress Ring)

struct SmallWidgetView: View {
    let entry: PlanerEntry

    var body: some View {
        VStack(spacing: 10) {
            ProgressRing(
                progress: entry.progress,
                lineWidth: 7,
                size: 70,
                fontSize: 22
            )

            Text("\(entry.completed)/\(entry.total) задач")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContainerBackground {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    PlanerColors.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Medium Widget (Task List)

struct MediumWidgetView: View {
    let entry: PlanerEntry

    var body: some View {
        HStack(spacing: 14) {
            // Left: Progress ring
            VStack(spacing: 6) {
                ProgressRing(
                    progress: entry.progress,
                    lineWidth: 5.5,
                    size: 56,
                    fontSize: 17
                )
                Text("\(entry.completed)/\(entry.total)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(width: 74)

            // Right: Task list
            VStack(alignment: .leading, spacing: 5) {
                Text("Задачи на сегодня")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PlanerColors.accent)
                    .padding(.bottom, 1)

                if entry.tasks.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(PlanerColors.accent.opacity(0.5))
                        Text("Нет задач")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                } else {
                    ForEach(entry.tasks.prefix(4)) { task in
                        TaskRow(task: task, showTime: true)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .widgetContainerBackground {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    PlanerColors.accent.opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Large Widget (Calendar + Tasks)

struct LargeWidgetView: View {
    let entry: PlanerEntry

    private var weekDays: [(String, Int, Bool)] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today)!

        let dayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let day = calendar.component(.day, from: date)
            let isToday = calendar.isDateInToday(date)
            return (dayNames[offset], day, isToday)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with title and progress
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Планер")
                        .font(.system(size: 18, weight: .bold))
                    Text("\(entry.completed) из \(entry.total) выполнено")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                ProgressRing(
                    progress: entry.progress,
                    lineWidth: 4.5,
                    size: 44,
                    fontSize: 13
                )
            }

            // Week strip
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.1) { name, day, isToday in
                    VStack(spacing: 3) {
                        Text(name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isToday ? PlanerColors.accent : .secondary)
                        ZStack {
                            if isToday {
                                Circle()
                                    .fill(PlanerColors.accent)
                                    .frame(width: 26, height: 26)
                            }
                            Text("\(day)")
                                .font(.system(size: 12, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundColor(isToday ? .white : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Divider
            Rectangle()
                .fill(PlanerColors.accent.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 2)

            // Task section header
            Text("Задачи")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(PlanerColors.accent)

            // Task list or empty state
            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(PlanerColors.accent.opacity(0.4))
                        Text("Нет задач на сегодня")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.tasks.prefix(5)) { task in
                    TaskRow(task: task, showTime: true)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .widgetContainerBackground {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    PlanerColors.accent.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Widget Configuration

struct PlanerWidgets: Widget {
    let kind: String = "PlanerWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlanerProvider()) { entry in
            PlanerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Планер")
        .description("Прогресс задач на сегодня")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PlanerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: PlanerEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct PlanerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlanerWidgets()
    }
}
