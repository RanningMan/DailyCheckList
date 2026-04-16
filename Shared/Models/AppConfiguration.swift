import Foundation

struct AppConfiguration: Codable, Equatable {
    var sheetURLString: String
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var themeID: AppThemeID

    static let `default` = AppConfiguration(
        sheetURLString: "",
        remindersEnabled: false,
        reminderHour: AppConstants.defaultReminderHour,
        reminderMinute: AppConstants.defaultReminderMinute,
        themeID: .cyberpunk
    )

    init(
        sheetURLString: String,
        remindersEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        themeID: AppThemeID = .cyberpunk
    ) {
        self.sheetURLString = sheetURLString
        self.remindersEnabled = remindersEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.themeID = themeID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sheetURLString = try container.decode(String.self, forKey: .sheetURLString)
        remindersEnabled = try container.decode(Bool.self, forKey: .remindersEnabled)
        reminderHour = try container.decode(Int.self, forKey: .reminderHour)
        reminderMinute = try container.decode(Int.self, forKey: .reminderMinute)
        themeID = try container.decodeIfPresent(AppThemeID.self, forKey: .themeID) ?? .cyberpunk
    }
}
