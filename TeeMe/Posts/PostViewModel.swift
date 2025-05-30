//
//  PostViewModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var userPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let postService = PostService()
    private var postsListener: ListenerRegistration?
    
    init() {
        loadAllPosts()
        setupRealtimeListener()
    }
    
    deinit {
        // Remove listener when view model is deallocated
        postsListener?.remove()
    }
    
    // MARK: - Public Methods
    
    /**
     * Adds a new post to Firebase and updates the local array
     */
    func addPost(_ post: Post) {
        isLoading = true
        errorMessage = nil
        
        postService.savePost(post) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let message):
                    print(message)
                    // The real-time listener will automatically update the posts array
                    // so we don't need to manually add it here
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Failed to save post: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /**
     * Loads all posts from Firebase
     */
    func loadAllPosts() {
        isLoading = true
        errorMessage = nil
        
        postService.loadAllPosts { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let posts):
                    self?.posts = posts
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Failed to load posts: \(error.localizedDescription)")
                    // Fallback to sample data if loading fails
                    self?.loadSampleData()
                }
            }
        }
    }
    
    /**
     * Loads posts for a specific user
     */
    func loadUserPosts(userId: String) {
        isLoading = true
        errorMessage = nil
        
        postService.loadUserPosts(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let posts):
                    self?.userPosts = posts
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Failed to load user posts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /**
     * Loads posts for the currently authenticated user
     */
    func loadCurrentUserPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        loadUserPosts(userId: currentUserId)
    }
    
    /**
     * Refreshes the posts (pull-to-refresh functionality)
     */
    func refreshPosts() {
        loadAllPosts()
    }
    
    /**
     * Deletes a post (only if user owns it)
     */
    func deletePost(_ post: Post) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              post.user.id == currentUserId,
              let firestoreId = post.firestoreId else {
            errorMessage = "Cannot delete this post"
            return
        }
        
        postService.deletePost(userId: currentUserId, postId: firestoreId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    // Remove from local array
                    self?.posts.removeAll { $0.id == post.id }
                    self?.userPosts.removeAll { $0.id == post.id }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Failed to delete post: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Sets up real-time listener for posts
     */
    private func setupRealtimeListener() {
        postsListener = postService.listenForAllPosts { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let posts):
                    self?.posts = posts
                    self?.errorMessage = nil
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Real-time listener error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /**
     * Loads sample data as fallback when Firebase is unavailable
     */
    private func loadSampleData() {
        posts = [
            // Complete posts with all stats
            Post(user: UserProfileModel(id: "1", username: "golfpro_mike", displayName: "Mike Johnson", handicap: 2.5, dateJoined: Date().addingTimeInterval(-86400 * 365)),
                 title: "Pebble Beach Golf Links", score: "72", holes: "18", greensInRegulation: "14", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
            
            Post(user: UserProfileModel(id: "2", username: "sarah_golfs", displayName: "Sarah Williams", handicap: 8.2, dateJoined: Date().addingTimeInterval(-86400 * 280)),
                 title: "Augusta National Golf Club", score: "79", holes: "18", greensInRegulation: "10", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
            
            Post(user: UserProfileModel(id: "3", username: "scottish_links", displayName: "James MacLeod", handicap: 12.0, dateJoined: Date().addingTimeInterval(-86400 * 450)),
                 title: "St. Andrews Links", score: "85", holes: "18", greensInRegulation: "8", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
            
            Post(user: UserProfileModel(id: "4", username: "weekend_warrior", displayName: "Lisa Chen", handicap: 18.5, dateJoined: Date().addingTimeInterval(-86400 * 120)),
                 title: "Torrey Pines Golf Course", score: "92", holes: "18", greensInRegulation: "6", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
            
            Post(user: UserProfileModel(id: "5", username: "tiger_woods_fan", displayName: "David Rodriguez", handicap: 15.3, dateJoined: Date().addingTimeInterval(-86400 * 200)),
                 title: "TPC Sawgrass", score: "88", holes: "18", greensInRegulation: "12", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))")]
    }
}
