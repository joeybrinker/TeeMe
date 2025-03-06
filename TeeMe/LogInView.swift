//
//  LogInView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 3/6/25.
//

import SwiftUI

struct LogInView: View {
    @State private var signIn = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                Color.green
                    .ignoresSafeArea()
                VStack{
                    Spacer()
                    VStack(alignment: .leading){
                            Text("TeeMe")
                                .fontWeight(.heavy)
                                .font(.system(size: 36))
                        Text("The best place to find courses near you.\nFor golfers, by golfers.")
                    }
                    .foregroundStyle(Color.white)
                    .padding()
                    VStack{
                        NavigationLink(destination: SignInView()){
                            Text("Sign In")
                                .frame(width: 290, height: 55)
                                .background(Color.white)
                                .foregroundStyle(Color.green)
                                .clipShape(.buttonBorder)
                        }
                        
                        NavigationLink(destination: SignUpView()){
                            Text("Sign Up")
                                .frame(width: 290, height: 55)
                                .foregroundStyle(Color.white)
                                .border(.white, width: 2)
                                .clipShape(.buttonBorder)
                              
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

#Preview {
    LogInView()
}
