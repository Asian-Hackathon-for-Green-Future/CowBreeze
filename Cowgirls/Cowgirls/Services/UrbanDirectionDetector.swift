import Foundation
import MapKit
import CoreLocation

/// Roughly estimates, for each of the 4 cardinal directions from a farm,
/// whether there appears to be a populated / built-up area nearby — used
/// to flag which wind directions carry odor risk toward people.
///
/// This is a lightweight on-device heuristic (no extra API key or server
/// needed): it samples a few points along each bearing and reverse-geocodes
/// them with MapKit. If a sample resolves to a real street-level address
/// (has both a locality and a thoroughfare), we treat that as a sign of a
/// residential/urban area in that direction. Open fields, mountains, and
/// paddies usually don't resolve to a specific street address.
///
/// For production accuracy, this should be swapped out for (or combined
/// with) an authoritative source — e.g. Statistics Korea's SGIS population
/// grid API, or 국토교통부 land-use (용도지역지구) data — which can say
/// "this is a residential zone" definitively instead of guessing from
/// address density. This heuristic is a reasonable stand-in until that's
/// wired up, and can also be used to pre-fill a suggestion that the farmer
/// confirms/edits during onboarding.
struct UrbanDirectionDetector: Sendable {
    /// Distances (meters) to sample along each bearing, near → far.
    var sampleDistances: [Double] = [1_000, 2_500, 4_500]

    func detectPopulatedDirections(from origin: CLLocationCoordinate2D) async -> Set<CompassDirection> {
        var result: Set<CompassDirection> = []

        await withTaskGroup(of: (CompassDirection, Bool).self) { group in
            for direction in CompassDirection.allCases {
                group.addTask {
                    let populated = await isDirectionPopulated(direction, from: origin)
                    return (direction, populated)
                }
            }
            for await (direction, populated) in group {
                if populated { result.insert(direction) }
            }
        }

        return result
    }

    private func isDirectionPopulated(_ direction: CompassDirection, from origin: CLLocationCoordinate2D) async -> Bool {
        for distance in sampleDistances {
            let sample = origin.offset(bearingDegrees: direction.bearingDegrees, distanceMeters: distance)
            if await isBuiltUp(sample) {
                return true
            }
        }
        return false
    }

    private func isBuiltUp(_ coordinate: CLLocationCoordinate2D) async -> Bool {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return false }

        do {
            let mapItems = try await request.mapItems
            guard let placemark = mapItems.first?.placemark else { return false }

            // 한국 농촌 주소 특성 반영:
            // - thoroughfare(도로명)는 도시 지역에만 잘 잡힘
            // - subLocality(동/리)는 농촌 마을도 잡힘 → 이것만으로도 충분
            // - name만 있어도(POI 등) 사람이 있다는 신호
            let hasStreetLevel = placemark.thoroughfare != nil || placemark.subThoroughfare != nil
            let hasNeighborhood = placemark.subLocality != nil
            let hasLocality = placemark.locality != nil
            let hasName = mapItems.first?.name != nil

            // 조건 완화: subLocality + locality 조합이면 마을로 판단
            return (hasLocality && hasNeighborhood)
                || (hasLocality && hasStreetLevel)
                || (hasNeighborhood && hasName)
        } catch {
            return false
        }
    }
}
