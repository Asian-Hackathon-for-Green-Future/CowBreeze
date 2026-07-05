import Foundation
import Combine
import CoreLocation
import MapKit

/// Single source of truth for the app, injected as an EnvironmentObject.
/// Everything here is seeded with dummy data (see DummyData.swift) — swap
/// these out for real network / persistence calls later.
@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = false

    @Published var farm: Farm = .dummy
    @Published var weather: WeatherInfo = .dummy
    @Published var ammonia: AmmoniaMeasurement = .dummy
    @Published var todayStats: DailySprayStats = .dummy
    @Published var recommendedSpray: RecommendedSpray = .dummy
    @Published var weeklyCounts: [WeeklySprayCount] = [
        WeeklySprayCount(week: "W1", count: 0),
        WeeklySprayCount(week: "W2", count: 0),
        WeeklySprayCount(week: "W3", count: 0),
        WeeklySprayCount(week: "W4", count: 0)
    ]
    @Published var monthlyCounts: [MonthlySprayCount] = MonthlySprayCount.dummyYear
    @Published var monthlyReport: MonthlyReport = .dummy
    @Published var annualReport: AnnualReport = .dummy
    @Published var policyNotices: [PolicyNotice] = PolicyNotice.dummyList
    @Published var sprayLogs: [SprayLog] = []
    @Published var cityName: String = ""

    /// Reverse-geocodes the farm coordinate using English locale to get the
    /// romanized administrative city/district name for display in Policy view.
    func refreshCityName() {
        let location = CLLocation(latitude: farm.coordinate.latitude,
                                  longitude: farm.coordinate.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location,
                                        preferredLocale: Locale(identifier: "en_US")) { placemarks, _ in
            DispatchQueue.main.async {
                if let p = placemarks?.first {
                    self.cityName = p.locality
                        ?? p.subAdministrativeArea
                        ?? p.administrativeArea
                        ?? "Local"
                }
            }
        }
    }

    // MARK: - 연간 집계 (1~전월 더미 + 이번달 실사용)

    /// 이번달 포함 연간 총 분사횟수
    var annualTotalSprayCount: Int {
        let pastMonths = monthlyCounts.prefix(currentMonth - 1).reduce(0) { $0 + $1.count }
        return pastMonths + todayStats.sprayCount
    }

    /// 연간 총 소비 비용 (회당 6,336원)
    var annualTotalSpendWon: Int {
        let pastMonths = monthlyCounts.prefix(currentMonth - 1).reduce(0) { $0 + $1.count }
        return pastMonths * 6_336 + todayStats.spendWon
    }

    /// 연간 총 절감 비용 (회당 7,500원)
    var annualTotalSavedWon: Int {
        let pastMonths = monthlyCounts.prefix(currentMonth - 1).reduce(0) { $0 + $1.count }
        return pastMonths * 7_500 + todayStats.savedWon
    }

    /// 이번달 실사용값 반영한 월별 차트용 배열
    var annualMonthlyCounts: [MonthlySprayCount] {
        monthlyCounts.enumerated().map { idx, item in
            if idx == currentMonth - 1 {
                return MonthlySprayCount(month: item.month, count: todayStats.sprayCount)
            }
            return item
        }
    }

    /// Temperature-adjusted NH₃ threshold per the decision table:
    /// T < 25°C → 11 ppm / 25–35°C → 10 ppm / ≥ 35°C → 9 ppm
    var nh3Threshold: Double {
        switch weather.temperature {
        case ..<25:  return 11.0
        case 25..<35: return 10.0
        default:      return 9.0
        }
    }

    /// NH₃ status evaluated against the current temperature-adjusted threshold.
    var nh3DynamicStatus: AmmoniaStatus {
        let c = ammonia.concentration
        if c < nh3Threshold { return .good }
        if c < 25           { return .caution }
        return .danger
    }

    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }

    /// Cardinal directions from the farm that appear to be populated /
    /// built-up, as estimated by `UrbanDirectionDetector`. Used to decide
    /// whether today's wind direction is carrying odor toward people.
    @Published var populatedDirections: Set<CompassDirection> = []
    @Published var isAnalyzingDirections: Bool = false
    @Published var isFetchingWeather: Bool = false

    private let urbanDetector = UrbanDirectionDetector()
    private let weatherService = WeatherService()
    private var weatherRefreshTask: Task<Void, Never>?

    /// 분사 1회 기록 — todayStats + 이번 주차 차트 + 로그 동시 업데이트
    func recordSpray(volumeLiters: Double) {
        todayStats = DailySprayStats(
            dateLabel: todayStats.dateLabel,
            sprayCount: todayStats.sprayCount + 1,
            totalVolumeLiters: todayStats.totalVolumeLiters + volumeLiters,
            spendWon: todayStats.spendWon + 6_336,
            savedWon: todayStats.savedWon + 7_500
        )
        let day = Calendar.current.component(.day, from: Date())
        let weekIndex = min((day - 1) / 7, weeklyCounts.count - 1)
        weeklyCounts[weekIndex].count += 1

        // 분사 로그 추가
        sprayLogs.insert(
            SprayLog(
                time: Date(),
                ammoniaLevel: ammonia.concentration,
                windDirection: weather.windDirection,
                volumeMl: 60,
                spendWon: 6_336,
                savedWon: 7_500
            ),
            at: 0 // 최신이 위에
        )
    }

    /// Re-runs the directional analysis for the current farm location.
    /// Call this right after onboarding, or again later if the farm's
    /// location changes.
    func refreshPopulatedDirections() {
        isAnalyzingDirections = true
        let coordinate = farm.coordinate
        Task {
            let detected = await urbanDetector.detectPopulatedDirections(from: coordinate)
            populatedDirections = detected
            isAnalyzingDirections = false
        }
    }

    /// Starts polling real weather data from OpenWeatherMap every 10 minutes.
    /// Call this right after onboarding.
    func startWeatherPolling() {
        // Fetch immediately
        refreshWeather()
        // Then every 10 minutes
        weatherRefreshTask = Task {
            while true {
                try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000)
                if !Task.isCancelled {
                    refreshWeather()
                }
            }
        }
    }

    /// Fetches current weather from OpenWeatherMap
    private func refreshWeather() {
        isFetchingWeather = true
        Task {
            do {
                let newWeather = try await weatherService.fetchWeather(
                    latitude: farm.coordinate.latitude,
                    longitude: farm.coordinate.longitude
                )
                weather = newWeather
            } catch {
                print("Weather fetch error: \(error)")
                // Keep using previous weather on error
            }
            isFetchingWeather = false
        }
    }

    /// Cancels ongoing weather polling (call on cleanup or when needed)
    func stopWeatherPolling() {
        weatherRefreshTask?.cancel()
        weatherRefreshTask = nil
    }

    /// Simulates realistic threshold-crossing conditions based on the decision table:
    /// Threshold_T = 11 ppm (T<25°C) / 10 ppm (25≤T<35°C) / 9 ppm (T≥35°C)
    /// Also updates weather: wind speed 1.5–3.6 m/s, direction toward a populated area.
    func simulateAmmoniaSpike() {
        // Random temperature across all threshold zones
        let temp = Int.random(in: 15...40)

        // Temperature-dependent NH₃ threshold
        let threshold: Double
        switch temp {
        case ..<25:  threshold = 11.0
        case 25..<35: threshold = 10.0
        default:     threshold = 9.0
        }

        // NH₃ ≥ threshold (add 0–20 ppm headroom for realism)
        let nh3 = threshold + Double.random(in: 0.5...20.0)

        // Wind speed in spray-triggering range (1.5–3.6 m/s)
        let windSpeed = Double.random(in: 1.5...3.6)

        // Wind direction: toward a detected populated direction (or random if none)
        let targetDir = populatedDirections.randomElement()
            ?? CompassDirection.allCases.randomElement()
            ?? .north
        let windDeg = targetDir.bearingDegrees + Double.random(in: -8...8)

        // Update weather readings
        weather = WeatherInfo(
            temperature: temp,
            humidity: Int.random(in: 60...90),
            windSpeed: windSpeed,
            windDirection: CompassDirection.nearest(toDegrees: windDeg).rawValue,
            windDegrees: windDeg
        )

        // Update NH₃ sensor reading
        ammonia = AmmoniaMeasurement(concentration: nh3, measuredAt: Date())

        NotificationManager.shared.scheduleAmmoniaAlert(level: Int(nh3))
    }
}
