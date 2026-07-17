import CoreLocation

/// A hardcoded FocusFlight destination. Real coordinates, so distance/duration and the
/// live route map are grounded in something real, even though the roster of cities is
/// fixed rather than pulled from any routing service.
///
/// All 10 are short-haul-distance Western/Central European cities on purpose — every
/// pairwise route between them is a real short flight, keeping FocusFlight sessions in
/// the same study-friendly range as Pomodoro (well under 2 hours; `FlightCalculator` also
/// hard-caps the computed duration as a backstop).
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
        Destination(name: "London", flag: "🇬🇧", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)),
        Destination(name: "Paris", flag: "🇫🇷", coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)),
        Destination(name: "Amsterdam", flag: "🇳🇱", coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)),
        Destination(name: "Brussels", flag: "🇧🇪", coordinate: CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517)),
        Destination(name: "Frankfurt", flag: "🇩🇪", coordinate: CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821)),
        Destination(name: "Zurich", flag: "🇨🇭", coordinate: CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417)),
        Destination(name: "Munich", flag: "🇩🇪", coordinate: CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820)),
        Destination(name: "Milan", flag: "🇮🇹", coordinate: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900)),
        Destination(name: "Vienna", flag: "🇦🇹", coordinate: CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738)),
        Destination(name: "Copenhagen", flag: "🇩🇰", coordinate: CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683))
    ]
}
