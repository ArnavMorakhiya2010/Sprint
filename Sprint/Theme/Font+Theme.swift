import SwiftUI

extension Font {
    /// Poppins, per spec's exact type scale. `Font.custom` silently falls back to the
    /// system font if "Poppins-*" isn't registered — so the app degrades gracefully rather
    /// than crashing if the font files haven't been added to the project (see README:
    /// they need to be downloaded from Google Fonts and added as `UIAppFonts`, since a
    /// code-only tool can't ship real font binaries).
    struct Theme {
        func h1Large() -> Font { .custom("Poppins-SemiBold", size: 32) }
        func h1Small() -> Font { .custom("Poppins-Bold", size: 24) }
        func h2() -> Font { .custom("Poppins-SemiBold", size: 20) }
        func h3() -> Font { .custom("Poppins-Medium", size: 18) }
        func bodyLarge() -> Font { .custom("Poppins-Regular", size: 16) }
        func bodyMedium1() -> Font { .custom("Poppins-Medium", size: 14) }
        func bodyMedium2() -> Font { .custom("Poppins-Regular", size: 14) }
        func bodySmall() -> Font { .custom("Poppins-Regular", size: 12) }
        func button() -> Font { .custom("Poppins-SemiBold", size: 16) }

        /// Not part of the named scale — the massive session-clock digits ("14:37") need
        /// sizes well beyond H1, which is normal for a dedicated hero-numeral style.
        func timerDigits(_ size: CGFloat) -> Font { .custom("Poppins-SemiBold", size: size) }
    }

    static let theme = Theme()
}
