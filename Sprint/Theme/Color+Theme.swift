import SwiftUI

extension Color {
    /// Sprint's fixed brand palette. Every screen in the app must be built from these five
    /// colors — no default Apple system colors (`.blue`, `.gray`, etc).
    struct Theme {
        /// C8D9E6 — master app background.
        let skyBlue = Color(hex: 0xC8D9E6)
        /// 2F4156 — primary text, heavy emphasis, dark surfaces (focus screens).
        let navy = Color(hex: 0x2F4156)
        /// 567C8D — active elements, accents, success states.
        let teal = Color(hex: 0x567C8D)
        /// F5EFEB — secondary surfaces, inactive tracks, metadata.
        let beige = Color(hex: 0xF5EFEB)
        /// FFFFFF — floating components, text on dark backgrounds.
        let white = Color(hex: 0xFFFFFF)
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
