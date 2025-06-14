//
//  UserDocument.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

func createUserDocument(for user: User) {
    let db = Firestore.firestore()
    
    // Get the auth provider information
    let authProvider = user.providerData.first?.providerID ?? "unknown"
    
    // Prepare user data
    var userData: [String: Any] = [
        "uid": user.uid,
        "joinDate": FieldValue.serverTimestamp(),
        "authProvider": authProvider,
        "lastSignIn": FieldValue.serverTimestamp()
    ]
    
    // Add email if available (some Apple users might hide their email)
    if let email = user.email {
        userData["email"] = email
    }
    
    // Add display name if available
    if let displayName = user.displayName {
        userData["displayName"] = displayName
    }
    
    // Add profile photo URL if available
    if let photoURL = user.photoURL?.absoluteString {
        userData["photoURL"] = photoURL
    }
    
    // Use merge: true to avoid overwriting existing data if user already exists
    db.collection("users").document(user.uid).setData(userData, merge: true) { error in
        if let error = error {
            print("Error creating/updating user document: \(error.localizedDescription)")
        } else {
            print("User document successfully created/updated for provider: \(authProvider)")
        }
    }
}

// Helper function to get user's auth provider
func getUserAuthProvider() -> String {
    guard let user = Auth.auth().currentUser else { return "none" }
    return user.providerData.first?.providerID ?? "unknown"
}

// Helper function to check if user is authenticated with a specific provider
func isUserSignedInWith(provider: String) -> Bool {
    guard let user = Auth.auth().currentUser else { return false }
    return user.providerData.contains { $0.providerID == provider }
}

// Constants for auth providers
struct AuthProviders {
    static let apple = "apple.com"
    static let google = "google.com"
    static let email = "password"
}

