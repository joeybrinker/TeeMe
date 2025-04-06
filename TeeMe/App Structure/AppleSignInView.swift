//
//  AppleSignInView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  AppleSignInView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import AuthenticationServices

struct AppleSignInView: View {
    @EnvironmentObject var authService: AppleAuthService
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.green
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // App logo and name
                    VStack(alignment: .leading) {
                        Text("TeeMe")
                            .font(.largeTitle.weight(.heavy))
                        Text("The best place to find courses near you.\nFor golfers, by golfers.")
                            .font(.body)
                    }
                    .foregroundStyle(Color.white)
                    .padding()
                    
                    Spacer()
                    
                    // Apple Sign In button
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            authService.processSignInWithAppleResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // Privacy message
                    Text("Your information is securely handled using Apple's Sign In service.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authService.errorMessage ?? "An unknown error occurred")
            }
            .onChange(of: authService.errorMessage) { _, newValue in
                showingAlert = newValue != nil
            }
        }
    }
}

// Custom sign in with Apple button
struct SignInWithAppleButton: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let onRequest: ((ASAuthorizationAppleIDRequest) -> Void)?
    let onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    
    init(_ type: ASAuthorizationAppleIDButton.ButtonType = .signIn,
         onRequest: ((ASAuthorizationAppleIDRequest) -> Void)? = nil,
         onCompletion: ((Result<ASAuthorization, Error>) -> Void)? = nil) {
        self.type = type
        self.style = .white
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        private let parent: SignInWithAppleButton
        
        init(_ parent: SignInWithAppleButton) {
            self.parent = parent
        }
        
        @objc func buttonTapped() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            parent.onRequest?(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion?(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.onCompletion?(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first ?? UIWindow()
            return window
        }
    }
    
    // Helper to set the button style
    func signInWithAppleButtonStyle(_ style: ASAuthorizationAppleIDButton.Style) -> SignInWithAppleButton {
        SignInWithAppleButton(type, onRequest: onRequest, onCompletion: onCompletion)
    }
}

#Preview {
    AppleSignInView()
        .environmentObject(AppleAuthService())
}