import SwiftUI

/// The user's own farm — a larger red pin, matching the mockup.
struct FarmPinView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 30, height: 30)
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .frame(width: 34, height: 34)
                .foregroundStyle(Color.cowRed)
        }
        .shadow(radius: 2)
    }
}

/// Neighboring farms — small labeled circles.
struct NeighborPinView: View {
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.cowGreen, lineWidth: 2))
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.9))
                .clipShape(Capsule())
        }
    }
}
