//
//  TeeMeApp.swift
//  TeeMe
//
//  Created by Joseph Brinker on 10/5/24.
//  Updated by Claude on 4/1/25.
//

import SwiftUI
import CloudKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TeeMeApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create shared course data model
    @StateObject private var courseModel = CourseDataModel()
    
    // Apple authentication service
    @StateObject private var authService = AppleAuthService()
    
    // Enable CloudKit features
    @StateObject private var cloudKitVM = CloudKitTeeMeViewModel()
    
    var body: some Scene {
        WindowGroup {
            // Show main app if signed in, otherwise show sign in view
            if authService.isSignedIn && cloudKitVM.isSignedInToiCloud {
                MainTabView()
                    .environmentObject(courseModel)
                    .environmentObject(authService)
                    .onAppear {
                        // Request notification permissions for tee time reminders
                        requestNotificationPermissions()
                    }
            } else {
                Group {
                    if !cloudKitVM.isSignedInToiCloud {
                        // Show iCloud sign-in message if not signed in to iCloud
                        iCloudSignInView
                    } else {
                        // Show Apple Sign In screen
                        AppleSignInView()
                            .environmentObject(authService)
                    }
                }
                .onAppear {
                    // Ensure CloudKit is checked
                    cloudKitVM.getiCloudStats()
                }
            }
        }
    }
    
    // Request permissions for user notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    // View shown when user is not signed in to iCloud
    private var iCloudSignInView: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("iCloud Account Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please sign in to iCloud in your device settings to use TeeMe. All your data will be securely stored and synced across your devices.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                // Try to refresh iCloud status
                cloudKitVM.getiCloudStats()
            } label: {
                Text("Refresh")
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top)
        }
        .padding()
    }
}

// Main tab view that contains all the app's primary views
struct MainTabView: View {
    @EnvironmentObject var courseModel: CourseDataModel
    @EnvironmentObject var authService: AppleAuthService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map tab for finding courses
            UpdatedMapView()
                .environmentObject(courseModel)
                .tabItem {
                    Label("Find Courses", systemImage: "map")
                }
                .tag(0)
            
            // Tee times tab
            TeeTimeBookingView()
                .tabItem {
                    Label("Tee Times", systemImage: "calendar")
                }
                .tag(1)
            
            // Scorecard tab
            ScorecardView()
                .tabItem {
                    Label("Scorecard", systemImage: "list.bullet.clipboard")
                }
                .tag(2)
            
            // Social tab
            GolferSocialView()
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }
                .tag(3)
            
            // Favorites tab
            FavoritesView()
                .environmentObject(courseModel)
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
                .tag(4)
            
            // Profile tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(5)
        }
        // Pass the auth service to any view that needs it
        .environmentObject(authService)
    }
}
