import Foundation

struct AmmoniaMeasurement: Sendable {
    var concentration: Double
    var measuredAt: Date

    var status: AmmoniaStatus {
        switch concentration {
        case 0..<10:  return .good
        case 10..<25: return .caution
        default:      return .danger
        }
    }
}

enum AmmoniaStatus: String, Sendable, Equatable {
    case good    = "Good"
    case caution = "Caution"
    case danger  = "Danger"
}
