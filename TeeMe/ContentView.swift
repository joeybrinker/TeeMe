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
    
    var body: some View {
        //if Auth.auth().currentUser != nil {
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
            }
            .tint(Color.green)
        //} else {
            //LogInView()
        //}
    }
}

#Preview {
    ContentView()
        .environmentObject(CourseDataModel())
}
