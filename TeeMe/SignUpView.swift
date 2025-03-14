//
//  SignUpView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/6/25.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State var isSignedIn = false
    var body: some View {
        
        if isSignedIn {
            MapView()
        }
        else{
            SignUpContent
        }
        
    }
    
    var SignUpContent: some View {
        NavigationStack{
            ZStack{
                Color.green
                VStack{
                    Spacer()
                    Text("Create Account")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    VStack(spacing: 20){
                        HStack{
                            //Image(systemName: "envelope.fill")
                            TextField("", text: $email)
                                .textFieldStyle(.plain)
                                .placeholder(when: email.isEmpty){ //this is the placeholder
                                    Text("Email")
                                        .font(.headline)
                                        .bold()
                                }
                        }
                        Rectangle()
                            .frame(width: 350, height: 1)
                        
                        HStack{
                            //Image(systemName: "lock.fill")
                            SecureField ("", text: $password)
                                .textFieldStyle(.plain)
                                .placeholder(when: password.isEmpty){
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
                        //sign up
                        signUp()
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 290, height: 55)
                                .foregroundStyle(.white)
                            Text("Sign Up")
                                .foregroundStyle(Color.green)
                        }
                    }
                    HStack{
                        Rectangle()
                            .frame(width: 120, height: 1)
                        Text("or")
                        Rectangle()
                            .frame(width: 120, height: 1)
                    }
                    .foregroundStyle(.white)
                    //                    HStack{
                    //                        Text("Already have an account?")
                    //                        NavigationLink("Sign In", destination: SignInView())
                    //                    }
                    //                    .foregroundStyle(.white)
                    NavigationLink(destination: SignInView()){
                        Text("Sign In")
                            .frame(width: 290, height: 55)
                            .foregroundStyle(Color.white)
                            .overlay{
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white, lineWidth: 2)
                            }
                    }
                    Spacer()
                }
                .frame(width: 350)
                .onAppear {
                    Auth.auth().addStateDidChangeListener { auth, user in
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
            .ignoresSafeArea()
        }
    }
    
    // Sign up function
    func signUp(){
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if error != nil {
                errorMessage = String(error!.localizedDescription)
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
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
