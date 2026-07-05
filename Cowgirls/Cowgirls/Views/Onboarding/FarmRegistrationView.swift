import SwiftUI
import CoreLocation

struct FarmRegistrationView: View {
    @EnvironmentObject var appState: AppState

    let address: String
    let coordinate: CLLocationCoordinate2D

    @State private var farmName: String = ""

    private var isComplete: Bool { !farmName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    formSection(title: "FARM NAME") {
                        TextField("e.g. Ducky's Farm", text: $farmName)
                            .padding(.horizontal, 14).padding(.vertical, 13)
                            .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    formSection(title: "LOCATION") {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill").foregroundStyle(Color.cowGreen)
                            Text(address).font(.subheadline).lineLimit(2)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer(minLength: 12)

                    Button(action: completeOnboarding) {
                        HStack(spacing: 8) {
                            Text("🤠")
                            Text("Complete Registration").font(.headline)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(isComplete ? Color.cowGreen : Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isComplete)
                }
                .padding(.horizontal, 20).padding(.vertical, 24)
            }
        }
        .background(Color(.systemBackground))
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            Text("🤠").font(.system(size: 32))
            VStack(alignment: .leading, spacing: 2) {
                Text("COWGIRLS")
                    .font(.system(size: 13, weight: .black)).tracking(3)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Enter your farm details")
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
            }
            Spacer()
            Text("2 / 2").font(.caption.bold()).foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .background(LinearGradient(colors: [Color.cowGreenDark, Color.cowGreen],
                                   startPoint: .leading, endPoint: .trailing))
    }

    @ViewBuilder
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.footnote.bold()).foregroundStyle(.secondary).tracking(0.5)
            content()
        }
    }

    private func completeOnboarding() {
        appState.farm = Farm(name: farmName.trimmingCharacters(in: .whitespaces),
                             address: address, coordinate: coordinate, livestock: [])
        appState.hasCompletedOnboarding = true
        appState.refreshPopulatedDirections()
        appState.refreshCityName()
        appState.startWeatherPolling()
    }
}
