import SwiftUI

@main
struct BurnListApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model: AppModel

    init() {
        _model = StateObject(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            ChecklistHomeView(model: model)
                .environment(\.appTheme, model.activeTheme)
                .preferredColorScheme(model.activeTheme.useDarkMode ? .dark : .light)
                .tint(model.activeTheme.accent)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await model.refreshIfConfigured()
            }
        }
    }
}
