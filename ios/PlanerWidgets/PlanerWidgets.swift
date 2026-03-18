import WidgetKit
import SwiftUI

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

// MARK: - Priority Color

func priorityColor(_ priority: Int) -> Color {
    switch priority {
    case 0: return .green
    case 1: return .orange
    case 2: return .red
    default: return .orange
    }
}

// MARK: - Small Widget (Progress Ring)

struct SmallWidgetView: View {
    let entry: PlanerEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(entry.progress) / 100)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(entry.progress)%")
                    .font(.system(size: 20, weight: .bold))
            }
            .frame(width: 60, height: 60)

            Text("\(entry.completed)/\(entry.total)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Сегодня")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Medium Widget (Task List)

struct MediumWidgetView: View {
    let entry: PlanerEntry

    var body: some View {
        HStack(spacing: 12) {
            // Progress
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.progress) / 100)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.progress)%")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(width: 50, height: 50)
                Text("\(entry.completed)/\(entry.total)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)

            // Task list
            VStack(alignment: .leading, spacing: 4) {
                Text("Задачи на сегодня")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if entry.tasks.isEmpty {
                    Text("Нет задач")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(entry.tasks.prefix(4)) { task in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(priorityColor(task.priority))
                                .frame(width: 6, height: 6)
                            Text(task.title)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            if !task.time.isEmpty {
                                Text(task.time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
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
        VStack(alignment: .leading, spacing: 8) {
            // Header with progress
            HStack {
                VStack(alignment: .leading) {
                    Text("Планер")
                        .font(.headline)
                    Text("\(entry.completed) из \(entry.total) выполнено")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.progress) / 100)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.progress)%")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(width: 40, height: 40)
            }

            // Mini calendar week
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.1) { name, day, isToday in
                    VStack(spacing: 2) {
                        Text(name)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        ZStack {
                            if isToday {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 24, height: 24)
                            }
                            Text("\(day)")
                                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? .white : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // Task list
            Text("Задачи")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if entry.tasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Нет задач на сегодня")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ForEach(entry.tasks.prefix(5)) { task in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(priorityColor(task.priority))
                            .frame(width: 8, height: 8)
                        Text(task.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        if !task.time.isEmpty {
                            Text(task.time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
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
