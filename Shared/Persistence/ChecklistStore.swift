import Foundation

final class ChecklistStore {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard) {
        self.userDefaults = userDefaults
    }

    func loadConfiguration() -> AppConfiguration {
        guard
            let data = userDefaults.data(forKey: AppConstants.configurationKey),
            let configuration = try? decoder.decode(AppConfiguration.self, from: data)
        else {
            return .default
        }

        return configuration
    }

    func saveConfiguration(_ configuration: AppConfiguration) {
        guard let data = try? encoder.encode(configuration) else {
            return
        }

        userDefaults.set(data, forKey: AppConstants.configurationKey)
    }

    func loadSnapshot() -> DailyChecklistSnapshot? {
        guard
            let data = userDefaults.data(forKey: AppConstants.snapshotKey),
            let snapshot = try? decoder.decode(DailyChecklistSnapshot.self, from: data)
        else {
            return nil
        }

        return snapshot
    }

    func saveSnapshot(_ snapshot: DailyChecklistSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        clearStaleCompletionData(keeping: snapshot.dateID)
        userDefaults.set(data, forKey: AppConstants.snapshotKey)
    }

    func loadTasks(for dateID: String) -> [DailyTask] {
        guard let snapshot = loadSnapshot(), snapshot.dateID == dateID else {
            return []
        }

        let completionMap = loadCompletionMap()
        return snapshot.tasks
            .map { task in
                var updatedTask = task
                updatedTask.isCompleted = completionMap[completionKey(for: task.taskID, dateID: dateID)] ?? false
                return updatedTask
            }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    func toggleTask(taskID: String, dateID: String) -> Bool {
        var completionMap = loadCompletionMap()
        let key = completionKey(for: taskID, dateID: dateID)
        let newValue = !(completionMap[key] ?? false)
        completionMap[key] = newValue
        clearStaleCompletionData(in: &completionMap, keeping: dateID)
        saveCompletionMap(completionMap)
        return newValue
    }

    private func loadCompletionMap() -> [String: Bool] {
        guard
            let data = userDefaults.data(forKey: AppConstants.completionMapKey),
            let completionMap = try? decoder.decode([String: Bool].self, from: data)
        else {
            return [:]
        }

        return completionMap
    }

    private func saveCompletionMap(_ completionMap: [String: Bool]) {
        guard let data = try? encoder.encode(completionMap) else {
            return
        }

        userDefaults.set(data, forKey: AppConstants.completionMapKey)
    }

    // MARK: - History

    func saveHistory(_ history: [String: [DailyTask]]) {
        guard let data = try? encoder.encode(history) else { return }
        userDefaults.set(data, forKey: AppConstants.historyKey)
    }

    func loadHistory() -> [String: [DailyTask]] {
        guard
            let data = userDefaults.data(forKey: AppConstants.historyKey),
            let history = try? decoder.decode([String: [DailyTask]].self, from: data)
        else {
            return [:]
        }
        return history
    }

    func mergeHistory(_ newEntries: [String: [DailyTask]]) {
        var history = loadHistory()
        for (dateID, tasks) in newEntries {
            history[dateID] = tasks
        }
        saveHistory(history)
    }

    func loadHistoryEntries() -> [(dateID: String, tasks: [DailyTask])] {
        let history = loadHistory()
        let completionMap = loadCompletionMap()

        return history.map { dateID, tasks in
            let merged = tasks.map { task -> DailyTask in
                var updated = task
                updated.isCompleted = completionMap[completionKey(for: task.taskID, dateID: dateID)] ?? false
                return updated
            }.sorted { $0.sortOrder < $1.sortOrder }
            return (dateID: dateID, tasks: merged)
        }.sorted { $0.dateID > $1.dateID }
    }

    // MARK: - Private

    private func clearStaleCompletionData(keeping dateID: String) {
        let historyDateIDs = Set(loadHistory().keys)
        var completionMap = loadCompletionMap()
        clearStaleCompletionData(in: &completionMap, keeping: dateID, historyDateIDs: historyDateIDs)
        saveCompletionMap(completionMap)
    }

    private func clearStaleCompletionData(in completionMap: inout [String: Bool], keeping dateID: String) {
        let historyDateIDs = Set(loadHistory().keys)
        clearStaleCompletionData(in: &completionMap, keeping: dateID, historyDateIDs: historyDateIDs)
    }

    private func clearStaleCompletionData(in completionMap: inout [String: Bool], keeping dateID: String, historyDateIDs: Set<String>) {
        completionMap = completionMap.filter { key, _ in
            guard let separatorIndex = key.firstIndex(of: "|") else { return false }
            let keyDateID = String(key[key.startIndex..<separatorIndex])
            return keyDateID == dateID || historyDateIDs.contains(keyDateID)
        }
    }

    private func completionKey(for taskID: String, dateID: String) -> String {
        "\(dateID)|\(taskID)"
    }
}
