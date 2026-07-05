import Foundation

/// A simplified 4-way compass direction, used to reason about which side of
/// the farm the wind is blowing toward and whether that side is populated.
enum CompassDirection: String, CaseIterable, Codable, Hashable, Sendable {
    case north = "N"
    case east  = "E"
    case south = "S"
    case west  = "W"

    var bearingDegrees: Double {
        switch self {
        case .north: return 0
        case .east: return 90
        case .south: return 180
        case .west: return 270
        }
    }

    /// Buckets a raw compass bearing (0–360, e.g. today's wind direction)
    /// into the nearest of the 4 cardinal directions.
    static func nearest(toDegrees degrees: Double) -> CompassDirection {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        return allCases.min { a, b in
            circularDistance(positive, a.bearingDegrees) < circularDistance(positive, b.bearingDegrees)
        } ?? .north
    }

    private static func circularDistance(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(diff, 360 - diff)
    }
}
