import SwiftUI

extension Font {
    /// Rounded, heavily-weighted type scale shared by every screen.
    struct Theme {
        /// Massive numerals for the focus timer. Always pair with `.monospacedDigit()` on the Text.
        func timer(_ size: CGFloat) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }

        func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .heavy, design: .rounded)
        }

        func header(_ size: CGFloat = 22) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }

        func body(_ size: CGFloat = 16) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }

        func caption(_ size: CGFloat = 13) -> Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
    }

    static let theme = Theme()
}
