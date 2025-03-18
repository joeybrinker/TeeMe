//
//  CourseDataModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/18/25.
//

import SwiftUI
import MapKit

class CourseDataModel: ObservableObject {
    @Published var favoriteCourses: [MKMapItem] = []
    
    func toggleFavorite(for course: MKMapItem) -> Bool {
        // Unfavorite Course and Return False
        if let index = favoriteCourses.firstIndex(of: course){
            favoriteCourses.remove(at: index)
            return false
        }
        // Favorite Course and Return True
        else {
            favoriteCourses.append(course)
            return true
        }
    }
    
    // Returns true if favorite, false otherwise
    func isFavorite(course: MKMapItem) -> Bool {
        favoriteCourses.contains(course)
    }
}
