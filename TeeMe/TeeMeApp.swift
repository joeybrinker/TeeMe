//
//  TeeMeApp.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Start Google Mobile Ads
        MobileAds.shared.start(completionHandler: nil)
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Warning: GoogleService-Info.plist not found or CLIENT_ID missing")
            return true
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        return true
    }
    
    // Handle URL schemes for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct TeeMeApp: App {
    // Register app delegate for Firebase & other services setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create shared models
    @StateObject private var courseModel = CourseDataModel()
    @StateObject private var userProfileViewModel = UserProfileViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(courseModel)
                .environmentObject(userProfileViewModel)
                .onOpenURL { url in
                    // Handle Google Sign-In URLs
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
