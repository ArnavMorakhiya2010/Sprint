import SwiftUI

extension Color {
    /// Sprint's fixed brand palette. Every screen in the app must be built from these five
    /// colors — no default Apple system colors (`.blue`, `.gray`, etc).
    struct Theme {
        /// F0F1EB — master app background.
        let paper = Color(hex: 0xF0F1EB)
        /// 121212 — primary text, titles, dark surfaces (tab bar, focus screens).
        let ink = Color(hex: 0x121212)
        /// 3C4E34 — completed states, success haptics, checked-off tasks.
        let moss = Color(hex: 0x3C4E34)
        /// E9A02F — active timers, warnings, the priority "Frog" task.
        let marigold = Color(hex: 0xE9A02F)
        /// B1B38E — metadata, secondary text, time estimates, disabled states.
        let sand = Color(hex: 0xB1B38E)
    }

    static let theme = Theme()

    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
