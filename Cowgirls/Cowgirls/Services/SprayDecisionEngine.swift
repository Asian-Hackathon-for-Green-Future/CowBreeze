import Foundation

struct SprayDecisionEngine {
    /// Temperature-adjusted NH₃ status (not the raw measurement's fixed-threshold status)
    let ammoniaStatus: AmmoniaStatus
    let populatedDirections: Set<CompassDirection>
    let windSpeed: Double
    let windDirection: CompassDirection

    var recommendation: SprayRecommendation {
        let hasRiskyWind = populatedDirections.contains(windDirection)

        switch ammoniaStatus {
        case .good:
            return SprayRecommendation(shouldSpray: false, sprayIntensity: .none,
                reason: "NH₃ level normal — No spray needed")

        case .caution:
            if !hasRiskyWind {
                return SprayRecommendation(shouldSpray: false, sprayIntensity: .none,
                    reason: "NH₃ caution but wind not toward urban area — Monitoring only")
            }
            if windSpeed < 1.5 {
                return SprayRecommendation(shouldSpray: false, sprayIntensity: .none,
                    reason: "Wind unstable (< 1.5 m/s) — Waiting for stable conditions")
            } else if windSpeed <= 3.6 {
                return SprayRecommendation(shouldSpray: true, sprayIntensity: .normal,
                    reason: "NH₃ caution + urban wind (1.5–3.6 m/s) — Normal spray")
            } else {
                return SprayRecommendation(shouldSpray: false, sprayIntensity: .none,
                    reason: "Wind too strong (> 3.6 m/s) — Spray ineffective")
            }

        case .danger:
            if !hasRiskyWind {
                return SprayRecommendation(shouldSpray: false, sprayIntensity: .none,
                    reason: "NH₃ danger — Internal alert + ventilation required")
            }
            if windSpeed < 1.5 {
                return SprayRecommendation(shouldSpray: false, sprayIntensity: .none,
                    reason: "Wind unstable (< 1.5 m/s)")
            } else if windSpeed <= 3.6 {
                return SprayRecommendation(shouldSpray: true, sprayIntensity: .strong,
                    reason: "NH₃ danger + urban wind — Heavy spray + alert issued")
            } else {
                return SprayRecommendation(shouldSpray: false, sprayIntensity: .none,
                    reason: "Wind too strong (> 3.6 m/s)")
            }
        }
    }
}

struct SprayRecommendation: Sendable {
    var shouldSpray: Bool
    var sprayIntensity: SprayIntensity
    var reason: String

    enum SprayIntensity: String, Sendable {
        case none   = "No Spray"
        case normal = "Normal Spray"
        case strong = "Heavy Spray"
    }
}
