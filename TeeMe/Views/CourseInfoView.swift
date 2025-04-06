//
//  EnhancedCourseInfoView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  EnhancedCourseInfoView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import MapKit

struct EnhancedCourseInfoView: View {
    // MARK: - Properties
    
    @EnvironmentObject var courseModel: CourseDataModel
    @StateObject private var weatherService = WeatherService()
    
    // Look Around scene for the selected location
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showingLookAround = false
    @State private var showingWeather = false
    @State private var showingTeeTimeBooking = false
    
    // Input properties passed from parent view
    var selectedMapItem: MKMapItem?
    var route: MKRoute?
    
    // Favorite state
    @State private var isFavorited: Bool = false
    
    // MARK: - Computed Properties
    
    // Formatted travel time for the route
    private var travelTime: String? {
        guard let route else { return nil }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: route.expectedTravelTime)
    }
    
    // MARK: - View Body
    var body: some View {
        VStack(spacing: 0) {
            // Main content view
            infoCard
            
            // Action buttons
            actionButtons
        }
        .onAppear {
            // Set initial favorite state when view appears
            if let course = selectedMapItem {
                isFavorited = courseModel.isFavorite(course: course)
                
                // Start loading weather data
                weatherService.getWeatherForecast(for: course)
                
                // Try to get a look around scene
                getLookAroundScene()
            }
        }
        .sheet(isPresented: $showingLookAround) {
            if let lookAroundScene = lookAroundScene {
                LookAroundPreview(initialScene: lookAroundScene)
                    .ignoresSafeArea()
            } else {
                Text("Look Around preview not available for this location")
                    .padding()
            }
        }
        .sheet(isPresented: $showingWeather) {
            if let course = selectedMapItem {
                CourseWeatherView(course: course)
            }
        }
        .sheet(isPresented: $showingTeeTimeBooking) {
            bookTeeTimeView
        }
    }
    
    // MARK: - UI Components
    
    // Card with course information
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Course name
            if let name = selectedMapItem?.name {
                Text(name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 12)
            }
            
            // Basic info in horizontal layout
            HStack(alignment: .top) {
                // Left column: address and contact info
                VStack(alignment: .leading, spacing: 8) {
                    // Address
                    if let address = selectedMapItem?.placemark.postalAddress {
                        VStack(alignment: .leading, spacing: 4) {
                            Label {
                                Text("\(address.street)")
                            } icon: {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(.red)
                            }
                            
                            Text("\(address.city), \(address.state)")
                                .padding(.leading, 24)
                        }
                        .font(.subheadline)
                    }
                    
                    // Phone number
                    if let phoneNumber = selectedMapItem?.phoneNumber {
                        Label {
                            Text(phoneNumber)
                        } icon: {
                            Image(systemName: "phone")
                                .foregroundStyle(.green)
                        }
                        .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right column: travel info and weather preview
                VStack(alignment: .trailing, spacing: 8) {
                    // Travel time
                    if let time = travelTime {
                        Label {
                            Text(time)
                        } icon: {
                            Image(systemName: "car")
                                .foregroundStyle(.blue)
                        }
                        .font(.subheadline)
                    }
                    
                    // Current weather (if available)
                    if let todayForecast = weatherService.forecasts.first {
                        HStack {
                            Image(systemName: todayForecast.condition.systemImage)
                                .foregroundStyle(todayForecast.condition.color)
                            
                            Text(todayForecast.temperatureFormatted)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)
            
            // Weather summary
            if let todayForecast = weatherService.forecasts.first {
                HStack {
                    Text("Today: \(weatherService.isGoodDayForGolf(on: todayForecast.date) ? "Good for golf" : "Not ideal for golf")")
                        .font(.caption)
                        .foregroundStyle(weatherService.isGoodDayForGolf(on: todayForecast.date) ? .green : .red)
                    
                    Spacer()
                    
                    Button("See full forecast") {
                        showingWeather = true
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Action buttons for the course
    private var actionButtons: some View {
        HStack(spacing: 15) {
            // Favorite button
            Button {
                if let selectedCourse = selectedMapItem {
                    isFavorited = courseModel.toggleFavorite(for: selectedCourse)
                }
            } label: {
                VStack {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .font(.system(size: 22))
                    Text("Favorite")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(isFavorited ? .yellow : .gray)
            
            // Look Around button
            Button {
                showingLookAround = true
            } label: {
                VStack {
                    Image(systemName: "binoculars")
                        .font(.system(size: 22))
                    Text("Look Around")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.blue)
            .disabled(lookAroundScene == nil)
            .opacity(lookAroundScene == nil ? 0.5 : 1.0)
            
            // Book Tee Time button
            Button {
                showingTeeTimeBooking = true
            } label: {
                VStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 22))
                    Text("Book Tee Time")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider(), alignment: .top)
    }
    
    // Book tee time sheet
    private var bookTeeTimeView: some View {
        NavigationStack {
            VStack {
                if let course = selectedMapItem {
                    TeeTimeSelectionView(course: course)
                } else {
                    Text("Course information not available")
                }
            }
            .navigationTitle("Book Tee Time")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helper Methods
    
    // Get Look Around scene for the location
    private func getLookAroundScene() {
        guard let coordinate = selectedMapItem?.placemark.coordinate else { return }
        
        let lookAroundSceneRequest = MKLookAroundSceneRequest(coordinate: coordinate)
        lookAroundSceneRequest.getSceneWithCompletionHandler { scene, error in
            DispatchQueue.main.async {
                self.lookAroundScene = scene
            }
        }
    }
}

// Simple view to select a tee time (would be replaced by full TeeTimeBookingView)
struct TeeTimeSelectionView: View {
    let course: MKMapItem
    let times = [
        "7:00 AM",
        "7:15 AM",
        "7:30 AM",
        "7:45 AM",
        "8:00 AM",
        "8:15 AM",
        "8:30 AM",
        "8:45 AM",
        "9:00 AM"
    ]
    
    var body: some View {
        VStack {
            // Date selector
            DatePicker("Select Date", selection: .constant(Date().addingTimeInterval(86400)), in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
            
            Divider()
            
            // Available times
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(times, id: \.self) { time in
                        Button {
                            // Would navigate to detailed booking
                        } label: {
                            Text(time)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// Preview for Look Around
struct LookAroundPreview: UIViewControllerRepresentable {
    let initialScene: MKLookAroundScene
    
    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        let viewController = MKLookAroundViewController(scene: initialScene)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
        // Nothing to update
    }
}

#Preview {
    EnhancedCourseInfoView()
        .environmentObject(CourseDataModel())
}
