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
    private let db = Firestore.firestore()
    
    init() {
        loadFavoritesFromFirebase()
    }
    
    // MARK: - Firebase Functions
    
    // Load favorites from firebase
    func loadFavoritesFromFirebase(){
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userID).collection("favorites").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading favorites: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Clear current favorites
            self.favoriteCourses.removeAll()
            
            // Process each course and its info
            for document in documents {
                let data = document.data()
                
                // Get location by coordinates
                guard let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let name = data["name"] as? String else { continue }
                
                // create address for the mapItem
                var addressDictionary: [String: Any] = [:]
                
                if let street = data["street"] as? String {
                    addressDictionary[CNPostalAddressStreetKey] = street
                }
                if let city = data["city"] as? String {
                    addressDictionary[CNPostalAddressCityKey] = city
                }
                if let state = data["state"] as? String {
                    addressDictionary[CNPostalAddressStateKey] = state
                }
                if let postalCode = data["postalCode"] as? String {
                    addressDictionary[CNPostalAddressPostalCodeKey] = postalCode
                }
                
                
                // Create mapItem & placemark
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = name
                
                // Other properties if available
                if let phoneNumber = data["phoneNumber"] as? String {
                    mapItem.phoneNumber = phoneNumber
                }
                if let websiteString = data["website"] as? String, let url = URL(string: websiteString) {
                    mapItem.url = url
                }
                
                // Add to favorites array
                self.favoriteCourses.append(mapItem)
            }
        }
    }
    
    // Save to Firebase
    private func saveToFirebase(_ course: MKMapItem) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Create a document ID from course's unique identifier or generate one
        let lat = course.placemark.coordinate.latitude
        let long = course.placemark.coordinate.longitude
        let documentId = "\(lat)_\(long)".replacingOccurrences(of: ".", with: "_")
        
        // Create a dictionary with course data
        var courseData: [String: Any] = [
            "name": course.name ?? "Unknown Course",
            "latitude": lat,
            "longitude": long,
            ]
        
        // Other properties if available
        if let phoneNumber = course.phoneNumber {
            courseData["phoneNumber"] = phoneNumber
        }
        if let website = course.url {
            courseData["website"] = website.absoluteString
        }
        if let postalAddress = course.placemark.postalAddress {
            courseData["street"] = postalAddress.street
            courseData["city"] = postalAddress.city
            courseData["state"] = postalAddress.state
            courseData["postalCode"] = postalAddress.postalCode
        }
        
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
    
    func toggleFavorite(for course: MKMapItem) -> Bool {
        // Unfavorite Course and Return False
        if let index = favoriteCourses.firstIndex(of: course){
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
    
    // Returns true if favorite, false otherwise
    func isFavorite(course: MKMapItem) -> Bool {
        self.favoriteCourses.contains(course)
    }
}

