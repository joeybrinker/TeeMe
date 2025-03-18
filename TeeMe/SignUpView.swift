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
            MapView()
        } else {
            signUpContent
        }
    }
    
    private var signUpContent: some View {
        NavigationStack {
            ZStack {
                Color.green
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("Create Account")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        HStack {
                            TextField("", text: $email)
                                .textFieldStyle(.plain)
                                .placeholder(when: email.isEmpty) {
                                    Text("Email")
                                        .font(.headline)
                                        .bold()
                                }
                        }
                        Rectangle()
                            .frame(width: 350, height: 1)
                        
                        HStack {
                            SecureField("", text: $password)
                                .textFieldStyle(.plain)
                                .placeholder(when: password.isEmpty) {
                                    Text("Password")
                                        .font(.headline)
                                        .bold()
                                }
                        }
                        Rectangle()
                            .frame(width: 350, height: 1)
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        signUp()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 290, height: 55)
                                .foregroundStyle(.white)
                            Text("Sign Up")
                                .foregroundStyle(Color.green)
                        }
                    }
                    
                    HStack {
                        Rectangle()
                            .frame(width: 120, height: 1)
                        Text("or")
                        Rectangle()
                            .frame(width: 120, height: 1)
                    }
                    .foregroundStyle(.white)
                    
                    NavigationLink(destination: SignInView()) {
                        Text("Sign In")
                            .frame(width: 290, height: 55)
                            .foregroundStyle(Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white, lineWidth: 2)
                            }
                    }
                    
                    Spacer()
                }
                .frame(width: 350)
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
                    .frame(width: 350)
            }
        }
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
