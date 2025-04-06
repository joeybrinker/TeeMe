//
//  AppleAuthService.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  AppleAuthService.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import AuthenticationServices
import CloudKit

class AppleAuthService: ObservableObject {
    @Published var isSignedIn = false
    @Published var userId: String?
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var errorMessage: String?
    
    init() {
        checkSignInStatus()
    }
    
    // Check if the user is already signed in with Apple ID
    private func checkSignInStatus() {
        // Check keychain for stored user ID
        if let userId = KeychainItem.readItem(key: "userId") {
            self.userId = userId
            self.isSignedIn = true
            
            // Try to retrieve name from keychain if available
            self.userName = KeychainItem.readItem(key: "userName")
            self.userEmail = KeychainItem.readItem(key: "userEmail")
        } else {
            self.isSignedIn = false
        }
    }
    
    // Process the result of the Apple Sign In
    func processSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            // Handle authorization
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Get user identifier
                let userId = appleIDCredential.user
                self.userId = userId
                
                // Save user ID to keychain
                do {
                    try KeychainItem.saveItem(key: "userId", value: userId)
                    self.isSignedIn = true
                } catch {
                    self.errorMessage = "Failed to save user ID: \(error.localizedDescription)"
                    return
                }
                
                // Get user name if provided
                if let fullName = appleIDCredential.fullName {
                    let name = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    
                    if !name.isEmpty {
                        self.userName = name
                        try? KeychainItem.saveItem(key: "userName", value: name)
                    }
                }
                
                // Get email if provided
                if let email = appleIDCredential.email {
                    self.userEmail = email
                    try? KeychainItem.saveItem(key: "userEmail", value: email)
                }
                
                // Handle user record creation in CloudKit
                createUserRecordInCloudKit(userId: userId)
            }
            
        case .failure(let error):
            self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            self.isSignedIn = false
        }
    }
    
    // Create or update user record in CloudKit
    private func createUserRecordInCloudKit(userId: String) {
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        // Check if a record already exists
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to query user record: \(error.localizedDescription)"
                }
                return
            }
            
            if let existingRecord = records?.first {
                // Update existing record if needed
                DispatchQueue.main.async {
                    print("User record exists in CloudKit")
                }
            } else {
                // Create new user record
                let newRecord = CKRecord(recordType: "UserProfile")
                newRecord["userId"] = userId
                newRecord["displayName"] = self?.userName ?? ""
                newRecord["email"] = self?.userEmail ?? ""
                newRecord["joinDate"] = Date()
                
                database.save(newRecord) { _, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.errorMessage = "Failed to create user record: \(error.localizedDescription)"
                        }
                    } else {
                        DispatchQueue.main.async {
                            print("Successfully created user record in CloudKit")
                        }
                    }
                }
            }
        }
    }
    
    // Sign out the user
    func signOut() {
        // Remove values from keychain
        try? KeychainItem.deleteItem(key: "userId")
        try? KeychainItem.deleteItem(key: "userName")
        try? KeychainItem.deleteItem(key: "userEmail")
        
        // Update published properties
        DispatchQueue.main.async { [weak self] in
            self?.isSignedIn = false
            self?.userId = nil
            self?.userName = nil
            self?.userEmail = nil
        }
    }
}

// Keychain helper for securely storing user credentials
struct KeychainItem {
    // MARK: - Types
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unexpectedItemData
        case unhandledError
    }
    
    // MARK: - Properties
    let service: String
    let accessGroup: String?
    private(set) var account: String
    
    // MARK: - Initializers
    init(service: String, account: String, accessGroup: String? = nil) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }
    
    // MARK: - Keychain Access
    func readItem() throws -> String {
        // Build a query to find the item
        var query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == noErr else { throw KeychainError.unhandledError }
        
        // Parse the password string from the query result
        guard let existingItem = queryResult as? [String: AnyObject],
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8)
        else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return password
    }
    
    func saveItem(_ password: String) throws {
        // Encode the password into an Data object
        let encodedPassword = password.data(using: String.Encoding.utf8)!
        
        // Check for an existing item in the keychain
        do {
            // Update the existing item with the new password
            try _ = readItem()
            
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedPassword as AnyObject?
            
            let query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned
            guard status == noErr else { throw KeychainError.unhandledError }
        } catch KeychainError.noPassword {
            // No password was found in the keychain, create a new item
            var newItem = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
            newItem[kSecValueData as String] = encodedPassword as AnyObject?
            
            // Add a the new item to the keychain
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned
            guard status == noErr else { throw KeychainError.unhandledError }
        }
    }
    
    func deleteItem() throws {
        // Delete the existing item from the keychain
        let query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)
        
        // Throw an error if an unexpected status was returned
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError }
    }
    
    // MARK: - Convenience
    static func readItem(key: String, service: String = "TeeMe.AppleSignIn") -> String? {
        do {
            let item = KeychainItem(service: service, account: key)
            return try item.readItem()
        } catch {
            print("Keychain read error: \(error)")
            return nil
        }
    }
    
    static func saveItem(key: String, value: String, service: String = "TeeMe.AppleSignIn") throws {
        let item = KeychainItem(service: service, account: key)
        try item.saveItem(value)
    }
    
    static func deleteItem(key: String, service: String = "TeeMe.AppleSignIn") throws {
        let item = KeychainItem(service: service, account: key)
        try item.deleteItem()
    }
    
    // MARK: - Helper Methods
    private static func keychainQuery(withService service: String, account: String? = nil, accessGroup: String? = nil) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}