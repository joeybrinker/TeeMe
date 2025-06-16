//
//  LogInPopUpView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/16/25.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject var courseModel: CourseDataModel
    @State private var errorMessage = ""
    @State private var isSigningIn = false
    @State private var currentNonce: String?
    
    var body: some View {
        ZStack {
            // Background layers
            Color.black
                .opacity(0.35)
                .ignoresSafeArea()
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 350, height: 600)
//                .foregroundStyle(LinearGradient(colors: [.gradientBottom, .gradientTop], startPoint: .bottomLeading, endPoint: .topTrailing))
                .foregroundStyle(.white)
                .padding()
            
            // Content
            VStack(spacing: 30) {

                // Header
                    VStack(spacing: 10) {
                        HStack{
                            Image(systemName: "figure.golf")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)
                            Spacer()
                        }
                        HStack{
                            Text("TeeMe")
                                .font(.system(size: 48).weight(.semibold))
                                .foregroundStyle(.black)
                            Spacer()
                        }
                        
                        Text("Sign in to save your favorite courses and track your golf rounds")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.leading)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                            .lineLimit(2)
                    }
                    .frame(width: 280)
                
                Spacer()
                                
                // Sign-in buttons
                VStack(spacing: 16) {
                    // Apple Sign-In Button
                    SignInWithAppleButton(.signIn) { request in
                        handleAppleSignInRequest(request)
                    } onCompletion: { result in
                        handleAppleSignInCompletion(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(width: 280, height: 50)
                    .cornerRadius(10)
                    
                    
                    GoogleSignInButton(action: signInWithGoogle)
                        .frame(width: 280, height: 50)
                        .disabled(isSigningIn)
                }
                
                // Loading indicator
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                }
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                        .lineLimit(4)
                }
                
                Spacer()
                
                // Cancel button
                Button("Cancel") {
                    courseModel.showSignIn = false
                }
                .font(.title3.weight(.bold))
                .foregroundStyle(.black)
                .padding()
            }
            .frame(width: 350, height: 500)
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                if user != nil {
                    courseModel.showSignIn = false
                    courseModel.loadFavoritesFromFirebase()
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In Methods
    
    private func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        currentNonce = randomNonceString()
        request.nonce = sha256(currentNonce!)
        request.requestedScopes = [.email, .fullName]
    }
    
    private func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        isSigningIn = true
        errorMessage = ""
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                isSigningIn = false
                errorMessage = "Failed to get Apple ID token"
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { result, error in
                isSigningIn = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                // Handle new user setup
                if let user = result?.user {
                    handleNewUserSetup(user: user,
                                     email: appleIDCredential.email)
                }
            }
            
        case .failure(let error):
            isSigningIn = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Google Sign-In Methods
    
    private func signInWithGoogle() {
        guard let presentingViewController = getRootViewController() else {
            errorMessage = "Unable to present sign-in"
            return
        }
        
        isSigningIn = true
        errorMessage = ""
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            isSigningIn = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                // Handle new user setup
                if let firebaseUser = result?.user {
                    handleNewUserSetup(user: firebaseUser,
                                     email: firebaseUser.email)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleNewUserSetup(user: User, email: String?) {
        // Create user document in Firestore
        createUserDocument(for: user)
        
        // Close the sign-in view
        courseModel.showSignIn = false
        
        // Load user's favorites
        courseModel.loadFavoritesFromFirebase()
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    // MARK: - Nonce Generation for Apple Sign-In
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    AuthView()
        .environmentObject(CourseDataModel())
}
