import CoreLocation

/// A hardcoded FocusFlight destination. Real coordinates, so distance/duration and the
/// live route map are grounded in something real, even though the roster of cities is
/// fixed rather than pulled from any routing service.
struct Destination: Identifiable {
    let id = UUID()
    let name: String
    let flag: String
    let coordinate: CLLocationCoordinate2D

    /// A 3-letter boarding-pass-style code. Not a real IATA lookup — just the city's
    /// initials, for the aesthetic.
    var code: String {
        String(name.prefix(3)).uppercased()
    }

    static let all: [Destination] = [
        Destination(name: "Tokyo", flag: "🇯🇵", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)),
        Destination(name: "London", flag: "🇬🇧", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)),
        Destination(name: "New York", flag: "🇺🇸", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
        Destination(name: "Paris", flag: "🇫🇷", coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)),
        Destination(name: "Dubai", flag: "🇦🇪", coordinate: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708)),
        Destination(name: "Singapore", flag: "🇸🇬", coordinate: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)),
        Destination(name: "Sydney", flag: "🇦🇺", coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)),
        Destination(name: "Toronto", flag: "🇨🇦", coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)),
        Destination(name: "Hong Kong", flag: "🇭🇰", coordinate: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)),
        Destination(name: "Zurich", flag: "🇨🇭", coordinate: CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417))
    ]
}
