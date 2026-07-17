import SwiftUI

extension Color {
    /// Sprint's fixed brand palette. Every screen in the app must be built from these six
    /// colors — no default Apple system colors (`.blue`, `.gray`, etc).
    struct Theme {
        /// FFFFFF — floating components, cards, text on dark backgrounds.
        let white = Color(hex: 0xFFFFFF)
        /// FAF8F5 — master app background.
        let pearl = Color(hex: 0xFAF8F5)
        /// DFDACF — secondary surfaces, inactive tracks, metadata.
        let khaki = Color(hex: 0xDFDACF)
        /// A3968D — active elements, accents.
        let taupe = Color(hex: 0xA3968D)
        /// 4D403A — depth accent: gradients, secondary fills. Low contrast as text on
        /// `leather`, so it's a surface color, not a text color, on dark screens.
        let cacao = Color(hex: 0x4D403A)
        /// 262626 — primary text, dark surfaces (focus screens).
        let leather = Color(hex: 0x262626)
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
