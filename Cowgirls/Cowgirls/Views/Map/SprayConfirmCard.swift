import SwiftUI

struct SprayConfirmCard: View {
    let recommended: RecommendedSpray
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spray Now?").font(.headline)
            Text("Recommended based on current weather conditions")
                .font(.caption).foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended Amount").font(.caption2).foregroundStyle(.secondary)
                    Text("Direction: \(recommended.location)").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text("60ml").font(.title3.bold())
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.cowGreen.opacity(0.08)))

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered).frame(maxWidth: .infinity)
                Button("Spray", action: onConfirm)
                    .buttonStyle(.borderedProminent).tint(Color.cowGreen).frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .frame(maxWidth: 300)
    }
}
