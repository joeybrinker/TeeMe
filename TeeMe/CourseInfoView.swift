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
        // Display Look Around preview for the location
        LookAroundPreview(initialScene: lookAroundScene)
            .overlay(alignment: .bottomTrailing) {
                overlayContent
            }
            .onAppear {
                getLookAroundScene()
            }
            .onChange(of: selectedMapItem) { _, _ in
                getLookAroundScene()
            }
    }
    
    // MARK: - UI Components
    
    // Information overlay showing name and travel time
    private var overlayContent: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Location name
            if let name = selectedMapItem?.placemark.name {
                Text(name)
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
    }
    
    // MARK: - Helper Methods
    
    // Load the Look Around scene for the selected location
    func getLookAroundScene() {
        // Reset any existing scene
        lookAroundScene = nil
        
        // Safely unwrap the selectedMapItem
        guard let mapItem = selectedMapItem else { return }
        
        // Fetch the scene asynchronously
        Task {
            let request = MKLookAroundSceneRequest(mapItem: mapItem)
            lookAroundScene = try? await request.scene
        }
    }
}

#Preview {
    CourseInfoView()
}
