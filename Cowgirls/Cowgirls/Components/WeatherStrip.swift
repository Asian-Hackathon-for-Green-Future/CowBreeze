import SwiftUI

struct WeatherStrip: View {
    let weather: WeatherInfo

    var body: some View {
        HStack(spacing: 0) {
            metric(icon: "thermometer.medium", value: "\(weather.temperature)°C")
            divider
            metric(icon: "humidity.fill", value: "\(weather.humidity)%")
            divider
            metric(icon: "wind", value: String(format: "%.1f m/s", weather.windSpeed))
            divider
            // 풍향: 나침반 기호 + 방향 텍스트
            HStack(spacing: 5) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.cowGreen)
                Text(weather.windDirection)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }

    private func metric(icon: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.cowGreen)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 0.5, height: 16)
    }
}
