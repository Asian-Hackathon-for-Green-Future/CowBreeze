import UIKit

struct PDFReportService {
    func generateReport(farm: Farm, report: MonthlyReport, weeklyCounts: [WeeklySprayCount]) -> URL? {
        let pageW: CGFloat = 595
        let pageH: CGFloat = 842
        let margin: CGFloat = 48
        let pageRect = CGRect(x: 0, y: 0, width: pageW, height: pageH)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CowGirls_Report_\(report.monthLabel.replacingOccurrences(of: " ", with: "_")).pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()

                var y: CGFloat = 0

                // Header band
                let green = UIColor(red: 0.09, green: 0.27, blue: 0.20, alpha: 1)
                green.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: pageW, height: 90))
                attr("CowGirls Farm Report", size: 20, weight: .bold,   color: .white).draw(at: .init(x: margin, y: 18))
                attr("Hello, \(farm.name)",  size: 13, weight: .regular, color: UIColor.white.withAlphaComponent(0.85)).draw(at: .init(x: margin, y: 46))
                attr(report.periodLabel,      size: 11, weight: .regular, color: UIColor.white.withAlphaComponent(0.70)).draw(at: .init(x: margin, y: 66))
                y = 106

                // Title
                attr(report.monthLabel, size: 22, weight: .bold, color: .black).draw(at: .init(x: margin, y: y))
                y += 34

                // Stat cards
                let cardW = (pageW - margin * 2 - 16) / 3
                let cards: [(String, String)] = [
                    ("\(report.totalSprayCount)x", "Total Sprays"),
                    (report.monthlyCostLabel, "Cost"),
                    ("\(abs(report.ammoniaReductionPercent))% less", "NH₃")
                ]
                for (i, (val, lbl)) in cards.enumerated() {
                    let x = margin + CGFloat(i) * (cardW + 8)
                    let cardRect = CGRect(x: x, y: y, width: cardW, height: 64)
                    UIColor(white: 0.94, alpha: 1).setFill()
                    UIBezierPath(roundedRect: cardRect, cornerRadius: 8).fill()
                    attr(val,  size: 16, weight: .bold,    color: .black).draw(at: .init(x: x + 10, y: y + 10))
                    attr(lbl,  size: 10, weight: .regular, color: .darkGray).draw(at: .init(x: x + 10, y: y + 40))
                }
                y += 84

                // Chart label
                attr("Weekly Spray Count", size: 13, weight: .semibold, color: .black).draw(at: .init(x: margin, y: y))
                y += 24

                // Bar chart
                let chartH: CGFloat = 90
                let maxCount = max(1, weeklyCounts.map(\.count).max() ?? 1)
                let slotW = (pageW - margin * 2) / CGFloat(weeklyCounts.count)
                let barW  = slotW * 0.52
                UIColor(red: 0.20, green: 0.47, blue: 0.36, alpha: 1).setFill()
                for (i, item) in weeklyCounts.enumerated() {
                    let barH = CGFloat(item.count) / CGFloat(maxCount) * chartH
                    let x = margin + CGFloat(i) * slotW + (slotW - barW) / 2
                    if barH > 0 {
                        UIBezierPath(rect: CGRect(x: x, y: y + chartH - barH, width: barW, height: barH)).fill()
                        attr("\(item.count)x", size: 9, weight: .bold, color: .black).draw(at: .init(x: x, y: y + chartH - barH - 16))
                    }
                    attr(item.week, size: 9, weight: .regular, color: .darkGray).draw(at: .init(x: x, y: y + chartH + 4))
                }
                y += chartH + 28

                // Footer line
                UIColor.lightGray.setStroke()
                let path = UIBezierPath(); path.move(to: .init(x: margin, y: y)); path.addLine(to: .init(x: pageW - margin, y: y)); path.lineWidth = 0.5; path.stroke()
                y += 10
                let df = DateFormatter(); df.dateStyle = .long; df.locale = Locale(identifier: "en_US")
                attr("Published: \(df.string(from: Date())) · CowGirls", size: 9, weight: .regular, color: .gray).draw(at: .init(x: margin, y: y))
            }
            return url
        } catch {
            print("PDF error: \(error)"); return nil
        }
    }

    private func attr(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ])
    }
}
