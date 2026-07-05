import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MapDashboardView()
                .tabItem { Label("MAP", systemImage: "map.fill") }

            ReportView()
                .tabItem { Label("REPORT", systemImage: "chart.bar.fill") }

            PolicyView()
                .tabItem { Label("POLICY", systemImage: "building.columns.fill") }

            SettingsView()
                .tabItem { Label("SETTING", systemImage: "gearshape.fill") }
        }
        .tint(Color.cowGreen)
    }
}
