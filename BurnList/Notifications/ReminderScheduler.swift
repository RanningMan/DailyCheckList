import Foundation
import UserNotifications

@MainActor
protocol ReminderScheduling {
    func requestAuthorization() async throws
    func scheduleDailyReminder(hour: Int, minute: Int) async throws
    func cancelReminder() async
}

enum ReminderSchedulerError: LocalizedError {
    case authorizationDenied

    var errorDescription: String? {
        "Notification permission was not granted."
    }
}

@MainActor
struct ReminderScheduler: ReminderScheduling {
    nonisolated(unsafe) private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        if !granted {
            throw ReminderSchedulerError.authorizationDenied
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        await cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "BURNLIST"
        content.body = "Your tasks are waiting. Burn through them."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.reminderRequestIdentifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func cancelReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.reminderRequestIdentifier])
    }
}
