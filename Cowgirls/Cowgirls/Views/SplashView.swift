import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale:    CGFloat = 0.4
    @State private var logoOpacity:  Double  = 0
    @State private var titleOpacity: Double  = 0
    @State private var tagOpacity:   Double  = 0
    @State private var screenOpacity: Double = 1

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.cowGreenDark, Color(red: 0.13, green: 0.38, blue: 0.28)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Circle().fill(.white.opacity(0.04)).frame(width: 400).offset(x: 120, y: -200)
            Circle().fill(.white.opacity(0.04)).frame(width: 280).offset(x: -130, y: 250)

            VStack(spacing: 0) {
                Spacer()

                Text("🤠").font(.system(size: 80))
                    .scaleEffect(logoScale).opacity(logoOpacity)

                Spacer().frame(height: 20)

                Text("COWGIRLS")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .tracking(6).foregroundStyle(.white)
                    .opacity(titleOpacity)

                Spacer().frame(height: 8)

                Text("Smart Odor Reduction Solution")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .opacity(tagOpacity)

                Spacer()

                Text("Livestock Division")
                    .font(.caption).foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 40).opacity(tagOpacity)
            }
        }
        .opacity(screenOpacity)
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
            logoScale = 1.0; logoOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) { titleOpacity = 1 }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) { tagOpacity = 1 }
        withAnimation(.easeIn(duration: 0.4).delay(1.7))   { screenOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) { onFinished() }
    }
}
