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
    
    // Look Around scene for the selected location
    @State private var lookAroundScene: MKLookAroundScene?
    
    // Input properties passed from parent view
    var selectedMapItem: MKMapItem?
    var route: MKRoute?
    
    // Favorite Courses
    @State private var isFavorite: Bool = false
    @State private var favoriteCourses: [MKMapItem] = []
    
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
            
            // Favorite button
            Button {
                isFavorite.toggle()
                if let selectedCourse = selectedMapItem {
                    if isFavorite {
                        if !favoriteCourses.contains(selectedCourse) {
                            favoriteCourses.append(selectedCourse)
                            printFavoriteCourses()
                        }
                    } else {
                        if favoriteCourses.contains(selectedCourse) {
                            favoriteCourses.remove(at: favoriteCourses.firstIndex(of: selectedCourse)!)
                            printFavoriteCourses()
                        }
                    }
                }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
            .font(.title3)
        }
    }
    
    // MARK: - Helper Methods
    
    func printFavoriteCourses() {
        print("Favorite Courses:")
        favoriteCourses.forEach { print($0.placemark.title ?? "Unknown Title") }
    }
}

#Preview {
    CourseInfoView()
}
