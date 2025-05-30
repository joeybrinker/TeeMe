//
//  PostService.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/29/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class PostService {
    private let db = Firestore.firestore()
    
    // MARK: - Create Post
    
    /**
     * Saves a new post under the user's document in Firestore
     *
     * @param post - The post object to save
     * @param completion - Callback with success/failure result
     */
    func savePost(_ post: Post, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "PostService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            completion(.failure(error))
            return
        }
        
        // Create post data dictionary - cache essential user data for social features
        let postData: [String: Any] = [
            "userId": currentUser.uid,
            "userDisplayName": post.user.displayName,  // Cache for immediate display & navigation
            "username": post.user.username,            // Cache for @mentions, search, navigation
            "title": post.title,
            "score": post.score,
            "holes": post.holes,
            "greensInRegulation": post.greensInRegulation,
            "likes": post.likes,
            "datePosted": Timestamp(date: Date()),
        ]
        
        // Save to user's posts subcollection
        db.collection("users").document(currentUser.uid).collection("posts").addDocument(data: postData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Post saved successfully"))
            }
        }
    }
    
    // MARK: - Load Posts
    
    /**
     * Loads all posts from all users for the main feed
     * This requires reading from multiple user collections
     *
     * @param completion - Callback with array of posts or error
     */
    func loadAllPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        // First, get all users
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userDocuments = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            var allPosts: [Post] = []
            let dispatchGroup = DispatchGroup()
            
            // For each user, get their posts
            for userDoc in userDocuments {
                dispatchGroup.enter()
                
                userDoc.reference.collection("posts")
                    .order(by: "createdAt", descending: true)
                    .getDocuments { snapshot, error in
                        defer { dispatchGroup.leave() }
                        
                        if let error = error {
                            print("Error loading posts for user \(userDoc.documentID): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let postDocuments = snapshot?.documents else { return }
                        
                        let userPosts = postDocuments.compactMap { postDoc -> Post? in
                            return self.createPostFromDocument(postDoc)
                        }
                        
                        allPosts.append(contentsOf: userPosts)
                    }
            }
            
            dispatchGroup.notify(queue: .main) {
                // Sort all posts by creation date
                let sortedPosts = allPosts.sorted { post1, post2 in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    dateFormatter.timeStyle = .short
                    
                    let date1 = dateFormatter.date(from: post1.datePosted) ?? Date.distantPast
                    let date2 = dateFormatter.date(from: post2.datePosted) ?? Date.distantPast
                    
                    return date1 > date2
                }
                
                completion(.success(sortedPosts))
            }
        }
    }
    
    /**
     * Loads posts for a specific user - much simpler now!
     *
     * @param userId - The ID of the user whose posts to load
     * @param completion - Callback with array of posts or error
     */
    func loadUserPosts(userId: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection("users").document(userId).collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let posts = documents.compactMap { document -> Post? in
                    return self.createPostFromDocument(document)
                }
                
                completion(.success(posts))
            }
    }
    
    // MARK: - Real-time Updates
    
    /**
     * Sets up a real-time listener for all posts (simplified version)
     * Note: This is less efficient for large numbers of users
     * Consider implementing a dedicated feed collection for production apps
     *
     * @param completion - Callback called whenever posts change
     * @return A listener that can be removed later
     */
    func listenForAllPosts(completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration {
        // For simplicity, we'll refresh the feed periodically
        // In a production app, you'd want a dedicated feed collection
        return db.collection("users").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Reload all posts when any user document changes
            self.loadAllPosts(completion: completion)
        }
    }
    
    /**
     * Sets up a real-time listener for a specific user's posts
     *
     * @param userId - The user ID to listen to
     * @param completion - Callback called whenever posts change
     * @return A listener that can be removed later
     */
    func listenForUserPosts(userId: String, completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId).collection("posts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let posts = documents.compactMap { document -> Post? in
                    return self.createPostFromDocument(document)
                }
                
                completion(.success(posts))
            }
    }
    
    // MARK: - Like Management
    
    /**
     * Updates the like count for a specific post
     *
     * @param userId - The user who owns the post
     * @param postId - The Firestore document ID of the post
     * @param newLikeCount - The new like count
     * @param completion - Callback with success/failure result
     */
    func updatePostLikes(userId: String, postId: String, newLikeCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("posts").document(postId).updateData([
            "likes": newLikeCount
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /**
     * Manages user likes for posts (tracks which users liked which posts)
     *
     * @param postOwnerId - The user who owns the post
     * @param postId - The Firestore document ID of the post
     * @param likingUserId - The ID of the user liking/unliking
     * @param isLiked - Whether the user is liking (true) or unliking (false)
     * @param completion - Callback with success/failure result
     */
    func toggleUserLike(postOwnerId: String, postId: String, likingUserId: String, isLiked: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let userLikeRef = db.collection("users").document(postOwnerId).collection("posts").document(postId).collection("likes").document(likingUserId)
        
        if isLiked {
            // Add like
            userLikeRef.setData([
                "userId": likingUserId,
                "likedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } else {
            // Remove like
            userLikeRef.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /**
     * Checks if a user has liked a specific post
     *
     * @param postOwnerId - The user who owns the post
     * @param postId - The Firestore document ID of the post
     * @param likingUserId - The ID of the user to check
     * @param completion - Callback with true if liked, false otherwise
     */
    func checkUserLike(postOwnerId: String, postId: String, likingUserId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        db.collection("users").document(postOwnerId).collection("posts").document(postId).collection("likes").document(likingUserId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(snapshot?.exists ?? false))
        }
    }
    
    // MARK: - Delete Post
    
    /**
     * Deletes a post from the user's collection
     *
     * @param userId - The user who owns the post
     * @param postId - The Firestore document ID of the post to delete
     * @param completion - Callback with success/failure result
     */
    func deletePost(userId: String, postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("posts").document(postId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Creates a Post object from a Firestore document
     * Uses cached user data for immediate display and social features
     *
     * @param document - The Firestore document
     * @return A Post object or nil if data is invalid
     */
    private func createPostFromDocument(_ document: QueryDocumentSnapshot) -> Post? {
        let data = document.data()
        
        // Extract required fields
        guard let userId = data["userId"] as? String,
              let userDisplayName = data["userDisplayName"] as? String,
              let username = data["username"] as? String,
              let title = data["title"] as? String,
              let score = data["score"] as? String,
              let holes = data["holes"] as? String,
              let greensInRegulation = data["greensInRegulation"] as? String,
              let likes = data["likes"] as? Int else {
            print("Failed to parse post document: \(document.documentID)")
            return nil
        }
        
        // Handle date
        let datePosted: String = {
            if let timestamp = data["datePosted"] as? Timestamp {
                return timestamp.dateValue().formatted(date: .numeric, time: .shortened)
            }
            return Date().formatted(date: .numeric, time: .shortened)
        }()
        
        // Create user model with cached data (handicap will be nil, fetched when viewing full profile)
        let userModel = UserProfileModel(
            id: userId,
            username: username,
            displayName: userDisplayName,
            handicap: nil, // Not cached - fetch when viewing full profile
            dateJoined: Date() // Not cached - fetch when viewing full profile
        )
        
        // Create post
        let post = Post(
            user: userModel,
            title: title,
            score: score,
            holes: holes,
            greensInRegulation: greensInRegulation,
            datePosted: datePosted
        )
        
        // Set the likes and store the document ID for future updates
        post.likes = likes
        post.firestoreId = document.documentID
        
        // Now check if current user has liked this post
        post.checkInitialLikeStatus()
        
        return post
    }
}
