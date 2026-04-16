import XCTest
@testable import BurnList

final class ChecklistStoreTests: XCTestCase {
    func testTogglingTaskPersistsCompletionForSameDay() throws {
        let defaults = makeDefaults()
        let store = ChecklistStore(userDefaults: defaults)
        let task = DailyTask(
            dateID: "2026-04-14",
            taskID: "dsa-30m-day",
            title: "DSA (30m/day)",
            sortOrder: 0,
            isCompleted: false
        )

        store.saveSnapshot(
            DailyChecklistSnapshot(
                dateID: "2026-04-14",
                tasks: [task],
                refreshedAt: DateFormatting.dayFormatter.date(from: "2026-04-14")!,
                lastErrorMessage: nil
            )
        )
        store.toggleTask(taskID: task.taskID, dateID: task.dateID)

        let reloaded = store.loadTasks(for: "2026-04-14")

        XCTAssertEqual(reloaded.first?.isCompleted, true)
    }

    func testLoadingTasksDoesNotCarryCompletionIntoNextDay() throws {
        let defaults = makeDefaults()
        let store = ChecklistStore(userDefaults: defaults)
        let task = DailyTask(
            dateID: "2026-04-14",
            taskID: "dsa-30m-day",
            title: "DSA (30m/day)",
            sortOrder: 0,
            isCompleted: false
        )

        store.saveSnapshot(
            DailyChecklistSnapshot(
                dateID: "2026-04-15",
                tasks: [
                    task,
                    DailyTask(
                        dateID: "2026-04-15",
                        taskID: "dsa-30m-day",
                        title: "DSA (30m/day)",
                        sortOrder: 0,
                        isCompleted: false
                    )
                ],
                refreshedAt: DateFormatting.dayFormatter.date(from: "2026-04-15")!,
                lastErrorMessage: nil
            )
        )

        store.toggleTask(taskID: "dsa-30m-day", dateID: "2026-04-14")

        let todayTasks = store.loadTasks(for: "2026-04-15")

        XCTAssertEqual(todayTasks.first?.isCompleted, false)
    }

    private func makeDefaults(file: StaticString = #filePath, line: UInt = #line) -> UserDefaults {
        let suiteName = "ChecklistStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected isolated defaults suite", file: file, line: line)
            return .standard
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
final class TaskSyncServiceTests: XCTestCase {
    func testRefreshSavesSnapshotForConfiguredSheetURL() async throws {
        let defaults = makeDefaults()
        let store = ChecklistStore(userDefaults: defaults)
        let csv = """
        Date,DSA (30m/day),FE coding (30m/day),UI coding (30m/day)
        2026-04-14,yes,,planned
        """
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/tasks.csv")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let service = TaskSyncService(
            store: store,
            session: StubNetworkSession(result: .success((Data(csv.utf8), response)))
        )

        let snapshot = await service.refreshPreservingCache(
            configuration: AppConfiguration(
                sheetURLString: "https://example.com/tasks.csv",
                remindersEnabled: false,
                reminderHour: 9,
                reminderMinute: 0
            ),
            now: DateFormatting.dayFormatter.date(from: "2026-04-14")!
        )

        XCTAssertEqual(snapshot.tasks.map(\.title), ["DSA (30m/day)", "UI coding (30m/day)"])
        XCTAssertNil(snapshot.lastErrorMessage)
        XCTAssertEqual(store.loadTasks(for: "2026-04-14").map(\.title), ["DSA (30m/day)", "UI coding (30m/day)"])
    }

    func testRefreshPreservesCachedTasksAndRecordsErrorOnFailure() async throws {
        let defaults = makeDefaults()
        let store = ChecklistStore(userDefaults: defaults)
        store.saveSnapshot(
            DailyChecklistSnapshot(
                dateID: "2026-04-14",
                tasks: [
                    DailyTask(
                        dateID: "2026-04-14",
                        taskID: "dsa-30m-day",
                        title: "DSA (30m/day)",
                        sortOrder: 0,
                        isCompleted: false
                    )
                ],
                refreshedAt: DateFormatting.dayFormatter.date(from: "2026-04-14")!,
                lastErrorMessage: nil
            )
        )

        let service = TaskSyncService(
            store: store,
            session: StubNetworkSession(result: .failure(URLError(.notConnectedToInternet)))
        )

        let snapshot = await service.refreshPreservingCache(
            configuration: AppConfiguration(
                sheetURLString: "https://example.com/tasks.csv",
                remindersEnabled: false,
                reminderHour: 9,
                reminderMinute: 0
            ),
            now: DateFormatting.dayFormatter.date(from: "2026-04-14")!
        )

        XCTAssertEqual(snapshot.tasks.map(\.title), ["DSA (30m/day)"])
        XCTAssertEqual(store.loadTasks(for: "2026-04-14").map(\.title), ["DSA (30m/day)"])
        XCTAssertEqual(snapshot.lastErrorMessage, URLError(.notConnectedToInternet).localizedDescription)
    }

    private func makeDefaults(file: StaticString = #filePath, line: UInt = #line) -> UserDefaults {
        let suiteName = "TaskSyncServiceTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected isolated defaults suite", file: file, line: line)
            return .standard
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private struct StubNetworkSession: NetworkSession {
    let result: Result<(Data, URLResponse), Error>

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try result.get()
    }
}
