import Foundation
import CoreLocation

/// Fetches real weather data from OpenWeatherMap API at regular intervals
final class WeatherService: Sendable {
    // MARK: - Configuration
    // Add your OpenWeatherMap API key to Config.xcconfig or Secrets.plist
    // and reference it here. Never commit real keys to source control.
    private let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OWM_API_KEY") as? String,
              !key.isEmpty else {
            assertionFailure("OpenWeatherMap API key not found. Add OWM_API_KEY to Config.xcconfig")
            return ""
        }
        return key
    }()
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"

    /// Fetches current weather for the given coordinate
    func fetchWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> WeatherInfo {
        let urlString = "\(baseURL)?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        let decoder = JSONDecoder()
        let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)

        return WeatherInfo(
            temperature: Int(weatherResponse.main.temp),
            humidity: weatherResponse.main.humidity,
            windSpeed: weatherResponse.wind.speed,
            windDirection: computeWindDirection(windDegrees: weatherResponse.wind.deg),
            windDegrees: weatherResponse.wind.deg
        )
    }

    private func computeWindDirection(windDegrees: Double) -> String {
        let direction = CompassDirection.nearest(toDegrees: windDegrees)
        return direction.rawValue
    }

    enum WeatherError: LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingError

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid API response"
            case .decodingError: return "Failed to decode weather data"
            }
        }
    }
}

// MARK: - OpenWeatherMap API Response Types

private struct OpenWeatherResponse: Decodable {
    let main: MainWeatherData
    let wind: WindData
}

private struct MainWeatherData: Decodable {
    let temp: Double
    let humidity: Int
}

private struct WindData: Decodable {
    let speed: Double
    let deg: Double
}
