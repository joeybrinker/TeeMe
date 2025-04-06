//
//  CourseInfoView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//

import SwiftUI
import MapKit

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
                    isFavorited = courseModel.isFavorite(course: course)
                }
            }
    }
    
    // MARK: - UI Components
    
    // Information overlay showing name and travel time
    private var overlayContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Location name
                if let name = selectedMapItem?.name {
                    Text(name)
                        .font(.headline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                }
                
                // Phone number if available
                if let phoneNumber = selectedMapItem?.phoneNumber {
                    Text(phoneNumber)
                        .font(.headline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                }
                
                // Address if available
                if let address = selectedMapItem?.placemark.postalAddress {
                    let completeAddress = "\(address.street), \(address.city), \(address.state)"
                    Text(completeAddress)
                        .font(.headline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                }
                
                // Travel time if available
                if let time = travelTime {
                    Text("Travel time: \(time)")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                }
            }
            .padding(12)
            
            // Favorite button - updated to use the course model
            Button {
                if let selectedCourse = selectedMapItem {
                    isFavorited = courseModel.toggleFavorite(for: selectedCourse)
                }
            } label: {
                Image(systemName: courseModel.isFavorite(course: selectedMapItem!) ? "star.fill" : "star")
                    .foregroundStyle(.green)
            }
            .font(.title3)
        }
    }
}

#Preview {
    CourseInfoView()
        .environmentObject(CourseDataModel())
}
