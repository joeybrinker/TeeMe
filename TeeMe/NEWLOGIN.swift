//
//  NEWLOGIN.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/16/25.
//

import SwiftUI
import FirebaseAuth

struct NEWLOGIN: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isSignedIn = false
    
    var body: some View {
        signUpContent
    }
    
    private var signUpContent: some View {
        ZStack{
            Color.black
                .opacity(0.35)
                .ignoresSafeArea()
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 350, height: 450)
                .foregroundStyle(.gray.opacity(0.9))
                .padding()
            VStack {
                Text("Join TeeMe")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)
                
                VStack {
                    TextField("Email", text: $email)
                        .padding()
                        .frame(width: 300, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    SecureField("Password", text: $password)
                        .padding()
                        .frame(width: 300, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text(errorMessage)
                        .font(.caption)
                        .frame(width: 300)
                    Button("Sign Up") {
                        signUp()
                    }
                    .foregroundStyle(.green)
                    .fontWeight(.bold)
                    .frame(width: 300, height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                }
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                if user != nil {
                    isSignedIn.toggle()
                }
            }
        }
    }
    
    // Sign up function
    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
            if let user = result?.user {
                createUserDocument(for: user)
            }
        }
    }
}

#Preview {
    NEWLOGIN()
        .environmentObject(CourseDataModel())
}
