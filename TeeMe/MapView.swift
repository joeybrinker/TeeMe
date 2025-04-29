//
//  MapView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//

import SwiftUI
import MapKit
import FirebaseAuth

// Default location if user location isn't available
extension CLLocationCoordinate2D {
    static let defaultPosition = CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369)
}

struct MapView: View {
    // MARK: - State Properties
    @EnvironmentObject var courseModel: CourseDataModel
    
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var route: MKRoute?
    @State private var locationManager = CLLocationManager()
    @State private var initialSearchPerformed = false
    
    //Ease of use
    @State private var timesloaded: Int8 = 0
    
    // MARK: - View Body
    var body: some View {
        // Main map container
        ZStack{
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
                .onAppear{
                    if timesloaded < 1 {
                        SearchModel(searchResults: $searchResults, visibleRegion: visibleRegion).search(for: "golf course")
                        timesloaded += 1
                    }
                }
            if courseModel.showSignIn {
                AuthView()
            }
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
            
            // Add the route overlay when available
            if let route {
                MapPolyline(route.polyline)
                    .stroke(
                        .green,
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapPitchToggle()
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .safeAreaInset(edge: .bottom) {
            bottomOverlay
        }
    }
    
    // Bottom information panel with course info and search
    private var bottomOverlay: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                
                // Selected location info if available
                if let selectedMapItem {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .frame(height: 160)
                            .foregroundStyle(.ultraThinMaterial)
                        
                        CourseInfoView(selectedMapItem: selectedMapItem, route: route)
                            .frame(height: 128)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                    }
                        
                }
                
                Button {
                    route = nil
                    SearchModel(searchResults: $searchResults, visibleRegion: visibleRegion).search(for: "golf course")
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 35)
                            .frame(width: 128, height: 48)
                            .foregroundColor(.green)
                        Text("Search")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 10)
                }
            }
            Spacer()
        }
        .padding()
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
        .environmentObject(CourseDataModel())
}
