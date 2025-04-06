//
//  WeatherService.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import CoreLocation
import MapKit

// Weather forecast for a specific day
struct WeatherForecast: Identifiable {
    var id = UUID()
    var date: Date
    var condition: WeatherCondition
    var temperature: Double // in Celsius
    var precipitation: Double // probability in percentage
    var windSpeed: Double // in km/h
    var description: String
    
    var temperatureFormatted: String {
        return String(format: "%.1f°C", temperature)
    }
    
    var precipitationFormatted: String {
        return String(format: "%.0f%%", precipitation)
    }
    
    var windSpeedFormatted: String {
        return String(format: "%.1f km/h", windSpeed)
    }
}

// Weather conditions
enum WeatherCondition: String, CaseIterable {
    case sunny = "Sunny"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case rainy = "Rainy"
    case thunderstorm = "Thunderstorm"
    case snowy = "Snowy"
    case foggy = "Foggy"
    
    var systemImage: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .foggy: return "cloud.fog.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .sunny: return .yellow
        case .partlyCloudy: return .blue
        case .cloudy: return .gray
        case .rainy: return .blue
        case .thunderstorm: return .purple
        case .snowy: return .blue
        case .foggy: return .gray
        }
    }
    
    // Is this weather good for golf?
    var goodForGolf: Bool {
        switch self {
        case .sunny, .partlyCloudy: return true
        case .cloudy: return true
        case .rainy, .thunderstorm, .snowy, .foggy: return false
        }
    }
}

class WeatherService: ObservableObject {
    @Published var forecasts: [WeatherForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Get weather forecast for a golf course
    func getWeatherForecast(for course: MKMapItem) {
        isLoading = true
        
        // In a real app, you would make an API call to a weather service
        // For now, we'll generate mock data based on the course location
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Generate 5-day forecast
            var generatedForecasts: [WeatherForecast] = []
            
            for i in 0..<5 {
                if let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) {
                    // Generate random but somewhat realistic weather
                    let randomCondition = self?.getRandomWeatherCondition() ?? .sunny
                    
                    // Temperature between 15-30°C
                    let temperature = Double.random(in: 15...30)
                    
                    // Precipitation probability based on condition
                    let precipitation: Double
                    switch randomCondition {
                    case .sunny: precipitation = Double.random(in: 0...5)
                    case .partlyCloudy: precipitation = Double.random(in: 5...20)
                    case .cloudy: precipitation = Double.random(in: 20...40)
                    case .rainy: precipitation = Double.random(in: 70...100)
                    case .thunderstorm: precipitation = Double.random(in: 80...100)
                    case .snowy: precipitation = Double.random(in: 70...100)
                    case .foggy: precipitation = Double.random(in: 40...60)
                    }
                    
                    // Wind speed between 0-30 km/h
                    let windSpeed = Double.random(in: 0...30)
                    
                    // Generate description
                    let description = self?.getWeatherDescription(for: randomCondition, temperature: temperature, precipitation: precipitation, windSpeed: windSpeed) ?? ""
                    
                    // Create forecast
                    let forecast = WeatherForecast(
                        date: date,
                        condition: randomCondition,
                        temperature: temperature,
                        precipitation: precipitation,
                        windSpeed: windSpeed,
                        description: description
                    )
                    
                    generatedForecasts.append(forecast)
                }
            }
            
            self?.forecasts = generatedForecasts
        }
    }
    
    // Get a random weather condition
    private func getRandomWeatherCondition() -> WeatherCondition {
        // More weight to good weather conditions for a golf app
        let weightedConditions: [WeatherCondition] = [
            .sunny, .sunny, .sunny,
            .partlyCloudy, .partlyCloudy,
            .cloudy,
            .rainy,
            .thunderstorm,
            .foggy
        ]
        
        return weightedConditions.randomElement() ?? .sunny
    }
    
    // Generate a descriptive text for the weather condition
    private func getWeatherDescription(for condition: WeatherCondition, temperature: Double, precipitation: Double, windSpeed: Double) -> String {
        switch condition {
        case .sunny:
            if temperature > 28 {
                return "Hot and sunny. Consider wearing sunscreen and staying hydrated."
            } else {
                return "Beautiful sunny day for golf. Enjoy your round!"
            }
            
        case .partlyCloudy:
            return "Partly cloudy skies with excellent visibility. Great day for golf."
            
        case .cloudy:
            if windSpeed > 20 {
                return "Cloudy with some wind. May affect ball flight."
            } else {
                return "Overcast but calm conditions. Good for golf."
            }
            
        case .rainy:
            if precipitation > 80 {
                return "Heavy rain expected. Consider rescheduling."
            } else {
                return "Light rain possible. Bring rain gear."
            }
            
        case .thunderstorm:
            return "Thunderstorms expected. Not recommended for golf due to lightning risk."
            
        case .snowy:
            return "Snow in the forecast. Course likely closed."
            
        case .foggy:
            return "Foggy conditions may limit visibility on the course."
        }
    }
    
    // Assess if the weather is suitable for playing golf
    func isGoodDayForGolf(on date: Date) -> Bool {
        guard let forecast = forecasts.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
            return true // Default to true if we don't have data
        }
        
        // Good conditions: good weather type, low precipitation, reasonable wind
        return forecast.condition.goodForGolf &&
               forecast.precipitation < 50 &&
               forecast.windSpeed < 25
    }
}
