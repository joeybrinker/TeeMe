//
//  SearchButtons.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//

import SwiftUI
import MapKit

struct SearchButtons: View {
    // MARK: - Properties
    
    // Bindings to parent view state
    @Binding var position: MapCameraPosition
    @Binding var searchResults: [MKMapItem]
    
    // Optional region to search within
    var visibleRegion: MKCoordinateRegion?
    
    // MARK: - View Body
    var body: some View {
        HStack(spacing: 12) {
            // Search for golf courses
            Button {
                search(for: "golf course")
            } label: {
                Label("Golf Course", systemImage: "figure.golf")
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.green)
            
            // You can add more search buttons here
            // For example:
            /*
            Button {
                search(for: "driving range")
            } label: {
                Label("Driving Range", systemImage: "sportscourt")
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.blue)
            */
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Methods
    
    // Perform a local search for the specified query
    func search(for query: String) {
        // Set up the search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        // Use current visible region or default to a region near the default position
        request.region = visibleRegion ?? MKCoordinateRegion(
            center: .defaultPosition,
            span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
        )
        
        // Perform search asynchronously
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResults = response?.mapItems ?? []
        }
    }
}
