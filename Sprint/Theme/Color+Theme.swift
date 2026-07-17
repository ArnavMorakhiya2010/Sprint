import SwiftUI

extension Color {
    /// Pomly's brand palette. Every screen builds from these — no default Apple system
    /// colors (`.blue`, `.gray`, etc).
    struct Theme {
        /// F7EBE1 — light-mode background.
        let cream = Color(hex: 0xF7EBE1)
        /// F58D4C — primary accent, filled buttons, active/progress states.
        let orange = Color(hex: 0xF58D4C)
        /// F4B9B8 — secondary accent, disabled states, inactive tracks.
        let peach = Color(hex: 0xF4B9B8)
        /// 34271F — primary text and dark elements in light mode.
        let espresso = Color(hex: 0x34271F)
        /// Not one of the four brand swatches — the spec describes the deep-focus
        /// timer background only as "a deep black/dark charcoal", so this is a reasoned
        /// near-black extension in the same warm-brown family as `espresso`, used only
        /// for that one full-screen dark state.
        let charcoal = Color(hex: 0x1C1410)
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
