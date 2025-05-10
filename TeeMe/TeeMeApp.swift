//
//  TeeMeApp.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
}

@main
struct TeeMeApp: App {
    // Register app delegate for Firebase & MobileAds setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create shared course data model
    @StateObject private var courseModel = CourseDataModel()
    
    var body: some Scene {
        WindowGroup {
            //CloudKitTeeMe()
            ContentView()
                .environmentObject(courseModel)
        }
    }
}
