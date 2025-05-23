//
//  CourseInfoView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//

import SwiftUI
import MapKit
import FirebaseAuth

struct CourseInfoView: View {
    // MARK: - Properties
    
    // Add this line to use the shared model
    @EnvironmentObject var courseModel: CourseDataModel
    
    // Look Around scene for the selected location
    @State private var lookAroundScene: MKLookAroundScene?
    
    // Input properties passed from parent view
    var selectedMapItem: MKMapItem?
    var route: MKRoute?
    
    // Favorite state
    @State private var isFavorited: Bool = false
    
    // Weather
    @StateObject private var weatherManager = WeatherKitManager()
    
    
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
        // Main content view
        overlayContent
            .onAppear {
                // Set initial favorite state when view appears
                if let course = selectedMapItem {
                    isFavorited = courseModel.isFavorite(courseName: course.placemark.name ?? "")
                    weatherManager.fetchWeather(for: CLLocation(latitude: selectedMapItem?.placemark.coordinate.latitude ?? 0, longitude: selectedMapItem?.placemark.coordinate.longitude ?? 0))
                }
            }
    }
    
    // MARK: - UI Components
    
    // Information overlay showing name and travel time
    private var overlayContent: some View {
        //        VStack{
        //            HStack {
        VStack(alignment: .center, spacing: 5) {
            // Location name
            if let name = selectedMapItem?.name {
                Text(name)
                    .font(.title)
                    .padding()
                    .lineLimit(1)
                    .allowsTightening(true)
            }
            
            
            HStack {
                // Travel time if available
                if let time = travelTime {
                    Text("Travel time: \(time)")
                }
                else {
                    Text("Travel time: ")
                }
                
                Spacer()
                
                Label(weatherManager.temperature, systemImage: weatherManager.symbolName)
            }
            .padding(.horizontal)
            
            // Favorite button - updated to use the course model
            HStack{
                Text(isFavorited ? "Remove from favorites" : "Add to favorites")
                
                Spacer()
                
                Button {
                    if Auth.auth().currentUser != nil{
                        if let selectedCourse = selectedMapItem {
                            isFavorited = courseModel.toggleFavorite(for: selectedCourse)
                            courseModel.showSignIn = false
                            print(selectedCourse.id)
                        }
                    }
                    else {
                        courseModel.showSignIn = true
                    }
                } label: {
                    Image(systemName: courseModel.isFavorite(courseName: selectedMapItem?.placemark.name ?? "") ? "star.fill" : "star")
                        .foregroundStyle(.green)
                }
                .font(.title3)
            }
            .padding()
        }
    }
}

#Preview {
    CourseInfoView()
        .environmentObject(CourseDataModel())
}
