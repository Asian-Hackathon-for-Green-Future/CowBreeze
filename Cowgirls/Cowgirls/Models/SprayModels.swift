import Foundation

/// Today's summary shown at the top of the Map dashboard.
struct DailySprayStats {
    var dateLabel: String
    var sprayCount: Int
    var totalVolumeLiters: Double
    var spendWon: Int   // 소비 비용: 6,336원 × 횟수
    var savedWon: Int   // 절감 비용: 7,500원 × 횟수 (무분별 대비)
}

/// The system's recommended spray amount, shown in the confirmation card.
struct RecommendedSpray {
    var volumeLiters: Double
    var location: String // 분사 위치 (e.g. "북동쪽")
}

/// One bar in the weekly spray-count chart on the Report tab.
struct WeeklySprayCount: Identifiable {
    let id = UUID()
    var week: String
    var count: Int
}

/// One bar in the monthly spray-count chart (for annual view).
struct MonthlySprayCount: Identifiable {
    let id = UUID()
    var month: String
    var count: Int
}

/// Monthly (or yearly) report summary.
struct MonthlyReport {
    var monthLabel: String          // "6월 리포트"
    var periodLabel: String         // "2026/06/01 - 2026/06/30"
    var totalSprayCount: Int        // 총 분사횟수
    var monthlyCostLabel: String    // "6.3만원"
    var ammoniaReductionPercent: Int// -34
}

/// Annual report summary.
struct AnnualReport {
    var yearLabel: String           // "2026년 리포트"
    var periodLabel: String         // "2026/01/01 - 2026/12/31"
    var totalSprayCount: Int
    var totalCostLabel: String      // "76만원"
    var ammoniaReductionPercent: Int
}
