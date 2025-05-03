//
//  UserProfileService.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/26/25.
//

import SwiftUI
import FirebaseFirestore  // Needed for database operations
import FirebaseAuth       // Needed for user authentication

/**
 * UserProfileService
 *
 * This class handles all interactions with user profiles in Firestore.
 * It provides methods to create, read, and update user profile data.
 * The service uses Firebase Firestore as the backend database.
 */
class UserProfileService {
    // Reference to the Firestore database
    private let db = Firestore.firestore()
    
    // MARK: - Create / Update Profile
    
    /**
     * Checks if a username is available in the database
     *
     * This method queries Firestore to check if a specific username already exists
     * by searching for documents where the "username" field matches the provided username.
     *
     * @param username - The username to check availability for
     * @param completion - A closure that will be called with the result:
     *                     - .success(true) if the username is available
     *                     - .success(false) if the username is taken or empty
     *                     - .failure(error) if a database error occurred
     */
    func isUsernameAvailable(_ username: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Validate: Do not allow empty username
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.success(false))  // Empty usernames are not allowed, return false
            return
        }
        
        // Query Firestore for documents where username matches
        db.collection("users").whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                // Handle any database errors
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check if any documents were returned
                if let documents = snapshot?.documents, documents.isEmpty {
                    completion(.success(true))      // No documents found, username is available
                }
                else {
                    completion(.success(false))     // Documents found, username is taken
                }
            }
    }
    
    /**
     * Creates a new user profile in Firestore
     *
     * This method first checks if the username is available, and if so,
     * creates a new profile document in Firestore with the user's information.
     *
     * @param user - The Firebase Auth user object
     * @param username - The desired username for the profile
     * @param displayName - The display name for the profile
     * @param completion - A closure that will be called with the result:
     *                     - .success(profile) with the created profile if successful
     *                     - .failure(error) if creation failed
     */
    func createUserProfile(for user: User, username: String, displayName: String, completion: @escaping (Result<UserProfileModel, Error>) -> Void) {
        // First check if the requested username is available
        isUsernameAvailable(username) { [weak self] result in
            guard let self = self else {return}  // Prevent memory leaks with weak self
            
            switch result {
            case .success(let isAvailable):
                if isAvailable {
                    // Username is available, create the profile
                    let userProfile = UserProfileModel(id: user.uid, username: username, displayName: displayName, dateJoined: Date())
                    
                    // Save the profile to Firestore
                    self.db.collection("users").document(user.uid).setData(userProfile.toDictionary()) { error in
                        if let error = error {
                            // Handle database error
                            completion(.failure(error))
                        }
                        else {
                            // Profile created successfully
                            completion(.success(userProfile))
                        }
                    }
                }
                else {
                    // Username is already taken, return appropriate error
                    let error = NSError(domain: "UserProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username already taken"])
                    completion(.failure(error))
                }
            case .failure(let error):
                // Pass through any errors from username check
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Updates an existing user profile
     *
     * This method handles updating a user profile, including checking if
     * a new username is available when the username is being changed.
     *
     * @param profile - The updated profile model
     * @param completion - A closure that will be called with the result:
     *                     - .success(profile) with the updated profile if successful
     *                     - .failure(error) if update failed
     */
    func updateUserProfile(_ profile: UserProfileModel, completion: @escaping (Result<UserProfileModel, Error>) -> Void) {
        // First get the current profile to check if username has changed
        getUserProfile(userId: profile.id) { [weak self] result in
            guard let self = self else { return }  // Prevent memory leaks
            
            switch result {
            case .success(let currentProfile):
                // Check if username has changed
                if currentProfile.username != profile.username {
                    // Username changed, check if the new one is available
                    self.isUsernameAvailable(profile.username) { result in
                        switch result {
                        case .success(let available):
                            if available {
                                // New username is available, save the profile
                                self.saveProfile(profile, completion: completion)
                            }
                            else {
                                // New username is taken, return error
                                let error = NSError(domain: "UserProfileService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Username is already taken"])
                                completion(.failure(error))
                            }
                        case .failure(let error):
                            // Pass through any errors from username check
                            completion(.failure(error))
                        }
                    }
                }
                else {
                    // Username unchanged, just save the profile updates
                    self.saveProfile(profile, completion: completion)
                }
            case .failure(let error):
                // Pass through any errors from profile retrieval
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Retrieves a user profile from Firestore
     *
     * This method fetches a user profile document from Firestore using the user ID.
     *
     * @param userId - The ID of the user whose profile to fetch
     * @param completion - A closure that will be called with the result:
     *                     - .success(profile) with the fetched profile if successful
     *                     - .failure(error) if retrieval failed or profile not found
     */
    func getUserProfile(userId: String, completion: @escaping (Result<UserProfileModel, Error>) -> Void) {
        // Get the document for this user ID
        db.collection("users").document(userId).getDocument { snapshot, error in
            // Handle any database errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check if document exists and has data
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                // Try to create profile model from the data
                if let profile = UserProfileModel(id: userId, data: data) {
                    completion(.success(profile))
                }
                else {
                    // Document exists but data is invalid
                    let error = NSError(domain: "UserProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user profile data"])
                    completion(.failure(error))
                }
            }
            else {
                // Document doesn't exist
                let error = NSError(domain: "UserProfileService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Private helper method to save a profile to Firestore
     *
     * This method handles the actual writing of profile data to Firestore.
     * The merge: true parameter ensures we only update the fields that are provided
     * without overwriting any fields not included in the update.
     *
     * @param profile - The profile to save
     * @param completion - A closure that will be called with the result
     */
    private func saveProfile(_ profile: UserProfileModel, completion: @escaping (Result<UserProfileModel, Error>) -> Void) {
        // Save the profile data to Firestore
        db.collection("users").document(profile.id).setData(profile.toDictionary(), merge: true) { error in
            if let error = error {
                // Handle database error
                completion(.failure(error))
            } else {
                // Save successful
                completion(.success(profile))
            }
        }
    }    
}
