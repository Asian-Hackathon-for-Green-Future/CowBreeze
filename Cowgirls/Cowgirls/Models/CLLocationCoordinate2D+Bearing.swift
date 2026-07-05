import CoreLocation

extension CLLocationCoordinate2D {
    /// Returns a coordinate offset from `self` by the given bearing
    /// (degrees, 0 = north, clockwise) and distance in meters.
    /// Uses a spherical-earth approximation — accurate enough at the
    /// few-kilometer scale this app works at.
    func offset(bearingDegrees: Double, distanceMeters: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let bearing = bearingDegrees * .pi / 180
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180

        let angularDistance = distanceMeters / earthRadius
        let lat2 = asin(sin(lat1) * cos(angularDistance) + cos(lat1) * sin(angularDistance) * cos(bearing))
        let lon2 = lon1 + atan2(
            sin(bearing) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2)
        )

        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
}
