//
//  LogInPopUpView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/16/25.
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @EnvironmentObject var courseModel: CourseDataModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isSignedIn = false
    @State private var showSignInView = false
    
    var body: some View {
        if showSignInView {
            authView(isSignIn: true)
        } else {
            authView(isSignIn: false)
        }
    }
    
    // Combined authentication view for both sign-up and sign-in
    private func authView(isSignIn: Bool) -> some View {
        ZStack {
            // Background layers
            Color.black
                .opacity(0.35)
                .ignoresSafeArea()
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 350, height: 600)
                .foregroundStyle(.white)
                .padding()
            
            // Content
            VStack {
                Spacer()
                
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text(isSignIn ? "Sign In" : "Create Account")
                            .font(.largeTitle.weight(.semibold))
                            .foregroundStyle(.black)
                        
                        Spacer().frame(height: 20)
                    }
                    .padding()
                    Spacer()
                }
                .padding(.horizontal)
                
                // Input fields
                TextField("", text: $email)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .frame(width: 300, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.black)
                    .autocorrectionDisabled()
                    .placeholder(when: email.isEmpty) {
                        Text("Email").foregroundStyle(.black.opacity(0.5))
                            .padding()
                    }
                
                SecureField("", text: $password)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .frame(width: 300, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.black)
                    .placeholder(when: password.isEmpty) {
                        Text("Password").foregroundStyle(.black.opacity(0.5))
                            .padding()
                    }
                
                // Error message
                Text(errorMessage)
                    .font(.caption)
                    .frame(width: 300)
                    .foregroundStyle(.black)
                
                // Action button
                Button(isSignIn ? "Sign In" : "Create Account") {
                    isSignIn ? signIn() : signUp()
                }
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .frame(width: 300, height: 50)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // Toggle between sign-in and sign-up
                HStack {
                    Text(isSignIn ? "If you do not have an account" : "If you already have an account")
                        .foregroundStyle(.black)
                    Button(isSignIn ? "Sign Up" : "Sign In") {
                        showSignInView.toggle()
                    }
                    .foregroundStyle(.green)
                }
                .font(.system(size: 16))
                
                Spacer()
                
                // Cancel button
                Button("Cancel") {
                    courseModel.showSignIn = false
                }
                .font(.body.weight(.bold))
                .foregroundStyle(.black)
                .padding()
            }
            .frame(width: 350, height: 600)
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                if user != nil {
                    isSignedIn.toggle()
                }
            }
        }
    }
    

    
    // Authentication functions
    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
            if let user = result?.user {
                createUserDocument(for: user)
                courseModel.showSignIn = false
            }
        }
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
            else{
                courseModel.showSignIn = false
            }
        }
    }
}

// Extension for the placeholder functionality
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(CourseDataModel())
}
