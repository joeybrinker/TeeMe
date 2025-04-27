//
//  UserProfileModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/26/25.
//

import SwiftUI
import FirebaseAuth     // Required for Firebase user types
import FirebaseFirestore // Required for Firestore types like Timestamp

/**
 * UserProfileModel
 *
 * This struct represents a user profile in the TeeMe app.
 * It stores essential user information and provides methods for
 * conversion between Firestore data and Swift objects.
 *
 * Conformance to protocols:
 * - Identifiable: Allows the model to be used in SwiftUI lists and ForEach
 * - Codable: Enables easy conversion to/from JSON (though we use custom methods for Firestore)
 */
struct UserProfileModel: Identifiable, Codable {
    var id: String              // Firebase user ID (UID) - used to uniquely identify this user
    var username: String        // Unique username - publicly visible identifier chosen by the user
    var displayName: String     // Name to display in the app - the user's preferred display name
    var handicap: Double?       // Golf handicap (optional) - standard golf skill measurement
    var dateJoined: Date        // When the user joined - timestamp for account creation
    
    /**
     * Computed property to format the handicap for display
     *
     * Returns the handicap formatted to one decimal place,
     * or "Not set" if the handicap is nil
     */
    var handicapDisplay: String {
        if let handicap = handicap {
            return String(format: "%.1f", handicap) // Format with one decimal place
        } else {
            return "Not set"
        }
    }
    
    /**
     * Creates an empty profile with default values
     *
     * This static method is useful for initializing a blank profile
     * before a user has provided their information or when no profile exists
     */
    static func empty() -> UserProfileModel {
        return UserProfileModel(
            id: "", username: "", displayName: "", handicap: nil, dateJoined: Date()
        )
    }
    
    /**
     * Initializes a profile from Firestore data
     *
     * This failable initializer attempts to create a profile model
     * from Firestore document data. It will return nil if required
     * fields are missing from the data.
     *
     * @param id - The document ID (user ID)
     * @param data - Dictionary containing Firestore document fields
     */
    init?(id: String, data: [String: Any]) {
        self.id = id
        
        // Required Fields - Username and displayName must exist
        guard let username = data["username"] as? String,
              let displayName = data["displayName"] as? String
        else {
            // If required fields are missing, initialization fails
            return nil
        }
        
        // Set properties from Firestore data
        self.username = username
        self.displayName = displayName
        self.handicap = data["handicap"] as? Double  // Optional field
        
        // Handle date conversion from Firestore Timestamp
        if let joinTimestamp = data["dateJoined"] as? Timestamp {
            // Convert Firestore Timestamp to Swift Date
            self.dateJoined = joinTimestamp.dateValue()
        }
        else {
            // Default to current date if timestamp is missing
            self.dateJoined = Date()
        }
    }
    
    /**
     * Standard initializer for creating a profile from Swift variables
     *
     * This initializer is used when creating a new profile from code
     * rather than from Firestore data.
     *
     * @param id - User ID from Firebase Auth
     * @param username - Chosen username
     * @param displayName - User's display name
     * @param handicap - Optional golf handicap
     * @param dateJoined - When the user joined (defaults to current date)
     */
    init(id: String, username: String, displayName: String, handicap: Double? = nil, dateJoined: Date) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.handicap = handicap
        self.dateJoined = dateJoined
    }
    
    /**
     * Converts the profile to a dictionary for Firestore storage
     *
     * This method creates a dictionary representation of the profile
     * that can be stored in Firestore. It handles proper conversion
     * of types like Date to Firestore Timestamp.
     *
     * @return Dictionary with keys and values for Firestore
     */
    func toDictionary() -> [String: Any] {
        // Create dictionary with required fields
        var dictionary: [String: Any] = [
            "username": username,
            "displayName": displayName,
            "dateJoined": Timestamp(date: dateJoined)  // Convert Date to Firestore Timestamp
        ]
        
        // Add optional fields only if they exist
        if let handicap = handicap {
            dictionary["handicap"] = handicap
        }
        
        return dictionary
    }
}
