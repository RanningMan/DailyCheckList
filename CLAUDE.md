# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the app
xcodebuild -project BurnList.xcodeproj -scheme BurnList -configuration Debug build

# Run all tests
xcodebuild -project BurnList.xcodeproj -scheme BurnList -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -project BurnList.xcodeproj -scheme BurnList -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BurnListTests/ChecklistStoreTests test

# Run a single test method
xcodebuild -project BurnList.xcodeproj -scheme BurnList -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BurnListTests/ChecklistStoreTests/testTogglePersistsCompletion test
```

## Architecture

SwiftUI iOS app that syncs a daily task checklist from a published Google Sheet CSV and displays it with widget support. No backend API — syncs directly from Google Sheets exports.

### Data Flow

```
Google Sheet (CSV) → TaskSyncService → TaskSheetParser → ChecklistStore (UserDefaults) → AppModel → UI / Widget
```

### Key Modules

- **Shared/** — Code shared between the main app and widget extension
  - `DailyTask` — Core model. Tasks are keyed by compound ID `dateID|taskID` (date-isolated completion state)
  - `ChecklistStore` — Persistence via app group UserDefaults (`group.com.example.BurnList.shared`), enabling widget data sharing
  - `TaskSheetParser` — Parses Google Sheets CSV, dynamically identifies date and task columns, handles multiple date formats
  - `AppConstants` — App group identifier, UserDefaults keys, widget kind
- **BurnList/App/** — `AppModel` is the central `@Observable`/`@MainActor` view model coordinating sync, persistence, and reminders
- **BurnList/Views/** — `ChecklistHomeView` (main list with pull-to-refresh) and `SettingsView` (sheet URL config, reminder settings)
- **BurnList/Sync/** — `TaskSyncService` handles network fetch with graceful cache fallback on failure
- **BurnListWidget/** — Home screen widget with `ToggleTaskIntent` for interactive task toggling; refreshes daily at 00:05

### Design Decisions

- Completion state is tracked per-date — toggling a task today doesn't affect other days
- `TaskSyncService.refreshPreservingCache()` keeps cached data visible on network failure rather than clearing the UI
- `ReminderScheduler` and `NetworkSession` use protocols for testability
- Widget shares data with the main app via app group UserDefaults and reloads via `WidgetCenter.reloadAllTimelines()`
