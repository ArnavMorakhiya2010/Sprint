import Foundation

/// A hardcoded FocusFlight destination. Deliberately not backed by any real routing or
/// distance data — the "flight" is a duration the user sets themselves via the arc dial;
/// Departure/Arrival exist to make that duration feel like a trip worth protecting.
struct Destination: Identifiable {
    let id = UUID()
    let name: String
    let flag: String

    static let all: [Destination] = [
        Destination(name: "Tokyo", flag: "🇯🇵"),
        Destination(name: "London", flag: "🇬🇧"),
        Destination(name: "New York", flag: "🇺🇸"),
        Destination(name: "Paris", flag: "🇫🇷"),
        Destination(name: "Dubai", flag: "🇦🇪"),
        Destination(name: "Singapore", flag: "🇸🇬"),
        Destination(name: "Sydney", flag: "🇦🇺"),
        Destination(name: "Toronto", flag: "🇨🇦"),
        Destination(name: "Hong Kong", flag: "🇭🇰"),
        Destination(name: "Zurich", flag: "🇨🇭")
    ]
}
