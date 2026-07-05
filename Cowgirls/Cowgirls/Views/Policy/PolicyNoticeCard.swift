import SwiftUI

private let pocheonURL = URL(string: "https://www.pocheon.go.kr/www/contents.do?key=4289")!

struct PolicyNoticeCard: View {
    let notice: PolicyNotice

    var body: some View {
        Button {
            UIApplication.shared.open(pocheonURL)
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(notice.category.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cowYellow.opacity(0.25))
                    .clipShape(Capsule())
                Spacer()
                Text(notice.date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: notice.imageName)
                            .foregroundStyle(.secondary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(notice.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    Text(notice.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }
}
