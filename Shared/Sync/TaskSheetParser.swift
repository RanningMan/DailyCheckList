import Foundation

struct TaskSheetParser {
    func parseAllTasks(from csv: String) throws -> [String: [DailyTask]] {
        let rows = parseRows(from: csv)
        guard let header = rows.first, !header.isEmpty else {
            throw TaskSheetParserError.missingHeader
        }

        guard let dateColumnIndex = header.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("Date") == .orderedSame }) else {
            throw TaskSheetParserError.missingDateColumn
        }

        let taskColumns = taskColumnDefinitions(from: header, excluding: dateColumnIndex)
        var result: [String: [DailyTask]] = [:]

        for row in rows.dropFirst() {
            guard row.indices.contains(dateColumnIndex),
                  let dateID = DateFormatting.normalizedDayID(fromSheetValue: row[dateColumnIndex]) else {
                continue
            }

            let tasks = taskColumns.compactMap { column -> DailyTask? in
                let value = row.indices.contains(column.rawIndex) ? row[column.rawIndex] : ""
                guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return nil
                }
                return DailyTask(
                    dateID: dateID,
                    taskID: slug(from: column.title),
                    title: column.title,
                    sortOrder: column.sortOrder,
                    isCompleted: false
                )
            }

            if !tasks.isEmpty {
                result[dateID] = tasks
            }
        }

        return result
    }

    func parseTodayTasks(from csv: String, now: Date) throws -> [DailyTask] {
        let rows = parseRows(from: csv)
        guard let header = rows.first, !header.isEmpty else {
            throw TaskSheetParserError.missingHeader
        }

        guard let dateColumnIndex = header.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("Date") == .orderedSame }) else {
            throw TaskSheetParserError.missingDateColumn
        }

        let taskColumns = taskColumnDefinitions(from: header, excluding: dateColumnIndex)
        let todayID = DateFormatting.dayID(from: now)

        guard let row = rows.dropFirst().first(where: { row in
            guard row.indices.contains(dateColumnIndex) else {
                return false
            }

            return DateFormatting.normalizedDayID(fromSheetValue: row[dateColumnIndex]) == todayID
        }) else {
            return []
        }

        return taskColumns.compactMap { column in
            let value = row.indices.contains(column.rawIndex) ? row[column.rawIndex] : ""
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            return DailyTask(
                dateID: todayID,
                taskID: slug(from: column.title),
                title: column.title,
                sortOrder: column.sortOrder,
                isCompleted: false
            )
        }
    }

    private func taskColumnDefinitions(from header: [String], excluding dateColumnIndex: Int) -> [TaskColumn] {
        header.enumerated().compactMap { index, value in
            guard index != dateColumnIndex else {
                return nil
            }

            let title = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let sortOrder = header[..<index].filter { _ in true }.count - (index > dateColumnIndex ? 1 : 0)
            return TaskColumn(rawIndex: index, title: title, sortOrder: sortOrder)
        }
    }

    private func slug(from value: String) -> String {
        let lowercase = value.lowercased()
        let mapped = lowercase.map { character -> Character in
            character.isLetter || character.isNumber ? character : "-"
        }
        let collapsed = String(mapped).replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func parseRows(from csv: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        let characters = Array(csv.replacingOccurrences(of: "\r\n", with: "\n"))
        var index = 0

        while index < characters.count {
            let character = characters[index]

            switch character {
            case "\"":
                if isInsideQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    isInsideQuotes.toggle()
                }
            case "," where !isInsideQuotes:
                row.append(field)
                field = ""
            case "\n" where !isInsideQuotes:
                row.append(field)
                if !row.allSatisfy({ $0.isEmpty }) {
                    rows.append(row)
                }
                row = []
                field = ""
            case "\r" where !isInsideQuotes:
                break
            default:
                field.append(character)
            }

            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            if !row.allSatisfy({ $0.isEmpty }) {
                rows.append(row)
            }
        }

        return rows
    }
}

private struct TaskColumn {
    let rawIndex: Int
    let title: String
    let sortOrder: Int
}

enum TaskSheetParserError: Error {
    case missingHeader
    case missingDateColumn
}
