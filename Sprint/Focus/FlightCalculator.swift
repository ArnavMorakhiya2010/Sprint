import CoreLocation

/// Turns a Departure/Arrival pair into a real great-circle distance and a plausible
/// flight duration, so FocusFlight's session length is never something the user sets —
/// it's a consequence of which two cities they picked (revision: no manual arc-drag time
/// entry in FocusFlight mode).
enum FlightCalculator {
    /// Typical commercial cruise speed.
    static let cruiseSpeedKmh: Double = 850
    /// Fixed taxi/takeoff/climb/descent/landing overhead folded into every flight.
    static let groundOverheadMinutes: Double = 25
    /// A study session shouldn't run longer than a Pomodoro's own ceiling. The
    /// close-together destination roster already keeps every route well under this, but
    /// the cap is kept as a hard backstop regardless of roster changes.
    static let maxMinutes = 120

    static func distanceKm(from: Destination, to: Destination) -> Double {
        let a = CLLocation(latitude: from.coordinate.latitude, longitude: from.coordinate.longitude)
        let b = CLLocation(latitude: to.coordinate.latitude, longitude: to.coordinate.longitude)
        return a.distance(from: b) / 1000
    }

    static func durationMinutes(from: Destination, to: Destination) -> Int {
        let cruiseMinutes = (distanceKm(from: from, to: to) / cruiseSpeedKmh) * 60
        let raw = Int((cruiseMinutes + groundOverheadMinutes).rounded())
        return min(maxMinutes, max(5, raw))
    }

    static func durationLabel(from: Destination, to: Destination) -> String {
        let minutes = durationMinutes(from: from, to: to)
        let hours = minutes / 60
        let remainder = minutes % 60
        return hours > 0 ? "\(hours)h \(remainder)m" : "\(remainder)m"
    }
}
