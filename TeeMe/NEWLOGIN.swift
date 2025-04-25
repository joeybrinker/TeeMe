//
//  NEWLOGIN.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/16/25.
//

import SwiftUI
import FirebaseAuth

struct NEWLOGIN: View {
    @EnvironmentObject var courseModel: CourseDataModel
    
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
                .frame(width: 350, height: 600)
                .foregroundStyle(.white)
                .padding()
            VStack {
                Spacer()
                VStack(alignment: .leading){
                    Image(systemName: "figure.golf")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    Text("Create Account")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.black)
                    
                    Spacer()
                        .frame(height: 20)
                }
                .padding()
                .frame(minWidth: 350)
                
                TextField("", text: $email)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .frame(width: 300, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .placeholder(when: email.isEmpty){
                        Text("Email").foregroundStyle(.black.opacity(0.5))
                            .padding()
                    }
                
                SecureField("", text: $password)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .frame(width: 300, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .placeholder(when: password.isEmpty){
                        Text("Password").foregroundStyle(.black.opacity(0.5))
                            .padding()
                    }
                Text(errorMessage)
                    .font(.caption)
                    .frame(width: 300)
                Button("Create Account") {
                    signUp()
                }
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .frame(width: 300, height: 50)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                HStack{
                    Text("If you already have an account")
                        .foregroundStyle(.black)
                    Button("Sign In"){
                        //Sign In Content
                    }
                    .foregroundStyle(.green)
                }
                .font(.system(size: 16))
                
                Spacer()
                
                Button("Cancel"){
                    courseModel.showSignIn = false
                }
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
    NEWLOGIN()
        .environmentObject(CourseDataModel())
}
