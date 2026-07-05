import Foundation

struct WeatherInfo {
    var temperature: Int      // °C
    var humidity: Int         // %
    var windSpeed: Double     // m/s
    var windDirection: String // e.g. "NNE"
    var windDegrees: Double   // compass degrees, used to rotate the wind arrow icon
}
