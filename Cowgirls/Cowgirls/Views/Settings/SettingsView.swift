import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section("Farm Info") {
                    LabeledContent("Farm Name", value: appState.farm.name)
                    LabeledContent("Location",  value: appState.farm.address)
                }

                Section("Area Analysis") {
                    if appState.isAnalyzingDirections {
                        HStack { ProgressView(); Text("Analyzing...") }
                    } else if appState.populatedDirections.isEmpty {
                        Text("No urban areas detected in any direction.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Urban directions: " + appState.populatedDirections.map(\.rawValue).sorted().joined(separator: ", "))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Re-analyze") { appState.refreshPopulatedDirections() }
                        .disabled(appState.isAnalyzingDirections)
                }

                Section("Notifications") {
                    Button("Request Permission") {
                        NotificationManager.shared.requestAuthorization()
                    }
                    Button("Send Test Alert (5s)") {
                        NotificationManager.shared.scheduleSprayReminder()
                    }
                    Text("After scheduling, background the app or lock your screen to see the notification with Spray / Cancel actions.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("App Info") {
                    LabeledContent("Version", value: "1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
