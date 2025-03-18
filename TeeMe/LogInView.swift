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
        NavigationStack {
            ZStack {
                Color.green
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("TeeMe")
                            .font(.largeTitle.weight(.heavy))
                        Text("The best place to find courses near you.\nFor golfers, by golfers.")
                            .font(.body)
                    }
                    .foregroundStyle(Color.white)
                    .padding()
                    
                    VStack {
                        NavigationLink(destination: SignInView()) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: 290, height: 55)
                                    .foregroundStyle(.white)
                                Text("Sign In")
                                    .foregroundStyle(Color.green)
                            }
                        }
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .frame(width: 290, height: 55)
                                .foregroundStyle(Color.white)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white, lineWidth: 2)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical)
            }
        }
        .tint(Color.white)
    }
}

#Preview {
    LogInView()
}
