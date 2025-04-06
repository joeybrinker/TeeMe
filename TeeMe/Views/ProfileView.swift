//
//  UpdatedProfileView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  UpdatedProfileView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import CloudKit

struct ProfileView: View {
    @StateObject private var profileModel = UserProfileModel()
    @EnvironmentObject var authService: AppleAuthService
    @State private var isEditingProfile = false
    @State private var editedDisplayName = ""
    @State private var editedHandicap = ""
    @State private var editedHomeCourseName = ""
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                if profileModel.isLoading {
                    loadingView
                } else if let profile = profileModel.currentProfile {
                    profileContentView(profile)
                } else {
                    Text("No profile available")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    signOutButton
                }
            }
            .alert("Error", isPresented: Binding(
                get: { profileModel.errorMessage != nil },
                set: { if !$0 { profileModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(profileModel.errorMessage ?? "")
            }
            .sheet(isPresented: $isEditingProfile) {
                editProfileView
            }
            .onAppear {
                // Load user profile when view appears
                if let userId = authService.userId {
                    profileModel.loadUserProfile(userId: userId)
                }
            }
        }
    }
    
    // Background gradient view
    private var backgroundView: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.1), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // Loading indicator
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading profile...")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
    }
    
    // Main profile content
    private func profileContentView(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile header
                profileHeaderView(profile)
                
                Divider()
                
                // Stats Section
                statsView(profile)
                
                Divider()
                
                // Recent Activity
                recentActivityView()
                
                // Account Info Section
                accountInfoView(profile)
                
                // Edit button
                Button {
                    prepareForEditing(profile)
                } label: {
                    Text("Edit Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // Profile header with avatar and name
    private func profileHeaderView(_ profile: UserProfile) -> some View {
        VStack {
            // Profile picture
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 100, height: 100)
                
                Text(String(profile.displayName.prefix(1).uppercased()))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 5)
            
            // Name and membership info
            Text(profile.displayName.isEmpty ? authService.userName ?? "Golfer" : profile.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Member since \(profile.joinDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // Stats view with handicap and average score
    private func statsView(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading) {
            Text("Golf Stats")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Handicap",
                    value: profile.handicap != nil ? String(format: "%.1f", profile.handicap!) : "N/A",
                    icon: "figure.golf"
                )
                
                StatCard(
                    title: "Avg Score",
                    value: profile.averageScore != nil ? "\(profile.averageScore!)" : "N/A",
                    icon: "chart.bar.fill"
                )
            }
            .padding(.horizontal)
        }
    }
    
    // Recent activity view
    private func recentActivityView() -> some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            NavigationLink {
                Text("Scorecard History")
                    .navigationTitle("Scorecard History")
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .frame(width: 30)
                    Text("View Scorecards")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink {
                Text("Upcoming Tee Times")
                    .navigationTitle("Upcoming Tee Times")
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .frame(width: 30)
                    Text("Upcoming Tee Times")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Account info section
    private func accountInfoView(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading) {
            Text("Account Information")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 10)
            
            VStack(spacing: 15) {
                HStack {
                    Text("Email")
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Text(profile.email)
                    Spacer()
                }
                
                HStack {
                    Text("Home Course")
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Text(profile.homeCourseName ?? "Not set")
                    Spacer()
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.05), radius: 5)
            .padding(.horizontal)
        }
    }
    
    // Sign out button
    private var signOutButton: some View {
        Button {
            showingSignOutAlert = true
        } label: {
            Text("Sign Out")
                .foregroundStyle(.red)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // Edit profile sheet
    private var editProfileView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Display Name", text: $editedDisplayName)
                    TextField("Handicap", text: $editedHandicap)
                        .keyboardType(.decimalPad)
                    TextField("Home Course", text: $editedHomeCourseName)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditingProfile = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
        }
    }
    
    // Prepare for editing profile
    private func prepareForEditing(_ profile: UserProfile) {
        editedDisplayName = profile.displayName
        editedHandicap = profile.handicap != nil ? String(profile.handicap!) : ""
        editedHomeCourseName = profile.homeCourseName ?? ""
        isEditingProfile = true
    }
    
    // Save updated profile
    private func saveProfile() {
        let handicap = Double(editedHandicap)
        profileModel.updateProfile(
            displayName: editedDisplayName,
            handicap: handicap,
            homeCourseName: editedHomeCourseName
        )
        isEditingProfile = false
    }
}

// Helper view for stat cards
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(Color.green)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
            }
            
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppleAuthService())
}
