//
//  FeedView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/27/25.
//

import SwiftUI
import FirebaseAuth

struct FeedView: View {
    @StateObject var postViewModel = PostViewModel()
    @EnvironmentObject var userViewModel: UserProfileViewModel
    @EnvironmentObject var courseModel: CourseDataModel
    
    @State var showAddPostView = false
    @State private var selectedSegment = 0 // 0 = All Posts, 1 = My Posts
    @State private var showDeleteConfirmation = false
    @State private var postToDelete: Post?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                if Auth.auth().currentUser != nil {
                    Picker("Feed Type", selection: $selectedSegment) {
                        Text("All Posts").tag(0)
                        Text("My Posts").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }
                
                // Main Content
                ZStack {
                    if Auth.auth().currentUser == nil {
                        // Not signed in view
                        notSignedInView
                        
                        if courseModel.showSignIn {
                            AuthView()
                        }
                    } else if postViewModel.isLoading {
                        // Loading view
                        ProgressView("Loading posts...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if selectedSegment == 0 {
                        // All posts view
                        allPostsView
                    } else {
                        // User posts view
                        userPostsView
                    }
                }
            }
            .navigationTitle(Text("Feed"))
            .toolbar {
                // Only show add post button if user is signed in
                if Auth.auth().currentUser != nil {
                    ToolbarItem {
                        Button {
                            showAddPostView = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddPostView) {
                AddPostView(postVM: postViewModel)
                    .presentationDetents([.medium, .large])
            }
            .refreshable {
                if selectedSegment == 0 {
                    postViewModel.refreshPosts()
                } else {
                    postViewModel.loadCurrentUserPosts()
                }
            }
            .onChange(of: selectedSegment) { _, newValue in
                if newValue == 1 {
                    // Load user posts when switching to "My Posts"
                    postViewModel.loadCurrentUserPosts()
                }
            }
            .alert("Error", isPresented: .constant(postViewModel.errorMessage != nil)) {
                Button("OK") {
                    postViewModel.errorMessage = nil
                }
            } message: {
                Text(postViewModel.errorMessage ?? "An error occurred")
            }
            .alert("Delete Post", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let post = postToDelete {
                        postViewModel.deletePost(post)
                        postToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
            .onAppear {
                postViewModel.loadAllPosts()
            }
        }
    }
    
    // MARK: - Methods
    
    private func deletePost(_ post: Post) {
        postToDelete = post
        showDeleteConfirmation = true
        postViewModel.deletePost(postToDelete!)
    }
    
    // MARK: - Subviews
    
    private var notSignedInView: some View {
        VStack{
            ContentUnavailableView(
                "Sign In to View Posts",
                systemImage: "person.slash",
                description: Text("Create an account to share your golf scores and see what others are playing.")
            )
            
            Button {
                courseModel.showSignIn = true  // Show authentication view when pressed
            } label: {
                ZStack{
                    // Green rounded rectangle button
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 300, height: 50)
                        .foregroundStyle(.green)
                        .padding()
                    // Button text
                    Text("Sign In")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
    
    private var allPostsView: some View {
        Group {
            if postViewModel.posts.isEmpty {
                ContentUnavailableView(
                    "No Posts Yet",
                    systemImage: "note.text",
                    description: Text("Be the first to share your golf experience!")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(postViewModel.posts, id: \.self) { post in
                            PostView(post: post)
                                .environmentObject(postViewModel)
                        }
                    }
                    .padding(.top)
                }
                .scrollIndicators(.automatic)
            }
        }
    }
    
    private var userPostsView: some View {
        Group {
            if postViewModel.userPosts.isEmpty {
                ContentUnavailableView(
                    "No Posts Yet",
                    systemImage: "note.text",
                    description: Text("Share your first golf round to get started!")
                )
            } else {
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
        }
    }
    
}

#Preview {
    FeedView()
        .environmentObject(UserProfileViewModel())
        .environmentObject(CourseDataModel())
}
