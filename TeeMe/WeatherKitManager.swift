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
    @Published var temperature: String = "Connecting to Apple Weather Services"
    @Published var symbolName: String = "xmark"
    
    private let weatherService = WeatherService.shared
    
    func fetchWeather(for location: CLLocation) {
        Task {
            do {
                let current = try await weatherService.weather(for: location, including: .current)
                let formatter = MeasurementFormatter()
                formatter.unitOptions = .providedUnit
                let tempString = formatter.string(from: current.temperature)
                temperature = tempString
                symbolName = current.symbolName
            } catch {
                print("WeatherKit error:", error)
            }
        }
    }
}
