//
//  SignInView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/6/25.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isSignedIn = false
    
    var body: some View {
        if isSignedIn {
            MapView()
        } else {
            signInContent
        }
    }
    
    private var signInContent: some View {
        NavigationStack {
            ZStack {
                Color.green
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("Sign In")
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
                        signIn()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 290, height: 55)
                                .foregroundStyle(.white)
                            Text("Sign In")
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
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
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
    
    // Sign in function
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignInView()
}
