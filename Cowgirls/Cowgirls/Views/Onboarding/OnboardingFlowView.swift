import SwiftUI
import CoreLocation

/// Coordinates the two-step onboarding flow: pick a location on the map,
/// then fill in farm name / livestock counts.
struct OnboardingFlowView: View {
    enum Step {
        case location
        case details
    }

    @State private var step: Step = .location
    @State private var address: String = "경기도 양주시 화합면 327번길"
    @State private var coordinate = CLLocationCoordinate2D(latitude: 37.7853, longitude: 127.0454)

    var body: some View {
        switch step {
        case .location:
            FarmLocationSearchView(address: $address, coordinate: $coordinate) {
                step = .details
            }
        case .details:
            FarmRegistrationView(address: address, coordinate: coordinate)
        }
    }
}
