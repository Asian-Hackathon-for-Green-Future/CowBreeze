import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }

            if showSplash {
                SplashView { showSplash = false }
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
    }
}
