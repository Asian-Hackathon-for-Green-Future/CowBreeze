import SwiftUI

struct PolicyView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: PolicyCategory = .all

    private var cityName: String {
        appState.cityName.isEmpty ? "Local" : appState.cityName
    }

    private var filteredNotices: [PolicyNotice] {
        selectedCategory == .all
            ? appState.policyNotices
            : appState.policyNotices.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                filterChips
                ForEach(filteredNotices) { notice in
                    PolicyNoticeCard(notice: notice)
                }
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello, \(appState.farm.name) 🤠")
                .font(.subheadline.bold()).foregroundStyle(.white)
            Text("\(cityName) Livestock Division")
                .font(.title2.bold()).foregroundStyle(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color.cowGreenDark, Color.cowGreen],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(PolicyCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Text(category.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.cowGreen : Color(.secondarySystemBackground))
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
