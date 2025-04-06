//
//  CourseWeatherView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  CourseWeatherView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import MapKit

struct CourseWeatherView: View {
    @StateObject private var weatherService = WeatherService()
    let course: MKMapItem
    
    var body: some View {
        ZStack {
            // Background
            Color.green.opacity(0.1).ignoresSafeArea()
            
            if weatherService.isLoading {
                loadingView
            } else if weatherService.forecasts.isEmpty {
                Text("No weather data available")
                    .foregroundStyle(.secondary)
            } else {
                weatherContentView
            }
        }
        .navigationTitle("\(course.name ?? "Course") Weather")
        .onAppear {
            weatherService.getWeatherForecast(for: course)
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading weather forecast...")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
    }
    
    // Weather content view
    private var weatherContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's weather card
                if let todayForecast = weatherService.forecasts.first {
                    todayWeatherCard(todayForecast)
                }
                
                // 5-day forecast
                fiveDayForecastView
            }
            .padding()
        }
    }
    
    // Today's weather card
    private func todayWeatherCard(_ forecast: WeatherForecast) -> some View {
        VStack(spacing: 15) {
            Text("Today's Weather")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .top, spacing: 20) {
                // Weather icon and temperature
                VStack(spacing: 5) {
                    Image(systemName: forecast.condition.systemImage)
                        .font(.system(size: 50))
                        .foregroundStyle(forecast.condition.color)
                    
                    Text(forecast.condition.rawValue)
                        .font(.headline)
                    
                    Text(forecast.temperatureFormatted)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(minWidth: 120)
                
                // Weather details
                VStack(alignment: .leading, spacing: 10) {
                    Label("Rain: \(forecast.precipitationFormatted)", systemImage: "drop.fill")
                    Label("Wind: \(forecast.windSpeedFormatted)", systemImage: "wind")
                    
                    // Golf-specific assessment
                    HStack {
                        Image(systemName: "figure.golf")
                        Text(weatherService.isGoodDayForGolf(on: forecast.date) ? 
                             "Good conditions for golf" : 
                             "Not ideal for golf")
                        .foregroundStyle(weatherService.isGoodDayForGolf(on: forecast.date) ? .green : .red)
                    }
                }
                .font(.subheadline)
            }
            
            // Weather description
            Text(forecast.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // 5-day forecast
    private var fiveDayForecastView: some View {
        VStack(spacing: 15) {
            Text("5-Day Forecast")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(weatherService.forecasts) { forecast in
                HStack {
                    // Day
                    Text(forecast.date.formatted(.dateTime.weekday(.wide)))
                        .frame(width: 100, alignment: .leading)
                    
                    // Weather icon
                    Image(systemName: forecast.condition.systemImage)
                        .foregroundStyle(forecast.condition.color)
                        .frame(width: 30)
                    
                    // Condition
                    Text(forecast.condition.rawValue)
                        .frame(width: 100, alignment: .leading)
                    
                    Spacer()
                    
                    // Temperature
                    Text(forecast.temperatureFormatted)
                        .fontWeight(.semibold)
                    
                    // Golf-suitable indicator
                    Image(systemName: weatherService.isGoodDayForGolf(on: forecast.date) ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(weatherService.isGoodDayForGolf(on: forecast.date) ? .green : .red)
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview {
    NavigationStack {
        CourseWeatherView(course: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369))))
    }
}