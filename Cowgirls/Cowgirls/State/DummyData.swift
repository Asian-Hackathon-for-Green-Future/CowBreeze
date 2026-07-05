import CoreLocation
import Foundation

// MARK: - Date helpers (private to this file)

private let koLocale = Locale(identifier: "ko_KR")
private let cal = Calendar.current
private let now = Date()

private var currentYear: Int  { cal.component(.year,  from: now) }
private var currentMonth: Int { cal.component(.month, from: now) }
private var currentDay: Int   { cal.component(.day,   from: now) }

private func isoDate(year: Int, month: Int, day: Int) -> String {
    String(format: "%04d/%02d/%02d", year, month, day)
}

private var lastDayOfMonth: Int {
    cal.range(of: .day, in: .month, for: now)!.upperBound - 1
}

/// 오늘이 당월 몇 퍼센트 지났는지 (0.0 ~ 1.0)
private var monthProgress: Double {
    Double(currentDay) / Double(lastDayOfMonth)
}

// MARK: - Extensions

extension Farm {
    static let dummy = Farm(
        name: "덕수농장",
        address: "경기도 양주시 화합면 327번길",
        coordinate: CLLocationCoordinate2D(latitude: 37.7853, longitude: 127.0454),
        livestock: [
            LivestockEntry(type: .cattle, count: 102),
            LivestockEntry(type: .pig, count: 80)
        ]
    )
}

extension WeatherInfo {
    static let dummy = WeatherInfo(
        temperature: 28,
        humidity: 72,
        windSpeed: 3.2,
        windDirection: "NNE",
        windDegrees: 22
    )
}

extension DailySprayStats {
    static var dummy: DailySprayStats {
        let f = DateFormatter()
        f.locale = koLocale
        f.dateFormat = "M월 d일"
        return DailySprayStats(
            dateLabel: f.string(from: now),
            sprayCount: 0,
            totalVolumeLiters: 0,
            spendWon: 0,
            savedWon: 0
        )
    }
}

extension RecommendedSpray {
    static let dummy = RecommendedSpray(volumeLiters: 0.06, location: "북동쪽")
}

extension AmmoniaMeasurement {
    static let dummy = AmmoniaMeasurement(concentration: 11.7, measuredAt: now)
}

extension WeeklySprayCount {
    /// 당월 기준 — 오늘이 속한 주차까지만 데이터, 이후 주차는 0
    /// 1주 = 1~7일, 2주 = 8~14일, 3주 = 15~21일, 4주 = 22~말일
    static var dummyWeek: [WeeklySprayCount] {
        let weekStarts = [1, 8, 15, 22]
        let fullCounts  = [5, 3,  7,  3]

        return zip(weekStarts, fullCounts).enumerated().map { idx, pair in
            let (start, full) = pair
            if currentDay < start {
                // 아직 시작 안 한 주차
                return WeeklySprayCount(week: "W\(idx + 1)", count: 0)
            } else if currentDay < start + 7 {
                // 현재 진행 중인 주차 — 지난 일수에 비례
                let daysIn  = currentDay - start + 1
                let partial = max(1, full * daysIn / 7)
                return WeeklySprayCount(week: "W\(idx + 1)", count: partial)
            } else {
                return WeeklySprayCount(week: "W\(idx + 1)", count: full)
            }
        }
    }
}

extension MonthlySprayCount {
    /// 당년 기준 — 지난 달은 확정값, 이번 달은 일수 비례, 미래 달은 0
    static var dummyYear: [MonthlySprayCount] {
        let fullCounts = [12, 9, 15, 20, 18, 18, 22, 14, 17, 21, 13, 11]
        return (1...12).map { month in
            let count: Int
            if month < currentMonth {
                count = fullCounts[month - 1]
            } else if month == currentMonth {
                count = max(1, Int(Double(fullCounts[month - 1]) * monthProgress))
            } else {
                count = 0
            }
            return MonthlySprayCount(month: englishMonth(month), count: count)
        }
    }
}

extension MonthlyReport {
    static var dummy: MonthlyReport {
        let fullCount = 18
        let partialCount = max(1, Int(Double(fullCount) * monthProgress))
        let cost = compactWon(partialCount * 6_336)
        let mf = DateFormatter(); mf.dateFormat = "MMMM"; mf.locale = Locale(identifier: "en_US")
        return MonthlyReport(
            monthLabel: "\(mf.string(from: now)) Report",
            periodLabel: "\(isoDate(year: currentYear, month: currentMonth, day: 1)) – \(isoDate(year: currentYear, month: currentMonth, day: lastDayOfMonth))",
            totalSprayCount: partialCount,
            monthlyCostLabel: cost,
            ammoniaReductionPercent: -34
        )
    }
}

extension AnnualReport {
    static var dummy: AnnualReport {
        let fullCounts = [12, 9, 15, 20, 18, 18, 22, 14, 17, 21, 13, 11]
        let pastTotal  = (1..<currentMonth).reduce(0) { $0 + fullCounts[$1 - 1] }
        let thisMonth  = max(1, Int(Double(fullCounts[currentMonth - 1]) * monthProgress))
        let total      = pastTotal + thisMonth
        let cost       = compactWon(total * 6_336)
        return AnnualReport(
            yearLabel: "\(currentYear) Annual Report",
            periodLabel: "\(isoDate(year: currentYear, month: 1, day: 1)) – \(isoDate(year: currentYear, month: 12, day: 31))",
            totalSprayCount: total,
            totalCostLabel: cost,
            ammoniaReductionPercent: -41
        )
    }
}

/// Compact currency formatter — shared by dummy data extensions
private func compactWon(_ amount: Int) -> String {
    if amount == 0 { return "₩0" }
    if amount >= 1_000_000 { return String(format: "₩%.1fM", Double(amount) / 1_000_000) }
    if amount >= 100_000   { return String(format: "₩%.0fK", Double(amount) / 1_000) }
    return String(format: "₩%.1fK", Double(amount) / 1_000)
}

private func englishMonth(_ month: Int) -> String {
    let f = DateFormatter(); f.dateFormat = "MMM"; f.locale = Locale(identifier: "en_US")
    var c = DateComponents(); c.month = month; c.year = 2026
    return Calendar.current.date(from: c).map { f.string(from: $0) } ?? "\(month)"
}

extension PolicyNotice {
    static let dummyList: [PolicyNotice] = [
        PolicyNotice(
            category: .subsidy,
            title: "Livestock Waste Emission Management Program Completed",
            date: "Jun 30, 2026",
            summary: "The city has completed the ammonia reduction support program aimed at curbing livestock odor complaints, with final approval received.",
            imageName: "building.2.fill",
            hasApplyButton: false
        ),
        PolicyNotice(
            category: .complaint,
            title: "Livestock Burial Site Excavation Work Commences",
            date: "Jun 30, 2026",
            summary: "On the first day, a site survey was conducted to assess the burial site conditions before full excavation commenced.",
            imageName: "hammer.fill",
            hasApplyButton: false
        ),
        PolicyNotice(
            category: .subsidy,
            title: "Livestock Waste Emission Management Program: Applications Open",
            date: "Jun 30, 2026",
            summary: "The city is accepting applications for the facility air emission management support program to reduce ammonia from livestock operations.",
            imageName: "doc.text.fill",
            hasApplyButton: true
        ),
        PolicyNotice(
            category: .subsidy,
            title: "Livestock Waste Emission Management Program Completed",
            date: "Jun 30, 2026",
            summary: "The 2025 livestock waste air emission management program has been successfully completed, with final approval granted.",
            imageName: "checkmark.seal.fill",
            hasApplyButton: false
        )
    ]
}
