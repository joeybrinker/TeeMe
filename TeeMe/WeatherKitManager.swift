import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherKitManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var symbolName: String = "questionmark"
    @Published var usesFahrenheit: Bool = true
    @Published var weeklyForecast: [DayWeather] = []
    @Published var isLoadingForecast: Bool = false
    
    private let weatherService = WeatherService.shared
    private var currentTemperature: Measurement<UnitTemperature>?
    private var currentLocation: CLLocation?
    
    func fetchWeather(for location: CLLocation) {
        currentLocation = location
        Task {
            do {
                let current = try await weatherService.weather(for: location, including: .current)
                self.currentTemperature = current.temperature
                updateTemperatureDisplay()
                symbolName = current.symbolName
            } catch {
                print("WeatherKit error:", error)
            }
        }
    }
    
    func fetchWeeklyForecast() {
        guard let location = currentLocation else { return }
        
        isLoadingForecast = true
        
        Task {
            do {
                let weather = try await weatherService.weather(for: location, including: .daily)
                weeklyForecast = Array(weather.forecast.prefix(7)) // Get 7 days
                isLoadingForecast = false
            } catch {
                print("Weekly forecast error:", error)
                isLoadingForecast = false
            }
        }
    }
    
    func toggleTemperatureUnit() {
        usesFahrenheit.toggle()
        updateTemperatureDisplay()
    }
    
    private func updateTemperatureDisplay() {
        guard let temp = currentTemperature else { return }
        
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 0
        
        // Convert to the preferred unit
        let displayTemp = usesFahrenheit ?
            temp.converted(to: .fahrenheit) :
            temp.converted(to: .celsius)
        
        temperature = formatter.string(from: displayTemp)
    }
}
