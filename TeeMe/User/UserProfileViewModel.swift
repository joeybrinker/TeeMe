//
//  UserProfileViewModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/26/25.
//

import SwiftUI
import FirebaseAuth    // Needed for user authentication
import FirebaseFirestore  // Needed for database types

/**
 * UserProfileViewModel
 *
 * This class serves as the intermediary between the UI and the data layer.
 * It follows the MVVM (Model-View-ViewModel) pattern and provides:
 * - Observable properties for UI to bind to
 * - Business logic for loading and saving user profiles
 * - Error handling and state management
 */
class UserProfileViewModel: ObservableObject {
    // The service that handles the actual Firebase operations
    private let userService = UserProfileService()
    
    // Published properties that the UI can observe and react to
    @Published var currentUser: UserProfileModel = .empty()  // The current user's profile
    @Published var isLoading = false                         // Indicates whether an operation is in progress
    @Published var errorMessage: String?                     // Contains any error message to display
    
    /**
     * Initializes the view model and loads the current user's profile
     */
    init() {
        loadCurrentUser()
    }
    
    /**
     * Loads the current authenticated user's profile from Firebase
     *
     * This method:
     * 1. Checks if a user is logged in
     * 2. Fetches their profile from the database
     * 3. Updates the observable state properties
     */
    func loadCurrentUser() {
        // Check if a user is logged in
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "No user signed in"
            return
        }
        
        // Show loading indicator
        isLoading = true
        
        // Call the service to get the user profile
        userService.getUserProfile(userId: user.uid) { [weak self] result in
            guard let self = self else { return }  // Prevent memory leaks
            
            // Always update UI on the main thread
            DispatchQueue.main.async {
                // Hide loading indicator
                self.isLoading = false
                
                // Handle the result
                switch result {
                case .success(let profile):
                    // Profile found, update the view model
                    self.currentUser = profile
                    self.errorMessage = nil
                    
                case .failure(let error):
                    // Handle different error cases
                    if (error as NSError).code == 404 {
                        // Special case: profile doesn't exist yet
                        self.errorMessage = "Profile not set up yet"
                    }
                    else {
                        // Other errors
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    /**
     * Saves the user profile to Firebase
     *
     * This method handles both creating new profiles and updating existing ones.
     * It validates inputs, shows loading states, and handles errors.
     *
     * @param username - The username to save
     * @param displayName - The display name to save
     * @param handicap - Optional handicap as a string (will be converted to Double)
     * @param completion - A closure called with true if successful, false otherwise
     */
    func saveProfile(username: String, displayName: String, handicap: String?, completion: @escaping (Bool) -> Void) {
        // Verify a user is logged in
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "No user is signed in"
            completion(false)
            return
        }
        
        // Show loading indicator
        isLoading = true
        
        // Convert handicap string to Double if provided
        // flatMap will return nil if the conversion fails or if handicap is nil
        let handicapValue: Double? = handicap.flatMap { Double($0) }
        
        // Prepare profile data with updated values
        var profile = currentUser
        profile.username = username
        profile.displayName = displayName
        profile.handicap = handicapValue
        
        // Determine whether to update or create based on if we have an existing profile
        if !currentUser.id.isEmpty {
            // Update existing profile
            userService.updateUserProfile(profile) { [weak self] result in
                guard let self = self else { return }  // Prevent memory leaks
                
                // Always update UI on the main thread
                DispatchQueue.main.async {
                    // Hide loading indicator
                    self.isLoading = false
                    
                    // Handle the result
                    switch result {
                    case .success(let userProfile):
                        // Update successful
                        self.currentUser = userProfile
                        self.errorMessage = nil
                        completion(true)
                        
                    case .failure(let error):
                        // Update failed
                        self.errorMessage = error.localizedDescription
                        completion(false)
                    }
                }
            }
        }
        else {
            // Create new profile
            userService.createUserProfile(for: user, username: username, displayName: displayName) { [weak self] result in
                guard let self = self else { return }  // Prevent memory leaks
                
                // Always update UI on the main thread
                DispatchQueue.main.async {
                    // Hide loading indicator
                    self.isLoading = false
                    
                    // Handle the result
                    switch result {
                    case .success(var newProfile):
                        // Set handicap if provided (it wasn't part of the initial creation)
                        newProfile.handicap = handicapValue
                        
                        // If a handicap was provided, update the profile again with the handicap
                        if handicapValue != nil {
                            // Fire and forget - we don't wait for this to complete
                            self.userService.updateUserProfile(newProfile) { _ in }
                        }
                        
                        // Update the view model with the new profile
                        self.currentUser = newProfile
                        self.errorMessage = nil
                        completion(true)
                        
                    case .failure(let error):
                        // Creation failed
                        self.errorMessage = error.localizedDescription
                        completion(false)
                    }
                }
            }
        }
    }
}
