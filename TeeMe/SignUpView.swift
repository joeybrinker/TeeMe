//
//  SignUpView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/6/25.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isSignedIn = false
    
    var body: some View {
        if isSignedIn {
            ContentView()
                .toolbarVisibility(.hidden)
        } else {
            signUpContent
        }
    }
    
    private var signUpContent: some View {
        NavigationStack {
            ZStack {
                Color.green
                    .ignoresSafeArea()
                Circle()
                    .scale(1.7)
                    .foregroundStyle(.white.opacity(0.35))
                Circle()
                    .scale(1.35)
                    .foregroundStyle(.white.opacity(0.75))
                
                VStack {
                    Text("Sign Up")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.green)
                                        
                    VStack {
                        TextField("Email", text: $email)
                            .padding()
                            .frame(width: 300, height: 50)
                            .background(Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .frame(width: 300, height: 50)
                            .background(Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Button("Sign Up") {
                            signUp()
                        }
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 300, height: 50)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        HStack {
                            Rectangle()
                                .frame(width: 120, height: 1)
                            Text("or")
                            Rectangle()
                                .frame(width: 120, height: 1)
                        }
                        .foregroundStyle(.green)
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign In")
                                .frame(width: 300, height: 50)
                                .foregroundStyle(Color.green)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.green, lineWidth: 2)
                                }
                        }
                    }
                    .tint(.green)
                    
                }
                .onAppear {
                    Auth.auth().addStateDidChangeListener { _, user in
                        if user != nil {
                            isSignedIn.toggle()
                        }
                    }
                }
                
                Text(errorMessage)
                    .foregroundStyle(.white)
                    .offset(y: 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    // Sign up function
    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(CourseDataModel())
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
