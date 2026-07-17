import Foundation

/// A quick, concrete suggestion for the mandatory 5-minute cooldown — replaces staring at
/// a blank countdown with something to actually go do.
enum BreakActivity: CaseIterable {
    case water
    case jumpingJacks
    case eyeRest
    case stretch
    case breathe

    var text: String {
        switch self {
        case .water: return "Drink a glass of water"
        case .jumpingJacks: return "Do 10 jumping jacks"
        case .eyeRest: return "Look at something 20 feet away for 20 seconds"
        case .stretch: return "Stretch your neck and shoulders"
        case .breathe: return "Take 5 slow, deep breaths"
        }
    }

    var systemImage: String {
        switch self {
        case .water: return "drop.fill"
        case .jumpingJacks: return "figure.jumprope"
        case .eyeRest: return "eye.fill"
        case .stretch: return "figure.cooldown"
        case .breathe: return "wind"
        }
    }
}
