//
//  UpdatedMapView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  UpdatedMapView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import MapKit

struct UpdatedMapView: View {
    // MARK: - State Properties
    @EnvironmentObject var courseModel: CourseDataModel
    
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var route: MKRoute?
    @State private var locationManager = CLLocationManager()
    @State private var initialSearchPerformed = false
    @State private var isSearching = false
    @State private var searchQuery = ""
    
    // MARK: - View Body
    var body: some View {
        // Main map container
        NavigationStack {
            ZStack(alignment: .top) {
                // Main map with markers and controls
                Map(position: $position, selection: $selectedMapItem) {
                    // Show user's current location
                    UserAnnotation()
                    
                    // Display search results
                    ForEach(searchResults, id: \.self) { result in
                        Marker(item: result)
                            .tint(.green)
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
                    MapCompass()
                    MapScaleView()
                }
                .onAppear {
                    locationManager.requestWhenInUseAuthorization()
                    
                    // Initial search after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if !initialSearchPerformed && searchResults.isEmpty {
                            searchNearbyGolfCourses()
                            initialSearchPerformed = true
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .safeAreaInset(edge: .bottom) {
                    // Bottom information panel with course info
                    if let selectedMapItem {
                        EnhancedCourseInfoView(selectedMapItem: selectedMapItem, route: route)
                            .frame(height: 180)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding()
                    }
                }
                .onMapCameraChange { context in
                    visibleRegion = context.region
                }
                .onChange(of: searchResults) { _, _ in
                    position = .automatic
                }
                .onChange(of: selectedMapItem) { _, _ in
                    getDirections()
                }
                
                // Search bar overlay at top
                searchBarView
            }
            .navigationTitle("Find Courses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Show filter options
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    // Search bar at the top
    private var searchBarView: some View {
        VStack {
            if isSearching {
                // Expanded search input
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search for golf courses", text: $searchQuery)
                            .onSubmit {
                                search(for: searchQuery)
                            }
                        
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Button("Cancel") {
                        withAnimation {
                            isSearching = false
                            searchQuery = ""
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(.ultraThinMaterial)
            } else {
                // Collapsed search button
                HStack {
                    Button {
                        withAnimation {
                            isSearching = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search for golf courses")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Spacer()
                    
                    Button {
                        searchNearbyGolfCourses()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            Spacer()
        }
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
    
    // Search for golf courses nearby
    func searchNearbyGolfCourses() {
        search(for: "golf course")
    }
    
    // Perform a search with the given query
    func search(for query: String) {
        // Set up the search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        // Use current visible region or default to a region near the default position
        request.region = visibleRegion ?? MKCoordinateRegion(
            center: .defaultPosition,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        // Perform search asynchronously
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResults = response?.mapItems ?? []
        }
    }
}

// Default location if user location isn't available
extension CLLocationCoordinate2D {
    static let defaultPosition = CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369)
}

#Preview {
    UpdatedMapView()
        .environmentObject(CourseDataModel())
}