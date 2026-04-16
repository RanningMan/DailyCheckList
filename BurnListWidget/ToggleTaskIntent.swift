import AppIntents
import WidgetKit

struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Task"
    static let openAppWhenRun = false

    @Parameter(title: "Task ID")
    var taskID: String

    @Parameter(title: "Date ID")
    var dateID: String

    init() {}

    init(taskID: String, dateID: String) {
        self.taskID = taskID
        self.dateID = dateID
    }

    func perform() async throws -> some IntentResult {
        let store = ChecklistStore()
        store.toggleTask(taskID: taskID, dateID: dateID)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
