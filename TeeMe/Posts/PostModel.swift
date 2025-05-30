//
//  PostModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

class Post: ObservableObject, Hashable {
    
    let id: UUID = UUID()
    let datePosted: String
    let user: UserProfileModel
    let title: String
    let score: String
    let holes: String
    let greensInRegulation: String
    
    @Published var isLiked: Bool = false
    @Published var likes: Int = 0
    
    // Firestore document ID for database operations
    var firestoreId: String?
    
    // Service for handling database operations
    private let postService = PostService()
    
    init(user: UserProfileModel, title: String, score: String, holes: String, greensInRegulation: String, datePosted: String? = nil) {
        self.user = user
        self.title = title
        self.score = score
        self.holes = holes
        self.greensInRegulation = greensInRegulation
        
        // Use provided date or generate current date
        if let datePosted = datePosted {
            self.datePosted = datePosted
        } else {
            self.datePosted = "\(Date().formatted(date: .numeric, time: .shortened))"
        }
        
        // Don't check like status here - will be called after firestoreId is set
    }
    
    /**
     * Call this after setting firestoreId to check if user has liked this post
     */
    func checkInitialLikeStatus() {
        checkUserLikeStatus()
    }
    
    func likePost() {
        // Optimistic update - update UI immediately
        likes += 1
        isLiked = true
        
        // Update in database
        updateLikeInDatabase()
    }
    
    func dislikePost() {
        // Optimistic update - update UI immediately
        likes -= 1
        isLiked = false
        
        // Update in database
        updateLikeInDatabase()
    }
    
    // MARK: - Private Methods
    
    /**
     * Updates the like status in the database
     */
    private func updateLikeInDatabase() {
        guard let firestoreId = firestoreId,
              let currentUserId = Auth.auth().currentUser?.uid else {
            print("Cannot update like: missing firestoreId or user not authenticated")
            return
        }
        
        // Update the like count in the post document (using the post owner's user ID)
        postService.updatePostLikes(userId: user.id, postId: firestoreId, newLikeCount: likes) { result in
            switch result {
            case .success():
                print("Like count updated successfully")
            case .failure(let error):
                print("Failed to update like count: \(error.localizedDescription)")
                // Revert optimistic update on failure
                DispatchQueue.main.async {
                    if self.isLiked {
                        self.likes -= 1
                        self.isLiked = false
                    } else {
                        self.likes += 1
                        self.isLiked = true
                    }
                }
            }
        }
        
        // Update the user's like status for this post
        postService.toggleUserLike(postOwnerId: user.id, postId: firestoreId, likingUserId: currentUserId, isLiked: isLiked) { result in
            switch result {
            case .success():
                print("User like status updated successfully")
            case .failure(let error):
                print("Failed to update user like status: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Checks if the current user has already liked this post
     */
    private func checkUserLikeStatus() {
        guard let firestoreId = firestoreId,
              let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        postService.checkUserLike(postOwnerId: user.id, postId: firestoreId, likingUserId: currentUserId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isLiked):
                    self?.isLiked = isLiked
                case .failure(let error):
                    print("Failed to check user like status: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Hashable Conformance
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
