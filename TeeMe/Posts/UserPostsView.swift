//
//  UserPostsView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 6/4/25.
//


import SwiftUI
import FirebaseAuth

struct UserPostsView: View {
    @EnvironmentObject var postViewModel: PostViewModel
    @State private var viewMode: ViewMode = .chronological
    
    enum ViewMode: String, CaseIterable {
        case chronological = "All Posts"
        case byCourse = "By Course"
    }
    
    private var groupedPosts: [String: [Post]] {
        Dictionary(grouping: postViewModel.userPosts) { post in
            post.title // Group by course name
        }
    }
    
    private var sortedCourseNames: [String] {
        groupedPosts.keys.sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // View mode picker
            Picker("View Mode", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(.green)
            
            // Content based on view mode
            Group {
                if postViewModel.userPosts.isEmpty {
                    ContentUnavailableView(
                        "No Posts Yet",
                        systemImage: "note.text",
                        description: Text("Share your first golf round to get started!")
                    )
                } else {
                    switch viewMode {
                    case .chronological:
                        chronologicalView
                    case .byCourse:
                        courseGroupedView
                    }
                }
            }
        }
    }
    
    // Original chronological view
    private var chronologicalView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(postViewModel.userPosts, id: \.self) { post in
                    PostView(post: post)
                        .environmentObject(postViewModel)
                }
            }
            .padding(.top)
        }
        .scrollIndicators(.automatic)
    }
    
    // New course-grouped view
    private var courseGroupedView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(sortedCourseNames, id: \.self) { courseName in
                    CourseGroupView(
                        courseName: courseName,
                        posts: groupedPosts[courseName] ?? []
                    )
                }
            }
            .padding(.top)
        }
        .scrollIndicators(.automatic)
    }
}



#Preview {
    UserPostsView()
        .environmentObject(PostViewModel())
}
