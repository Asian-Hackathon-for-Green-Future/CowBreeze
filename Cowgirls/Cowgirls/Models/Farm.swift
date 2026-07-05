import Foundation
import CoreLocation

enum LivestockType: String, CaseIterable, Identifiable, Hashable {
    case cattle  = "Cattle"
    case pig     = "Pig"
    case chicken = "Chicken"
    case goat    = "Goat"

    var id: String { rawValue }
}

struct LivestockEntry: Identifiable, Hashable {
    let id: UUID
    var type: LivestockType
    var count: Int

    init(id: UUID = UUID(), type: LivestockType, count: Int) {
        self.id = id
        self.type = type
        self.count = count
    }
}

struct Farm {
    var name: String
    var address: String
    var coordinate: CLLocationCoordinate2D
    var livestock: [LivestockEntry]
}
