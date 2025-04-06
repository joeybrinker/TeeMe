//
//  CourseDataModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  CourseDataModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/18/25.
//  Updated by Claude on 4/1/25.
//

import SwiftUI
import MapKit
import Combine

class CourseDataModel: ObservableObject {
    // Local cache of favorite courses
    @Published var favoriteCourses: [MKMapItem] = []
    
    // CloudKit database manager
    private let cloudDB = CloudKitDatabase()
    
    // Loading state
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Initialize and load favorites from CloudKit
    init() {
        loadFavoritesFromCloud()
    }
    
    // Load favorites from CloudKit
    func loadFavoritesFromCloud() {
        isLoading = true
        
        cloudDB.fetchFavoriteCourses { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let records):
                    // Convert CKRecords to MKMapItems
                    let mapItems = records.compactMap { self?.cloudDB.mapItemFromRecord($0) }
                    self?.favoriteCourses = mapItems
                case .failure(let error):
                    self?.errorMessage = "Failed to load favorites: \(error.localizedDescription)"
                    print("Error loading favorites: \(error)")
                }
            }
        }
    }
    
    // Toggle favorite status for a course
    func toggleFavorite(for course: MKMapItem) -> Bool {
        // Check if course is already a favorite
        if let index = favoriteCourses.firstIndex(of: course) {
            // Remove from favorites
            favoriteCourses.remove(at: index)
            
            // Remove from CloudKit
            cloudDB.deleteFavoriteCourse(with: course.id) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("Successfully removed course from CloudKit")
                    case .failure(let error):
                        // If failed to remove from cloud, revert local state
                        self?.favoriteCourses.append(course)
                        self?.errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
                    }
                }
            }
            
            return false
        } else {
            // Add to favorites locally first
            favoriteCourses.append(course)
            
            // Then add to CloudKit
            cloudDB.saveFavoriteCourse(course) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("Successfully added course to CloudKit")
                    case .failure(let error):
                        // If failed to add to cloud, revert local state
                        if let index = self?.favoriteCourses.firstIndex(of: course) {
                            self?.favoriteCourses.remove(at: index)
                        }
                        self?.errorMessage = "Failed to save favorite: \(error.localizedDescription)"
                    }
                }
            }
            
            return true
        }
    }
    
    // Check if a course is a favorite
    func isFavorite(course: MKMapItem) -> Bool {
        favoriteCourses.contains(course)
    }
}