//
//  SearchModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/5/25.
//

import MapKit
import SwiftUI

struct SearchModel {
    
    // Bindings to parent view state
    //@Binding var position: MapCameraPosition
    @Binding var searchResults: [MKMapItem]
    
    // Optional region to search within
    var visibleRegion: MKCoordinateRegion?
    
    func search(for query: String) {
        // Set up the search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        // Use current visible region or default to a region near the default position
        request.region = visibleRegion ?? MKCoordinateRegion(
            center: CLLocationManager().location?.coordinate ?? .defaultPosition,
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
