//
//  CourseDataModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/18/25.
//

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
import Contacts

class CourseDataModel: ObservableObject {
    
    @Published var favoriteCourses: [MKMapItem] = []
    @Published var showSignIn: Bool = false
    
    private let db = Firestore.firestore()
    private var isLoading = false // Add loading flag
    
    init() {
        loadFavoritesFromFirebase()
    }
    
    // MARK: - Firebase Functions
    
    // Load favorites from firebase
    func loadFavoritesFromFirebase() {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        db.collection("users").document(userID).collection("favorites").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            defer { self.isLoading = false } // Reset loading flag when done
            
            if let error = error {
                print("Error loading favorites: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Clear current favorites on main thread
            DispatchQueue.main.async {
                self.favoriteCourses.removeAll()
            }
            
            // Create a task group to handle all async operations
            Task {
                await withTaskGroup(of: MKMapItem?.self) { group in
                    // Add a task for each document
                    for document in documents {
                        group.addTask {
                            let data = document.data()
                            
                            guard let latitude = data["latitude"] as? Double,
                                  let longitude = data["longitude"] as? Double,
                                  let name = data["name"] as? String else { return nil }
                            
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            
                            // Try to find the original item
                            if let originalItem = await self.findOriginalMapItem(
                                withName: name,
                                coordinate: coordinate
                            ) {
                                return originalItem
                            } else {
                                // Fallback: Create minimal reconstructed item
                                let placemark = MKPlacemark(coordinate: coordinate)
                                let tempMapItem = MKMapItem(placemark: placemark)
                                tempMapItem.name = name
                                return tempMapItem
                            }
                        }
                    }
                    
                    // Collect all results and update on main thread
                    var newFavorites: [MKMapItem] = []
                    for await result in group {
                        if let mapItem = result {
                            newFavorites.append(mapItem)
                        }
                    }
                    
                    // Update the published property on main thread
                    await MainActor.run {
                        self.favoriteCourses = newFavorites
                    }
                }
            }
        }
    }
    
    // MARK: - CHANGE: Simplified save method with minimal data
    private func saveToFirebase(_ course: MKMapItem) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Create a document ID from course coordinates
        let lat = course.placemark.coordinate.latitude
        let long = course.placemark.coordinate.longitude
        let documentId = "\(lat)_\(long)".replacingOccurrences(of: ".", with: "_")
        
        // MARK: - CHANGE: Store only the minimal required fields
        let courseData: [String: Any] = [
            "name": course.name ?? "Unknown Course",
            "latitude": lat,
            "longitude": long
        ]
        
        // Save to firestore
        db.collection("users").document(userId).collection("favorites").document(documentId).setData(courseData) {
            error in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                print("Saving Worked!")
            }
        }
    }
    
    // Remove from Firebase
    private func removeFromFirebase(_ course: MKMapItem) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        // Get document ID
        let lat = course.placemark.coordinate.latitude
        let long = course.placemark.coordinate.longitude
        let documentId = "\(lat)_\(long)".replacingOccurrences(of: ".", with: "_")
        
        // Delete from firestore
        db.collection("users").document(userID).collection("favorites").document(documentId).delete { error in
            if let error = error {
                print("Error deleting document: \(error.localizedDescription)")
            } else {
                print("Successfully deleted document")
            }
        }
    }
    
    // MARK: - MapItem Functions
    
    // MARK: - CHANGE: Optimized search function that only needs name and coordinates
    func findOriginalMapItem(withName name: String, coordinate: CLLocationCoordinate2D) async -> MKMapItem? {
        let searchRequest = MKLocalSearch.Request()
        
        // Use the name as the search query - essential for finding the original item
        searchRequest.naturalLanguageQuery = name
        
        // Use a small region centered on the saved coordinates to narrow results
        searchRequest.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        do {
            let search = MKLocalSearch(request: searchRequest)
            let response = try await search.start()
            
            // Find a matching item by comparing coordinates and name
            return response.mapItems.first { item in
                let itemCoord = item.placemark.coordinate
                let distance = CLLocation(latitude: itemCoord.latitude, longitude: itemCoord.longitude)
                    .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                
                // Match if distance is less than 50 meters and names match
                print("Search Worked")
                return distance < 50 && item.name == name
            }
        } catch {
            print("Search failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - CHANGE: Updated to use the correct identifier in toggleFavorite
    func toggleFavorite(for course: MKMapItem) -> Bool {
        // Check if this course is already a favorite by comparing coordinates
        let courseCoord = course.placemark.coordinate
        if let index = favoriteCourses.firstIndex(where: { favoriteItem in
            let favoriteCoord = favoriteItem.placemark.coordinate
            let distance = CLLocation(latitude: courseCoord.latitude, longitude: courseCoord.longitude)
                .distance(from: CLLocation(latitude: favoriteCoord.latitude, longitude: favoriteCoord.longitude))
            
            return distance < 10 && favoriteItem.name == course.name
        }) {
            // Unfavorite Course and Return False
            self.favoriteCourses.remove(at: index)
            removeFromFirebase(course)
            return false
        }
        // Favorite Course and Return True
        else {
            self.favoriteCourses.append(course)
            saveToFirebase(course)
            return true
        }
    }
    
    // MARK: - CHANGE: Updated favorite check methods to use coordinate comparison
    func isFavorite(courseName: String) -> Bool {
        return favoriteCourses.contains(where: { $0.name == courseName })
    }
    
    func isFavorite(course: MKMapItem) -> Bool {
        let courseCoord = course.placemark.coordinate
        
        return favoriteCourses.contains { favoriteItem in
            let favoriteCoord = favoriteItem.placemark.coordinate
            let distance = CLLocation(latitude: courseCoord.latitude, longitude: courseCoord.longitude)
                .distance(from: CLLocation(latitude: favoriteCoord.latitude, longitude: favoriteCoord.longitude))
            
            // Consider it the same course if they're within 10 meters and have the same name
            return distance < 10 && favoriteItem.name == course.name
        }
    }

    func search(for query: String) {
        // Set up the search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        // Use current visible region or default to a region near the default position
        request.region = MKCoordinateRegion(
            center: CLLocationManager().location?.coordinate ?? .defaultPosition,
            span: MKCoordinateSpan(latitudeDelta: .infinity, longitudeDelta: .infinity)
        )
        
        // Perform search asynchronously
        Task {
            let search = MKLocalSearch(request: request)
            _ = try? await search.start()
        }
    }
}
