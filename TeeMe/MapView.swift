//
//  MapView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//

import SwiftUI
import MapKit

// Default location if user location isn't available
extension CLLocationCoordinate2D {
    static let defaultPosition = CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369)
}

struct MapView: View {
    // MARK: - State Properties
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var route: MKRoute?
    @State private var locationManager = CLLocationManager()
    @State private var initialSearchPerformed = false
    
    // MARK: - View Body
    var body: some View {
        // Main map container
        mainMapContent
            // Map event handlers
            .onMapCameraChange { context in
                visibleRegion = context.region
            }
            .onChange(of: searchResults) { _, _ in
                position = .automatic
            }
            .onChange(of: selectedMapItem) { _, _ in
                getDirections()
            }
    }
    
    // MARK: - UI Components
    
    // Main map with markers and controls
    private var mainMapContent: some View {
        Map(position: $position, selection: $selectedMapItem) {
            // Show user's current location
            UserAnnotation()
            
            // Display search results
            ForEach(searchResults, id: \.self) { result in
                Marker(item: result)
            }
            .annotationTitles(.hidden)
        }
        .mapControls {
            MapUserLocationButton()
            MapPitchToggle()
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            bottomOverlay
        }
    }
    
    // Bottom information panel with course info and search
    private var bottomOverlay: some View {
        HStack {
            Spacer()
            VStack(spacing: 0) {
                // Selected location info if available
                if let selectedMapItem {
                    CourseInfoView(selectedMapItem: selectedMapItem, route: route)
                        .frame(height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding([.top, .horizontal])
                }
                
                // Search buttons
                SearchButtons(
                    position: $position,
                    searchResults: $searchResults,
                    visibleRegion: visibleRegion
                )
                .padding(.top)
            }
            Spacer()
        }
        .background(.thinMaterial)
    }
    
    // MARK: - Helper Methods
    
    // Calculate directions from user's location to selected destination
    func getDirections() {
        route = nil
        guard let selectedMapItem else { return }
        
        // Determine starting location - use user's actual location if available
        let sourceCoordinate: CLLocationCoordinate2D
        
        if let userLocation = locationManager.location?.coordinate {
            sourceCoordinate = userLocation
        } else {
            sourceCoordinate = .defaultPosition
        }
        
        // Create map items for source and destination
        let sourceMapItem = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
        
        // Set up the directions request
        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = selectedMapItem
        
        // Perform the route calculation asynchronously
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            route = response?.routes.first
        }
    }
}

#Preview {
    MapView()
}
