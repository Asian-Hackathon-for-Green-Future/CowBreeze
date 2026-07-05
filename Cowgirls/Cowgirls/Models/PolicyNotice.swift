import Foundation

enum PolicyCategory: String, CaseIterable, Identifiable, Hashable {
    case all      = "All"
    case subsidy  = "Subsidy"
    case complaint = "Complaint"

    var id: String { rawValue }
}

struct PolicyNotice: Identifiable {
    let id = UUID()
    var category: PolicyCategory
    var title: String
    var date: String
    var summary: String
    var imageName: String // SF Symbol used as a placeholder thumbnail
    var hasApplyButton: Bool
}
