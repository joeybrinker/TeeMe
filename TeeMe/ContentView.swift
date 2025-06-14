//
//  ContentView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/18/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var courseModel: CourseDataModel
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    
    var body: some View {
            TabView(selection: $selectedTab) {
                MapView()
                    .environmentObject(courseModel)
                    .tabItem {
                        Label("Find Courses", systemImage: "map")
                    }
                    .tag(0)
                
                FavoritesView()
                    .environmentObject(courseModel)
                    .tabItem {
                        Label("Favorites", systemImage: "star")
                    }
                    .tag(1)
                
                FeedView()
                    .environmentObject(userProfileViewModel)
                    .environmentObject(courseModel)
                    .tabItem {
                        Label("Feed", systemImage: "note.text")
                    }
                    .tag(2)
                
                UserProfileView()
                    .environmentObject(courseModel)
                    .environmentObject(userProfileViewModel)
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(3)
                
                
            }
            .accentColor(.green) //Will be depreciated in later versions
    }
}

#Preview {
    ContentView()
        .environmentObject(CourseDataModel())
        .environmentObject(UserProfileViewModel())
}
