//
//  ProfileSetupView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/27/25.
//
// Purpose: This file defines the profile setup/edit view for the TeeMe golf app.
// It allows users to create or edit their profile information including username,
// display name, and handicap.

import SwiftUI

/// ProfileSetupView: A view that allows users to set up or edit their profile
/// Handles both new profile creation and editing of existing profiles
struct ProfileSetupView: View {
    // MARK: - Properties
    
    // StateObject to maintain the view model instance throughout the view lifecycle
    @StateObject var viewModel = UserProfileViewModel()
    
    // State variables to hold form input values
    @State private var username: String = ""       // User's unique username
    @State private var displayName: String = ""    // User's display name
    @State private var handicap = ""               // User's golf handicap (optional)
    @State private var isProfileComplete: Bool = false  // Flag to show content view when profile is complete
    
    // Environment objects and values
    @EnvironmentObject var courseModel: CourseDataModel  // Course data injected from parent
    @Environment(\.dismiss) var dismiss  // Environment value to dismiss this view
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    profileFormView
                    
                    // Submit button - saves profile information
                    Button {
                        saveProfile()
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 300, height: 50)
                                .foregroundStyle(.green)
                                .padding()
                            Text("Submit")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    // Disable button if required fields are empty
                    .disabled(username.isEmpty || displayName.isEmpty)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Set Up Your Profile")
                .navigationBarTitleDisplayMode(.inline)  // Use inline title style
                .toolbar {
                    // Add a cancel button to the top left of the navigation bar
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()  // Dismiss this view when Cancel is tapped
                        }
                    }
                }
            }
            .onAppear {
                // Pre-fill form with existing data if available
                // This happens when editing an existing profile
                if !viewModel.currentUser.id.isEmpty {
                    username = viewModel.currentUser.username
                    displayName = viewModel.currentUser.displayName
                    if let handicap = viewModel.currentUser.handicap {
                        self.handicap = String(handicap)
                    }
                }
            }
            // Display alert when there's an error message
            .alert(isPresented: Binding<Bool>(
                // Computed binding that's true when errorMessage is not nil
                get: { viewModel.errorMessage != nil },
                set: {if !$0 { viewModel.errorMessage = nil } }
            )) {
                // Create alert with error message
                Alert(title: Text("Error"),
                      message: Text(viewModel.errorMessage ?? "An unknown error occurred."),
                      dismissButton: .default(Text("OK")))
            }
            // Full screen cover to show the main content view when profile is complete
            .fullScreenCover(isPresented: $isProfileComplete) {
                ContentView()
                    .environmentObject(courseModel)  // Pass the course model to ContentView
            }
        }
    }
    
    // MARK: - Subviews
    
    /// The profile form containing fields for username, display name, and handicap
    private var profileFormView: some View {
        VStack(spacing: 15) {
            // Profile icon placeholder
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.gray)
                .padding(.bottom, 20)
            
            // Username field with label
            VStack(alignment: .leading) {
                Text("Username")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("@username", text: $username)  // Bind to username state
                    .textContentType(.username)  // Hint for autofill
                    .textInputAutocapitalization(.never)  // Don't auto-capitalize
                    .keyboardType(.default)
                    .autocorrectionDisabled(true)  // Disable autocorrection
                    .padding()
                    .background(Color(.systemGray6))  // Light gray background
                    .clipShape(RoundedRectangle.init(cornerRadius: 8))  // Rounded corners
            }
            
            // Display name field with label
            VStack(alignment: .leading) {
                Text("Display Name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("Your name", text: $displayName)  // Bind to displayName state
                    .textContentType(.name)  // Hint for autofill
                    .keyboardType(.default)
                    .padding()
                    .background(Color(.systemGray6))  // Light gray background
                    .clipShape(RoundedRectangle.init(cornerRadius: 8))  // Rounded corners
            }
            
            // Handicap field with label (optional)
            VStack(alignment: .leading) {
                Text("Handicap (optional)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("Your name", text: $handicap)  // Bind to handicap state
                    .keyboardType(.default)
                    .padding()
                    .background(Color(.systemGray6))  // Light gray background
                    .clipShape(RoundedRectangle.init(cornerRadius: 8))  // Rounded corners
            }
        }
    }
    
    //MARK: - Actions
    
    /// Saves the profile information to the database
    /// Calls the view model's saveProfile method and handles success/failure
    private func saveProfile() {
        // Call the view model method with form values and a completion handler
        viewModel.saveProfile(username: username, displayName: displayName, handicap: handicap) { success in
            if success {
                // If successful, dismiss the view
                dismiss()
            }
            // If not successful, the view model will set an error message
            // which will trigger the alert via the binding
        }
    }
}

/// SwiftUI Preview for this view
/// Creates an instance of ProfileSetupView for the preview canvas
#Preview {
    ProfileSetupView()
}
