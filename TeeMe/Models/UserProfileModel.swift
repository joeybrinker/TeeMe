//
//  UserProfile.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  UserProfileModel.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import FirebaseAuth
import CloudKit

struct UserProfile: Identifiable, Equatable {
    var id: String  // Firebase UID
    var displayName: String
    var email: String
    var handicap: Double?
    var averageScore: Int?
    var preferredTeeTime: String?
    var homeCourseName: String?
    var joinDate: Date
    
    // Equatable implementation
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id
    }
}

class UserProfileModel: ObservableObject {
    @Published var currentProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    init() {
        // Check for logged in user and load profile
        if let user = Auth.auth().currentUser {
            loadUserProfile(userId: user.uid)
        }
        
        // Add auth state listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadUserProfile(userId: user.uid)
            } else {
                self?.currentProfile = nil
            }
        }
    }
    
    // Load user profile from CloudKit
    func loadUserProfile(userId: String) {
        isLoading = true
        
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    return
                }
                
                // If profile exists, load it
                if let record = records?.first {
                    self?.currentProfile = self?.profileFromRecord(record)
                } else {
                    // If no profile exists, create one
                    self?.createNewProfile(userId: userId)
                }
            }
        }
    }
    
    // Create a new user profile in CloudKit
    private func createNewProfile(userId: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        let profile = UserProfile(
            id: userId,
            displayName: user.displayName ?? "",
            email: user.email ?? "",
            handicap: nil,
            averageScore: nil,
            preferredTeeTime: nil,
            homeCourseName: nil,
            joinDate: Date()
        )
        
        saveProfile(profile)
        self.currentProfile = profile
    }
    
    // Save profile to CloudKit
    func saveProfile(_ profile: UserProfile) {
        isLoading = true
        
        let record = CKRecord(recordType: "UserProfile")
        record["userId"] = profile.id
        record["displayName"] = profile.displayName
        record["email"] = profile.email
        record["handicap"] = profile.handicap
        record["averageScore"] = profile.averageScore
        record["preferredTeeTime"] = profile.preferredTeeTime
        record["homeCourseName"] = profile.homeCourseName
        record["joinDate"] = profile.joinDate
        
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                } else {
                    self?.currentProfile = profile
                }
            }
        }
    }
    
    // Update specific profile fields
    func updateProfile(displayName: String? = nil, 
                       handicap: Double? = nil, 
                       averageScore: Int? = nil,
                       preferredTeeTime: String? = nil,
                       homeCourseName: String? = nil) {
        
        guard var updatedProfile = currentProfile else { return }
        
        if let displayName = displayName {
            updatedProfile.displayName = displayName
        }
        
        if let handicap = handicap {
            updatedProfile.handicap = handicap
        }
        
        if let averageScore = averageScore {
            updatedProfile.averageScore = averageScore
        }
        
        if let preferredTeeTime = preferredTeeTime {
            updatedProfile.preferredTeeTime = preferredTeeTime
        }
        
        if let homeCourseName = homeCourseName {
            updatedProfile.homeCourseName = homeCourseName
        }
        
        saveProfile(updatedProfile)
    }
    
    // Convert CloudKit record to UserProfile
    private func profileFromRecord(_ record: CKRecord) -> UserProfile {
        return UserProfile(
            id: record["userId"] as? String ?? "",
            displayName: record["displayName"] as? String ?? "",
            email: record["email"] as? String ?? "",
            handicap: record["handicap"] as? Double,
            averageScore: record["averageScore"] as? Int,
            preferredTeeTime: record["preferredTeeTime"] as? String,
            homeCourseName: record["homeCourseName"] as? String,
            joinDate: record["joinDate"] as? Date ?? Date()
        )
    }
}
