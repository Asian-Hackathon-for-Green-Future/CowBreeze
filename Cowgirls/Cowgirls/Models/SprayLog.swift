import Foundation

struct SprayLog: Identifiable {
    let id = UUID()
    let time: Date
    let ammoniaLevel: Double   // ppm
    let windDirection: String  // "NNE" 등
    let volumeMl: Int          // 60
    let spendWon: Int          // 6,336
    let savedWon: Int          // 7,500

    var timeLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d, HH:mm"
        return f.string(from: time)
    }

    var ammoniaStatus: String {
        switch ammoniaLevel {
        case 0..<10:  return "Good"
        case 10..<25: return "Caution"
        default:      return "Danger"
        }
    }
}
