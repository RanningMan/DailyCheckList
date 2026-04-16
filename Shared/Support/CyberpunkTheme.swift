import SwiftUI

struct AppTheme: Equatable {
    let name: String
    let background: Color
    let cardBackground: Color
    let accent: Color
    let completedAccent: Color
    let successBadge: Color
    let textPrimary: Color
    let textSecondary: Color
    let dimAccent: Color
    let useDarkMode: Bool

    static func monoFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }
}

enum AppThemeID: String, Codable, CaseIterable, Identifiable {
    case cyberpunk
    case vaporwave
    case terminal
    case bloodRed
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cyberpunk: "Cyberpunk"
        case .vaporwave: "Vaporwave"
        case .terminal: "Terminal"
        case .bloodRed: "Blood Red"
        case .minimal: "Minimal"
        }
    }

    var theme: AppTheme {
        switch self {
        case .cyberpunk:
            AppTheme(
                name: "Cyberpunk",
                background: Color(red: 0.04, green: 0.04, blue: 0.10),
                cardBackground: Color(red: 0.07, green: 0.07, blue: 0.16),
                accent: Color(red: 0, green: 0.94, blue: 1),
                completedAccent: Color(red: 1, green: 0, blue: 0.67),
                successBadge: Color(red: 0.22, green: 1, blue: 0.08),
                textPrimary: .white,
                textSecondary: Color(red: 0, green: 0.94, blue: 1).opacity(0.5),
                dimAccent: Color(red: 0, green: 0.94, blue: 1).opacity(0.4),
                useDarkMode: true
            )
        case .vaporwave:
            AppTheme(
                name: "Vaporwave",
                background: Color(red: 0.08, green: 0.02, blue: 0.14),
                cardBackground: Color(red: 0.12, green: 0.04, blue: 0.20),
                accent: Color(red: 0.4, green: 0.8, blue: 1),
                completedAccent: Color(red: 1, green: 0.4, blue: 0.7),
                successBadge: Color(red: 0.4, green: 1, blue: 0.8),
                textPrimary: .white,
                textSecondary: Color(red: 0.4, green: 0.8, blue: 1).opacity(0.5),
                dimAccent: Color(red: 0.4, green: 0.8, blue: 1).opacity(0.4),
                useDarkMode: true
            )
        case .terminal:
            AppTheme(
                name: "Terminal",
                background: Color(red: 0.02, green: 0.05, blue: 0.02),
                cardBackground: Color(red: 0.04, green: 0.10, blue: 0.04),
                accent: Color(red: 0, green: 1, blue: 0),
                completedAccent: Color(red: 0, green: 0.7, blue: 0),
                successBadge: Color(red: 0, green: 1, blue: 0),
                textPrimary: Color(red: 0, green: 1, blue: 0),
                textSecondary: Color(red: 0, green: 1, blue: 0).opacity(0.4),
                dimAccent: Color(red: 0, green: 1, blue: 0).opacity(0.3),
                useDarkMode: true
            )
        case .bloodRed:
            AppTheme(
                name: "Blood Red",
                background: Color(red: 0.06, green: 0.02, blue: 0.02),
                cardBackground: Color(red: 0.12, green: 0.04, blue: 0.04),
                accent: Color(red: 1, green: 0.15, blue: 0.15),
                completedAccent: Color(red: 1, green: 0.4, blue: 0),
                successBadge: Color(red: 1, green: 0.4, blue: 0),
                textPrimary: .white,
                textSecondary: Color(red: 1, green: 0.15, blue: 0.15).opacity(0.5),
                dimAccent: Color(red: 1, green: 0.15, blue: 0.15).opacity(0.35),
                useDarkMode: true
            )
        case .minimal:
            AppTheme(
                name: "Minimal",
                background: Color(red: 0.96, green: 0.96, blue: 0.97),
                cardBackground: .white,
                accent: Color(red: 0.2, green: 0.2, blue: 0.2),
                completedAccent: Color(red: 0.3, green: 0.3, blue: 0.3),
                successBadge: Color(red: 0.2, green: 0.7, blue: 0.3),
                textPrimary: Color(red: 0.1, green: 0.1, blue: 0.1),
                textSecondary: Color(red: 0.5, green: 0.5, blue: 0.5),
                dimAccent: Color(red: 0.7, green: 0.7, blue: 0.7),
                useDarkMode: false
            )
        }
    }
}

// MARK: - Backward compatibility alias

enum CyberpunkTheme {
    static var current: AppTheme { AppThemeID.cyberpunk.theme }

    static var background: Color { current.background }
    static var cardBackground: Color { current.cardBackground }
    static var neonCyan: Color { current.accent }
    static var neonMagenta: Color { current.completedAccent }
    static var neonGreen: Color { current.successBadge }
    static var textPrimary: Color { current.textPrimary }
    static var textSecondary: Color { current.textSecondary }
    static var dimCyan: Color { current.dimAccent }

    static func monoFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        AppTheme.monoFont(style, weight: weight)
    }
}

// MARK: - Environment

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme = AppThemeID.cyberpunk.theme
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
