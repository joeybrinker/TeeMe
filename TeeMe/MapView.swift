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
    @State private var searchText: String = ""
    @State private var isShowingInfo: Bool = false
    @State private var isShowingDetails: Bool = false
    
    @State var timesloaded: Int8 = 0
    
    @FocusState private var searchIsFocused: Bool
    
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
                .onChange(of: selectedMapItem) { _, newValue in
                    getDirections()
                    if newValue != nil {
                        isShowingInfo = true
                    }
                    else {
                        isShowingInfo = false
                        searchIsFocused = false
                    }
                }
                .onAppear{
                    locationManager.requestWhenInUseAuthorization()
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
            .annotationSubtitles(.automatic)
            
            // Add the route overlay when available
            if let route {
                // Create a wider, blurred line for the glow effect
                MapPolyline(route.polyline)
                    .stroke( Color.green.opacity(0.5), style: StrokeStyle( lineWidth: 8, lineCap: .round, lineJoin: .round))
                
                // Main route line with a gradient
                MapPolyline(route.polyline)
                    .stroke(.green, style: StrokeStyle(lineWidth: 4,lineCap: .round,lineJoin: .round))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            centerUserLocationButton
        }
        .overlay(alignment: .top) {
            searchBar
        }
        .overlay(alignment: .bottom) {
            searchButton
        }
        .onSubmit {
            if !searchText.isEmpty {
                SearchModel(searchResults: $searchResults, visibleRegion: visibleRegion).search(for: searchText)
                searchIsFocused = false
                searchText = ""
            }
            else {
                searchIsFocused = false
                searchText = ""
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        
        
        //Course Info View Sheet
        .sheet(isPresented: $isShowingInfo, content: {
            bottomOverlay
                .presentationDetents([.height(200), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(200)))
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        })
        .mapItemDetailSheet(isPresented: $isShowingDetails, item: selectedMapItem)
    }
    
    // Search bar
    private var searchBar: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.thinMaterial)
            HStack{
                Image(systemName: "magnifyingglass")
                    .font(.body)
                TextField("Search for a course...", text: $searchText)
                    .autocorrectionDisabled()
                    .font(.subheadline)
                    .frame(maxWidth: 350, maxHeight: 50)
                    .onSubmit {
                        searchText = ""
                        searchIsFocused = false
                    }
                    .focused($searchIsFocused)
                if !searchText.isEmpty {
                    Image(systemName: "xmark.circle.fill")
                        .onTapGesture {
                            searchText = ""
                            searchIsFocused = false
                        }
                }
            }
            .padding()
        }
        .frame(maxWidth: 350, maxHeight: 50)
    }
    
    // Center user location button
    private var centerUserLocationButton: some View {
        Button{
            centerOnUserLocation()
        } label: {
            ZStack {
                Image(systemName: "location")
                    .frame(width: 44, height: 44)
                    .font(.system(size: 19.5))
                    .foregroundColor(.green)
                    .background(.thickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 4)
            }
        }
        .padding()
    }
    
    // Search / load button
    private var searchButton: some View {
        Button {
            route = nil
            if searchIsFocused {
                if !searchText.isEmpty {
                    SearchModel(searchResults: $searchResults, visibleRegion: visibleRegion).search(for: searchText)
                    searchIsFocused = false
                    searchText = ""
                }
                else {
                    searchIsFocused = false
                    searchText = ""
                }
            }
            else {
                SearchModel(searchResults: $searchResults, visibleRegion: visibleRegion).search(for: "Golf Course")
            }
            
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 35)
                    .frame(width: 128, height: 48)
                    .foregroundColor(.green)
                Text(searchIsFocused ? "Search" : "Load")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding()
            .shadow(radius: 10)
        }
    }
    
    // Bottom information panel with course info and search
    private var bottomOverlay: some View {
        VStack{
            // Selected location info if available
            if let selectedMapItem {
                CourseInfoView(selectedMapItem: selectedMapItem, route: route)
                    .padding()
            }
            
            Button {
                isShowingInfo = false
                isShowingDetails = true
                print("Showing Details")
            } label: {
                Text("More Details")
                    .foregroundStyle(.primary)
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
    
    // To replace the MapUserLocationButton() map control
    func centerOnUserLocation() {
        if let userLocation = locationManager.location?.coordinate {
            // Animate to user location with zoom level
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
}

#Preview {
    MapView()
        .environmentObject(CourseDataModel())
}

