import SwiftUI
import WeatherKit

struct WeatherForecastView: View {
    @ObservedObject var weatherManager: WeatherKitManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if weatherManager.isLoadingForecast {
                    ProgressView("Loading forecast...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if weatherManager.weeklyForecast.isEmpty {
                    ContentUnavailableView(
                        "No Forecast Available",
                        systemImage: "cloud.slash",
                        description: Text("Unable to load weather forecast for this location.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(weatherManager.weeklyForecast, id: \.date) { dayWeather in
                                WeatherDayRow(dayWeather: dayWeather, usesFahrenheit: weatherManager.usesFahrenheit)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("7-Day Forecast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(weatherManager.usesFahrenheit ? "°F" : "°C") {
                        weatherManager.toggleTemperatureUnit()
                    }
                }
            }
        }
        .onAppear {
            weatherManager.fetchWeeklyForecast()
        }
    }
}

struct WeatherDayRow: View {
    let dayWeather: DayWeather
    let usesFahrenheit: Bool
    
    private var highTemp: Int {
        let temp = usesFahrenheit ?
            dayWeather.highTemperature.converted(to: .fahrenheit) :
            dayWeather.highTemperature.converted(to: .celsius)
        return Int(temp.value)
    }
    
    private var lowTemp: Int {
        let temp = usesFahrenheit ?
            dayWeather.lowTemperature.converted(to: .fahrenheit) :
            dayWeather.lowTemperature.converted(to: .celsius)
        return Int(temp.value)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayWeather.date, format: .dateTime.weekday(.wide))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(dayWeather.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(dayWeather.condition.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Colorful weather symbol
                WeatherSymbolView(symbolName: dayWeather.symbolName)
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .trailing) {
                    Text("\(highTemp)°")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(lowTemp)°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WeatherSymbolView: View {
    let symbolName: String
    
    var body: some View {
        Image(systemName: symbolName)
            .font(.title2)
            .symbolRenderingMode(.multicolor)
            .symbolVariant(.fill)
            .foregroundStyle(symbolColor)
    }
    
    private var symbolColor: Color {
        // Apply colors similar to the Weather app
        switch symbolName {
        case let name where name.contains("sun"):
            return .orange
        case let name where name.contains("cloud.rain"), let name where name.contains("rain"):
            return .blue
        case let name where name.contains("cloud.snow"), let name where name.contains("snow"):
            return .gray
        case let name where name.contains("cloud.bolt"), let name where name.contains("thunderstorm"):
            return .purple
        case let name where name.contains("cloud"):
            return .gray
        case let name where name.contains("wind"):
            return .mint
        case let name where name.contains("fog"):
            return .secondary
        default:
            return .blue
        }
    }
}
