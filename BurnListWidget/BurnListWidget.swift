import AppIntents
import WidgetKit
import SwiftUI

struct DailyChecklistEntry: TimelineEntry {
    let date: Date
    let tasks: [DailyTask]
    let lastUpdated: Date?
    let lastErrorMessage: String?
    let theme: AppTheme
}

struct DailyChecklistProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyChecklistEntry {
        let theme = loadTheme()
        return DailyChecklistEntry(
            date: .now,
            tasks: [
                DailyTask(dateID: DateFormatting.dayID(from: .now), taskID: "dsa-30m-day", title: "DSA (30m/day)", sortOrder: 0, isCompleted: false),
                DailyTask(dateID: DateFormatting.dayID(from: .now), taskID: "fe-coding-30m-day", title: "FE coding (30m/day)", sortOrder: 1, isCompleted: true)
            ],
            lastUpdated: .now,
            lastErrorMessage: nil,
            theme: theme
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyChecklistEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyChecklistEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(for: now)
        let nextRefresh = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry(for date: Date) -> DailyChecklistEntry {
        let store = ChecklistStore()
        let dateID = DateFormatting.dayID(from: date)
        let snapshot = store.loadSnapshot()
        let shouldShowSnapshotState = snapshot?.dateID == dateID

        return DailyChecklistEntry(
            date: date,
            tasks: store.loadTasks(for: dateID),
            lastUpdated: shouldShowSnapshotState ? snapshot?.refreshedAt : nil,
            lastErrorMessage: shouldShowSnapshotState ? snapshot?.lastErrorMessage : nil,
            theme: loadTheme()
        )
    }

    private func loadTheme() -> AppTheme {
        ChecklistStore().loadConfiguration().themeID.theme
    }
}

struct DailyChecklistWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: DailyChecklistProvider.Entry

    private var theme: AppTheme { entry.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.date, format: .dateTime.weekday(.abbreviated).month().day())
                .font(AppTheme.monoFont(.headline, weight: .bold))
                .foregroundStyle(theme.accent)

            if entry.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No tasks today")
                        .font(AppTheme.monoFont(.subheadline, weight: .medium))
                        .foregroundStyle(theme.textPrimary)
                    Text("Open the app to refresh.")
                        .font(AppTheme.monoFont(.caption2))
                        .foregroundStyle(theme.textSecondary)
                }
            } else {
                ForEach(Array(entry.tasks.prefix(maxTasks).enumerated()), id: \.element.id) { _, task in
                    Button(intent: ToggleTaskIntent(taskID: task.taskID, dateID: task.dateID)) {
                        HStack(spacing: 8) {
                            Image(systemName: task.isCompleted ? "flame.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? theme.completedAccent : theme.dimAccent)
                                .shadow(color: task.isCompleted ? theme.completedAccent.opacity(0.5) : .clear, radius: 4)
                            Text(task.title)
                                .font(AppTheme.monoFont(.caption))
                                .foregroundStyle(task.isCompleted ? theme.completedAccent.opacity(0.5) : theme.textPrimary)
                                .strikethrough(task.isCompleted, color: theme.completedAccent.opacity(0.4))
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if entry.tasks.count > maxTasks {
                    Text("+\(entry.tasks.count - maxTasks) more in app")
                        .font(AppTheme.monoFont(.caption2))
                        .foregroundStyle(theme.textSecondary)
                }
            }

            if entry.lastErrorMessage != nil {
                Text("Using cached tasks")
                    .font(AppTheme.monoFont(.caption2))
                    .foregroundStyle(theme.completedAccent.opacity(0.6))
            }
        }
        .containerBackground(theme.cardBackground, for: .widget)
        .widgetURL(URL(string: "dailychecklist://today"))
    }

    private var maxTasks: Int {
        switch family {
        case .systemSmall:
            3
        case .systemMedium:
            6
        default:
            10
        }
    }
}

@main
struct BurnListWidget: Widget {
    let kind: String = AppConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyChecklistProvider()) { entry in
            DailyChecklistWidgetView(entry: entry)
        }
        .configurationDisplayName("BURNLIST")
        .description("Your daily ops. Burn through them.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
