import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeMode = .dark
    @Published var colors: ColorScheme = .neoNoir
    
    private init() {
        loadThemePreferences()
    }
    
    func applyTheme() {
        colors = .neoNoir // Always use neo noir for this app
    }
    
    func switchTheme(to theme: ThemeMode) {
        currentTheme = theme
        saveThemePreferences()
    }
    
    private func loadThemePreferences() {
        currentTheme = .dark
    }
    
    private func saveThemePreferences() {
    }
}
extension ColorScheme {
    static let neoNoir = ColorScheme(
        background: Color(hex: "#121212"),
        surface: Color(hex: "#1E1E1E"),
        primaryText: Color(hex: "#FFFFFF"),
        secondaryText: Color(hex: "#E0E0E0"),
        accent: Color(hex: "#FFFFFF"),
        progress: Color(hex: "#CCCCCC"),
        border: Color(hex: "#333333"),
        shadow: Color.black.opacity(0.5)
    )
}

struct ColorScheme {
    let background: Color
    let surface: Color
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let progress: Color
    let border: Color
    let shadow: Color
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
