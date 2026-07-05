import SwiftUI
import MapKit
import CoreLocation

struct FarmLocationSearchView: View {
    @Binding var address: String
    @Binding var coordinate: CLLocationCoordinate2D
    var onDone: () -> Void

    @State private var cameraPosition: MapCameraPosition
    @State private var isSearching = false
    @State private var searchError: String?

    init(address: Binding<String>, coordinate: Binding<CLLocationCoordinate2D>, onDone: @escaping () -> Void) {
        self._address = address
        self._coordinate = coordinate
        self.onDone = onDone
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(center: coordinate.wrappedValue,
                               span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
            searchBar
            if let err = searchError {
                Text(err).font(.caption).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.bottom, 4)
            }
            mapArea
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            Text("🤠").font(.system(size: 32))
            VStack(alignment: .leading, spacing: 2) {
                Text("COWGIRLS")
                    .font(.system(size: 13, weight: .black)).tracking(3)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Register your farm location")
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
            }
            Spacer()
            Text("1 / 2").font(.caption.bold()).foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .background(LinearGradient(colors: [Color.cowGreenDark, Color.cowGreen],
                                   startPoint: .leading, endPoint: .trailing))
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Search address or place name", text: $address)
                    .submitLabel(.search)
                    .onSubmit { geocodeAddress() }
                if !address.isEmpty {
                    Button { address = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 11)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 돋보기 아이콘 버튼
            if isSearching {
                ProgressView().frame(width: 44)
            } else {
                Button(action: geocodeAddress) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(Color.cowGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var mapArea: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                Annotation("Farm Location", coordinate: coordinate) { FarmPinView() }
            }
            .mapStyle(.standard)

            VStack(spacing: 0) {
                if !address.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill").foregroundStyle(Color.cowGreen)
                        Text(address).font(.caption).lineLimit(1)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                }

                HStack(spacing: 12) {
                    Button("Cancel") {}
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Color(.systemGray5)).foregroundStyle(.primary)
                        .font(.subheadline.bold()).clipShape(RoundedRectangle(cornerRadius: 14))

                    Button("Set This Location", action: onDone)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Color.cowGreen).foregroundStyle(.white)
                        .font(.subheadline.bold()).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(16).background(.ultraThinMaterial)
            }
        }
    }

    @MainActor
    private func geocodeAddress() {
        let query = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        searchError = nil
        Task {
            defer { isSearching = false }
            do {
                // MKLocalSearch handles addresses AND place names / POIs / building names
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                let response = try await MKLocalSearch(request: request).start()
                guard let item = response.mapItems.first else {
                    searchError = "Location not found."; return
                }
                let coord = item.placemark.coordinate
                coordinate = coord
                // Update address to the resolved name for clarity
                if let name = item.name, !name.isEmpty {
                    address = name
                }
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            } catch {
                searchError = "Location not found. Try a different name or address."
            }
        }
    }
}
