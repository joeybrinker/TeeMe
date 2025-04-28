//
//  UserProfileView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/26/25.
//
// Purpose: This file defines the user profile view for the TeeMe golf app.
// It handles different states: not signed in, profile not set up, and full profile view.

import SwiftUI     // Framework for building the UI
import FirebaseAuth // Library for Firebase authentication services

/// UserProfileView: The main view that displays user profile information
/// Uses an MVVM pattern with UserProfileViewModel to handle the data and business logic
struct UserProfileView: View {
    // MARK: - Properties
    
    // StateObject maintains the view model instance throughout the view lifecycle
    @StateObject private var viewModel = UserProfileViewModel()
    
    // EnvironmentObject injected from parent view to access course data
    @EnvironmentObject var courseModel: CourseDataModel
    
    // Local state to control the visibility of the profile edit sheet
    @State private var showingEditProfile: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        
        // User not signed in - Display sign-in prompt
        if Auth.auth().currentUser == nil {
            ZStack{
                notSignedInView   // Custom view defined below
                
                // Conditionally show the authentication view as an overlay
                if courseModel.showSignIn {
                    AuthView()    // Authentication view for login/signup
                }
            }
        }
        // Commented out loading state - Could be uncommented for use
//        // Loading state
//        else if viewModel.isLoading {
//            ProgressView()
//                .scaleEffect(1.5)
//                .padding()
//        }
        // Profile not set up - User is authenticated but hasn't completed profile
        else if viewModel.currentUser.id.isEmpty {
            profileNotSetupView   // Custom view defined below
                // Present the profile setup sheet when showingEditProfile is true
                .sheet(isPresented: $showingEditProfile) {
                    ProfileSetupView()
                        .environmentObject(courseModel) // Pass course data to setup view
                }
                .onAppear() {
                    viewModel.loadCurrentUser()
                }
        }
        // Profile View - Fully authenticated and profile set up
        else {
            NavigationStack{      // Container for navigable content
                ScrollView{       // Makes content scrollable
                    VStack(spacing: 20){
                        profileContentView  // Main profile content defined below
                    }
                    .padding()
                }
                .navigationTitle(Text("Profile"))  // Sets the navigation bar title
                .toolbar {
                    // Only show Edit button if user is authenticated and has a profile
                    if !viewModel.currentUser.id.isEmpty && Auth.auth().currentUser != nil {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Edit") {
                                showingEditProfile = true  // Toggle profile edit sheet
                            }
                        }
                    }
                }
                // Sheet for editing profile
                .sheet(isPresented: $showingEditProfile) {
                    ProfileSetupView()
                        .environmentObject(courseModel)
                        .environmentObject(viewModel)
                }
                // Enable pull-to-refresh functionality
                .refreshable {
                    viewModel.loadCurrentUser()  // Reload user data when pulled to refresh
                }
            }
            .onAppear {
                // Refresh profile data when the view appears
                viewModel.loadCurrentUser()
            }
        }
    }

    
    //MARK: - SubViews
    
    /// View displayed when user is not signed in
    /// Provides information and a sign-in button
    private var notSignedInView: some View {
        VStack(spacing: 20){
            // Unavailable content placeholder with description
            ContentUnavailableView("Sign In to View Your Profile",
                                  systemImage: "person.slash",
                                  description: Text("Create an account to track your golf scores and save favorite courses."))
            
            // Sign in button
            Button {
                courseModel.showSignIn = true  // Show authentication view when pressed
            } label: {
                ZStack{
                    // Green rounded rectangle button
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 300, height: 50)
                        .foregroundStyle(.green)
                        .padding()
                    // Button text
                    Text("Sign In")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
    
    /// View displayed when user is authenticated but profile is not set up
    /// Prompts user to complete their profile
    private var profileNotSetupView: some View {
        VStack(spacing: 20) {
            // Unavailable content placeholder with description
            ContentUnavailableView("Complete your profile",
                                  systemImage: "person.crop.circle.badge.plus",
                                  description: Text("Set up your golf profile to get the most out of TeeMe."))
            
            // Profile setup button
            Button {
                showingEditProfile = true  // Show profile setup view when pressed
            } label: {
                ZStack{
                    // Green rounded rectangle button
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 300, height: 50)
                        .foregroundStyle(.green)
                        .padding()
                    // Button text
                    Text("Set Up Profile")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
    
    
    /// Main content view for a fully configured profile
    /// Contains header, stats, favorites, and sign out button
    private var profileContentView: some View {
        VStack(spacing: 25){
            // Profile head with name and info
            profileHeaderView
            
            // Stats summary
            profileStatsView
            
            //Favourite Courses Preview
            favoritesPreviewView
            
            Spacer()
            
            // Sign out button
            Button("Sign Out") {
                do {
                    try Auth.auth().signOut()  // Firebase signOut method
                    viewModel.loadCurrentUser()  // Reload user state after sign out
                }
                catch {
                    print("Error signing out: \(error)")  // Error handling
                }
            }
            .foregroundStyle(.red)
            .padding(.top)
        }
    }
    
    /// Header section displaying user information and profile picture
    private var profileHeaderView: some View {
        VStack(spacing: 15) {
            // Profile Icon (placeholder system image)
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.gray)
            
            // Name and username
            VStack(spacing: 5) {
                Text(viewModel.currentUser.displayName)  // User's display name
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("@\(viewModel.currentUser.username)")  // Username with @ prefix
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Handicap display with green background
            Text("Handicap: \(viewModel.currentUser.handicapDisplay)")
                .font(.headline)
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.1))  // Light green background
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle.init(cornerRadius: 10))
            
            // Member since date
            Text("Member since: \(viewModel.currentUser.dateJoined.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle.init(cornerRadius: 12))
        .shadow(radius: 1)  // Add subtle shadow for card-like appearance
    }
    
    /// Section displaying user statistics
    /// Currently only shows favorite courses count, but designed to accommodate more stats
    private var profileStatsView: some View {
        HStack(spacing: 0) {
            statsItem(count: courseModel.favoriteCourses.count, label: "Favorites")
            // Additional stats items could be added here in the future
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle.init(cornerRadius: 12))
        .shadow(radius: 1)  // Add subtle shadow for card-like appearance
    }
    
    /// Reusable function to create a stats item view
    /// @param count: The numerical value to display
    /// @param label: The description for the stat
    private func statsItem(count: Int, label: String) -> some View {
        VStack(spacing: 5) {
            Text("\(count)")  // Display the count
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)  // Display the label
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)  // Take up available width
    }
    
    /// Section showing a preview of favorite courses
    /// Includes a header with navigation to the full favorites list
    private var favoritesPreviewView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Favorite Courses")
                    .font(.headline)
                Spacer()
                // Navigation link to Favorites View
                NavigationLink(destination: FavoritesView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
            .padding()
            
            // Display message when no favorites exist
            if courseModel.favoriteCourses.isEmpty {
                Text("You haven't favorited any courses yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            // If there were favorites, they would be displayed here
        }
    }
    
}

/// SwiftUI Preview for this view
/// Creates instances of required models for the preview canvas
#Preview {
    UserProfileView()
        .environmentObject(CourseDataModel())  // Inject course data model
        .environmentObject(UserProfileViewModel())  // Inject view model
}
