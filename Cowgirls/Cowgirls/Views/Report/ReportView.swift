import SwiftUI
import Charts

struct ReportView: View {
    @EnvironmentObject var appState: AppState
    @State private var periodMode = 0
    @State private var expandedDays: Set<String> = []
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Picker("", selection: $periodMode) {
                    Text("Monthly").tag(0)
                    Text("Annual").tag(1)
                }
                .pickerStyle(.segmented)

                if periodMode == 0 {
                    monthlyContent
                } else {
                    annualContent
                }

                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF Report", systemImage: "doc.richtext.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                }
                .background(Color.cowGreenDark)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - 월간

    private var monthlyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.monthlyReport.monthLabel)
                    .font(.title2.bold())
                Text(appState.monthlyReport.periodLabel)
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                liveStatCard(icon: "drop.fill",
                             value: "\(appState.todayStats.sprayCount)x",
                             label: "Total Sprays")
                liveStatCard(icon: "humidity.fill",
                             value: "\(appState.todayStats.sprayCount * 60)ml",
                             label: "Volume")
                liveStatCard(icon: "wonsign.circle.fill",
                             value: compactWon(appState.todayStats.spendWon),
                             label: "Cost")
            }

            // 오늘 절감액
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("vs. Unguided Spray", systemImage: "arrow.down.circle.fill")
                        .font(.caption).foregroundStyle(Color.cowGreen)
                    Text("Today's Savings")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(compactWon(appState.todayStats.savedWon))
                    .font(.title2.bold()).foregroundStyle(Color.cowGreen)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cowGreen.opacity(0.25), lineWidth: 1))

            // 주간 차트
            Text("Weekly Sprays").font(.headline)

            let maxCount = appState.weeklyCounts.map(\.count).max() ?? 0
            Chart(appState.weeklyCounts) { item in
                BarMark(x: .value("Week", item.week), y: .value("Count", item.count))
                    .foregroundStyle(Color.cowGreen.gradient)
                    .annotation(position: .top) {
                        if item.count > 0 {
                            Text("\(item.count)x").font(.caption2)
                        }
                    }
            }
            .chartYScale(domain: 0...Double(max(maxCount + 2, 5)))
            .chartYAxis {
                AxisMarks(values: .stride(by: max(1.0, Double(max(maxCount + 2, 5)) / 4))) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 180)

            // 분사 기록 (일별 토글)
            sprayLogSection
        }
    }

    // MARK: - 분사 기록 일별 토글

    private var sprayLogSection: some View {
        let grouped = groupedLogs()
        return Group {
            if !grouped.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spray Log").font(.headline)

                    VStack(spacing: 6) {
                        ForEach(grouped, id: \.date) { group in
                            dayToggle(group: group)
                        }
                    }
                }
            }
        }
    }

    private func dayToggle(group: (date: String, logs: [SprayLog])) -> some View {
        let isExpanded = expandedDays.contains(group.date)
        return VStack(spacing: 0) {
            Button {
                if isExpanded {
                    expandedDays.remove(group.date)
                } else {
                    expandedDays.insert(group.date)
                }
            } label: {
                HStack {
                    Text(group.date)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(group.logs.count)x")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }

            if isExpanded {
                Divider().padding(.leading, 14)
                ForEach(group.logs) { log in
                    sprayLogRow(log)
                    if log.id != group.logs.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sprayLogRow(_ log: SprayLog) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.cowGreen)
                .frame(width: 32, height: 32)
                .background(Color.cowGreen.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(log.timeLabel)
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    Label(log.ammoniaStatus, systemImage: "aqi.medium")
                        .font(.caption).foregroundStyle(.secondary)
                    Label(log.windDirection, systemImage: "safari.fill")
                        .font(.caption).foregroundStyle(.secondary)
                    Label("\(log.volumeMl)ml", systemImage: "humidity.fill")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    /// 날짜 문자열 기준으로 최신순 그룹핑
    private func groupedLogs() -> [(date: String, logs: [SprayLog])] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d"
        let grouped = Dictionary(grouping: appState.sprayLogs) { f.string(from: $0.time) }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, logs: $0.value) }
    }

    // MARK: - 연간

    private var annualContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.annualReport.yearLabel)
                    .font(.title2.bold())
                Text(appState.annualReport.periodLabel)
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                liveStatCard(icon: "drop.fill",
                             value: "\(appState.annualTotalSprayCount)x",
                             label: "Total Sprays")
                liveStatCard(icon: "humidity.fill",
                             value: "\(appState.annualTotalSprayCount * 60)ml",
                             label: "Volume")
                liveStatCard(icon: "wonsign.circle.fill",
                             value: compactWon(appState.annualTotalSpendWon),
                             label: "Cost")
            }

            // 총 절감액
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("vs. Unguided Spray", systemImage: "arrow.down.circle.fill")
                        .font(.caption).foregroundStyle(Color.cowGreen)
                    Text("Annual Total Savings")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(compactWon(appState.annualTotalSavedWon))
                    .font(.title2.bold()).foregroundStyle(Color.cowGreen)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cowGreen.opacity(0.25), lineWidth: 1))

            Text("Monthly Sprays").font(.headline)

            Chart(appState.annualMonthlyCounts) { item in
                BarMark(x: .value("Month", item.month), y: .value("Count", item.count))
                    .foregroundStyle(Color.cowGreen.gradient)
                    .annotation(position: .top) {
                        if item.count > 0 {
                            Text("\(item.count)").font(.system(size: 9))
                        }
                    }
            }
            .chartYScale(domain: 0...Double((appState.annualMonthlyCounts.map(\.count).max() ?? 0) + 3))
            .frame(height: 180)
        }
    }

    // MARK: - 공통 뷰

    private func liveStatCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(Color.cowGreen)
            Text(value)
                .font(.headline.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }

    private func compactWon(_ amount: Int) -> String {
        if amount == 0 { return "₩0" }
        if amount >= 1_000_000 { return String(format: "₩%.1fM", Double(amount) / 1_000_000) }
        if amount >= 100_000 { return String(format: "₩%.0fK", Double(amount) / 1_000) }
        if amount >= 1_000 { return String(format: "₩%.1fK", Double(amount) / 1_000) }
        return String(format: "₩%.1fK", Double(amount) / 1_000)
    }

    private var header: some View {
        Text("Hello, \(appState.farm.name) 🤠").font(.headline)
    }

    // MARK: - PDF

    private func exportPDF() {
        let service = PDFReportService()
        if let url = service.generateReport(
            farm: appState.farm,
            report: appState.monthlyReport,
            weeklyCounts: appState.weeklyCounts
        ) {
            pdfURL = url
            showShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
