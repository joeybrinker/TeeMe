//
//  FavoritesView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/18/25.
//

import SwiftUI
import MapKit
import FirebaseAuth

struct FavoritesView: View {
    @EnvironmentObject var courseModel: CourseDataModel
    @State private var selectedCourse: MKMapItem?
    
    var body: some View {
        NavigationStack {
            VStack {
                if courseModel.favoriteCourses.isEmpty ||  Auth.auth().currentUser == nil {
                    emptyStateView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorite Courses")
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Favorites",
            systemImage: "star.slash",
            description: Text("Courses you favorite will appear here.")
        )
    }
    
    private var favoritesList: some View {
        List {
            ForEach(courseModel.favoriteCourses, id: \.self) { course in
                VStack(alignment: .leading) {
                    Text(course.name ?? "Unknown Course")
                        .font(.headline)
                    
                    if let address = course.placemark.postalAddress {
                        Text("\(address.street), \(address.city), \(address.state)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .swipeActions {
                    Button(role: .destructive) {
                        _ = courseModel.toggleFavorite(for: course)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .tint(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCourse = course
                }
            }
        }
        .mapItemDetailSheet(item: $selectedCourse)
    }
}

// Helper extension to make MKMapItem identifiable for sheet presentation
extension MKMapItem: @retroactive Identifiable {
    public var id: String {
        return self.placemark.title ?? UUID().uuidString
    }
}

#Preview {
    FavoritesView()
        .environmentObject(CourseDataModel())
}
