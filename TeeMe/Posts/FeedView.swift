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
    
    @State private var showingEditProfile = false
    
    // Ad frequency: show ad every N posts
    private let adFrequency = 4
    
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
                    }
                    else if userViewModel.currentUser.id.isEmpty {
                        profileNotSetupView
                            .sheet(isPresented: $showingEditProfile) {
                                ProfileSetupView()
                                    .environmentObject(courseModel)
                                    .environmentObject(userViewModel)
                                    .onDisappear {
                                        userViewModel.loadCurrentUser()
                                    }
                            }
                            .onAppear {
                                userViewModel.loadCurrentUser()
                            }
                    } else if postViewModel.isLoading {
                        // Loading view
                        ProgressView("Loading posts...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if selectedSegment == 0 {
                        // All posts view with native ads
                        allPostsWithAdsView
                            .navigationTitle(Text("Feed"))
                    } else {
                        // User posts view (no ads in personal posts)
                        UserPostsView()
                            .environmentObject(postViewModel)
                            .navigationTitle(Text("Feed"))
                    }
                }
            }
            
            .toolbar {
                // Only show add post button if user is signed in
                if Auth.auth().currentUser != nil && !userViewModel.currentUser.id.isEmpty {
                    ToolbarItem {
                        Button {
                            showAddPostView = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.green)
                            Text("Post")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddPostView) {
                AddPostView(postVM: postViewModel, courseModel: courseModel)
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
    
    // MARK: - All Posts with Native Ads View
    private var allPostsWithAdsView: some View {
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
                        ForEach(Array(createFeedWithAds().enumerated()), id: \.offset) { index, item in
                            switch item {
                            case .post(let post):
                                PostView(post: post)
                                    .environmentObject(postViewModel)
                            case .ad:
                                NativeAdPostView()
                            }
                        }
                    }
                    .padding(.top)
                }
                .scrollIndicators(.automatic)
            }
        }
    }
    
    // MARK: - Create Feed with Native Ads
    private func createFeedWithAds() -> [FeedItem] {
        var feedItems: [FeedItem] = []
        
        for (index, post) in postViewModel.posts.enumerated() {
            feedItems.append(.post(post))
            
            // Insert ad every adFrequency posts (but not at the very beginning)
            if (index + 1) % adFrequency == 0 && index > 0 {
                feedItems.append(.ad)
            }
        }
        
        return feedItems
    }
    
    // MARK: - Feed Item Enum
    private enum FeedItem {
        case post(Post)
        case ad
    }
    
    // MARK: - Existing Subviews
    private var notSignedInView: some View {
        VStack{
            ContentUnavailableView(
                "Sign In to View Posts",
                systemImage: "person.slash",
                description: Text("Create an account to share your golf scores and see what others are playing.")
            )
            
            Button {
                courseModel.showSignIn = true
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 300, height: 50)
                        .foregroundStyle(.green)
                        .padding()
                    Text("Sign In")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
    
    private var profileNotSetupView: some View {
        VStack(spacing: 20) {
            ContentUnavailableView("Complete your profile",
                                   systemImage: "person.crop.circle.badge.plus",
                                   description: Text("Set up your golf profile to view and post scores."))
            
            Button {
                showingEditProfile = true
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 300, height: 50)
                        .foregroundStyle(.green)
                        .padding()
                    Text("Set Up Profile")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
}

#Preview {
    FeedView()
        .environmentObject(UserProfileViewModel())
        .environmentObject(CourseDataModel())
}
