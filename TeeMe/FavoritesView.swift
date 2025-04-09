//
//  FavoritesView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/18/25.
//

import SwiftUI
import MapKit

struct FavoritesView: View {
    @EnvironmentObject var courseModel: CourseDataModel
    @State private var selectedCourse: MKMapItem?
    
    var body: some View {
        NavigationStack {
            VStack {
                if courseModel.favoriteCourses.isEmpty {
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
                        Label("Remove", systemImage: "trash")
                            .tint(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCourse = course
                }
            }
        }
        .sheet(item: $selectedCourse) { course in
            CourseDetailView(course: course)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
        }
    }
}

// Helper extension to make MKMapItem identifiable for sheet presentation
extension MKMapItem: @retroactive Identifiable {
    public var id: String {
        return self.placemark.title ?? UUID().uuidString
    }
}

// Course detail sheet view
struct CourseDetailView: View {
    let course: MKMapItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(course.name ?? "Unknown Course")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let address = course.placemark.postalAddress {
                    VStack(alignment: .leading) {
                        Text("Address")
                            .font(.headline)
                        Text("\(address.street)")
                        Text("\(address.city), \(address.state) \(address.postalCode)")
                    }
                }
                
                if let phone = course.phoneNumber {
                    VStack(alignment: .leading) {
                        Text("Phone")
                            .font(.headline)
                        //Text(phone)
                        Link(phone, destination: URL(string: "tel://\(phone)")!)
                    }
                }
                
                if let url = course.url {
                    VStack(alignment: .leading) {
                        Text("Website")
                            .font(.headline)
                        Link(url.absoluteString, destination: url)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Course Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(CourseDataModel())
}
