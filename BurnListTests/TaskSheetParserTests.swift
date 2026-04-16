import XCTest
@testable import BurnList

final class TaskSheetParserTests: XCTestCase {
    func testParsesNonEmptyTaskCellsForMatchingDateRowInSheetColumnOrder() throws {
        let parser = TaskSheetParser()
        let csv = """
        Date,DSA (30m/day),FE coding (30m/day),UI coding (30m/day),FE SD (1.5h/day),BE SD (1.5h/day)
        2026-04-14,yes,,planned,done,
        2026-04-15,,x,,x,x
        """

        let tasks = try parser.parseTodayTasks(
            from: csv,
            now: DateFormatting.dayFormatter.date(from: "2026-04-14")!
        )

        XCTAssertEqual(tasks.map(\.taskID), ["dsa-30m-day", "ui-coding-30m-day", "fe-sd-1-5h-day"])
        XCTAssertEqual(tasks.map(\.title), ["DSA (30m/day)", "UI coding (30m/day)", "FE SD (1.5h/day)"])
        XCTAssertEqual(tasks.map(\.sortOrder), [0, 2, 3])
        XCTAssertTrue(tasks.allSatisfy { $0.dateID == "2026-04-14" })
    }

    func testIgnoresBlankTaskCellsForMatchingDateRow() throws {
        let parser = TaskSheetParser()
        let csv = """
        Date,DSA (30m/day),FE coding (30m/day),UI coding (30m/day)
        2026-04-14,  ,planned,
        """

        let tasks = try parser.parseTodayTasks(
            from: csv,
            now: DateFormatting.dayFormatter.date(from: "2026-04-14")!
        )

        XCTAssertEqual(tasks.map(\.title), ["FE coding (30m/day)"])
    }

    func testSupportsUSStyleDateValuesFromGoogleSheets() throws {
        let parser = TaskSheetParser()
        let csv = """
        Date,DSA (30m/day),FE coding (30m/day)
        4/14/2026,x,
        """

        let tasks = try parser.parseTodayTasks(
            from: csv,
            now: DateFormatting.dayFormatter.date(from: "2026-04-14")!
        )

        XCTAssertEqual(tasks.map(\.title), ["DSA (30m/day)"])
    }
}
