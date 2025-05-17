//
//  WeatherKitManager.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/12/25.
//

import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherKitManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var symbolName: String = "questionmark"
    @Published var usesFahrenheit: Bool = true
    
    private let weatherService = WeatherService.shared
    private var currentTemperature: Measurement<UnitTemperature>?
    
    func fetchWeather(for location: CLLocation) {
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
