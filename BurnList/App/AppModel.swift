import Foundation
import WidgetKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var tasks: [DailyTask] = []
    @Published private(set) var historyEntries: [(dateID: String, tasks: [DailyTask])] = []
    @Published private(set) var syncStatusText = "Add your published Google Sheet URL in Settings."
    @Published private(set) var isRefreshing = false
    @Published var configuration: AppConfiguration

    private let store: ChecklistStore
    private let syncService: TaskSyncService
    private let reminderScheduler: ReminderScheduling

    init(
        store: ChecklistStore = ChecklistStore(),
        syncService: TaskSyncService? = nil,
        reminderScheduler: ReminderScheduling = ReminderScheduler()
    ) {
        self.store = store
        self.syncService = syncService ?? TaskSyncService(store: store)
        self.reminderScheduler = reminderScheduler
        configuration = store.loadConfiguration()
        reloadFromStore()
    }

    var activeTheme: AppTheme {
        configuration.themeID.theme
    }

    func setTheme(_ themeID: AppThemeID) {
        configuration.themeID = themeID
        store.saveConfiguration(configuration)
    }

    var reminderDate: Date {
        let components = DateComponents(hour: configuration.reminderHour, minute: configuration.reminderMinute)
        return Calendar.current.date(from: components) ?? .now
    }

    func refreshIfConfigured() async {
        let trimmedURL = configuration.sheetURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            reloadFromStore()
            return
        }

        await refresh()
    }

    func refresh() async {
        isRefreshing = true
        store.saveConfiguration(configuration)
        let snapshot = await syncService.refreshPreservingCache(configuration: configuration)
        apply(snapshot: snapshot)
        isRefreshing = false
        WidgetCenter.shared.reloadAllTimelines()
    }

    func toggle(_ task: DailyTask) {
        store.toggleTask(taskID: task.taskID, dateID: task.dateID)
        reloadFromStore(dateID: task.dateID)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func saveSheetURL(_ sheetURLString: String) {
        configuration.sheetURLString = sheetURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        store.saveConfiguration(configuration)
        reloadFromStore()
    }

    func setRemindersEnabled(_ isEnabled: Bool) async {
        configuration.remindersEnabled = isEnabled
        await persistReminderPreferences()
    }

    func setReminderTime(_ date: Date) async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        configuration.reminderHour = components.hour ?? AppConstants.defaultReminderHour
        configuration.reminderMinute = components.minute ?? AppConstants.defaultReminderMinute
        await persistReminderPreferences()
    }

    func reloadFromStore(now: Date = .now) {
        reloadFromStore(dateID: DateFormatting.dayID(from: now))
    }

    private func reloadFromStore(dateID: String) {
        tasks = store.loadTasks(for: dateID)
        historyEntries = store.loadHistoryEntries().filter { $0.dateID < dateID }
        syncStatusText = statusText(for: store.loadSnapshot(), currentDateID: dateID)
    }

    private func apply(snapshot: DailyChecklistSnapshot) {
        tasks = store.loadTasks(for: snapshot.dateID)
        historyEntries = store.loadHistoryEntries().filter { $0.dateID < snapshot.dateID }
        syncStatusText = statusText(for: snapshot, currentDateID: snapshot.dateID)
    }

    private func persistReminderPreferences() async {
        store.saveConfiguration(configuration)

        do {
            if configuration.remindersEnabled {
                try await reminderScheduler.requestAuthorization()
                try await reminderScheduler.scheduleDailyReminder(
                    hour: configuration.reminderHour,
                    minute: configuration.reminderMinute
                )
            } else {
                await reminderScheduler.cancelReminder()
            }
        } catch {
            configuration.remindersEnabled = false
            store.saveConfiguration(configuration)
            syncStatusText = "Reminder error: \(error.localizedDescription)"
            return
        }

        syncStatusText = statusText(for: store.loadSnapshot(), currentDateID: DateFormatting.dayID(from: .now))
    }

    private func statusText(for snapshot: DailyChecklistSnapshot?, currentDateID: String) -> String {
        guard let snapshot else {
            return configuration.sheetURLString.isEmpty
                ? "Add your published Google Sheet URL in Settings."
                : "No checklist cached yet. Pull to refresh."
        }

        let updatedAt = DateFormatter.localizedString(from: snapshot.refreshedAt, dateStyle: .none, timeStyle: .short)
        if let lastErrorMessage = snapshot.lastErrorMessage {
            return "Last refresh \(updatedAt). Using cached tasks. \(lastErrorMessage)"
        }

        if snapshot.dateID == currentDateID, snapshot.tasks.isEmpty {
            return "Updated \(updatedAt). No tasks are planned for today."
        }

        return "Updated \(updatedAt)."
    }
}
