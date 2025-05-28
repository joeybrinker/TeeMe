//
//  AddPostView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/27/25.
//

import SwiftUI

struct AddPostView: View {
    @EnvironmentObject var userViewModel: UserProfileViewModel
    
    @State var postVM: PostViewModel
    
    @State private var title = ""
    @State private var score = ""
    @State private var holes = ""
    @State private var greensInRegulation = ""
    
    @State private var showError: Bool = false
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray.opacity(0.15))
            VStack(spacing: 0) {
                postHeader
                    .padding(.top)
                
                Spacer()
                
                courseName
                
                Spacer()
                
                mainContent
                
                Spacer()
                
                HStack {
                    likeButton
                        .padding()
                    Spacer()
                }
            }
        }
        .frame(width: 325, height: 200)
        
        Button {
            if checkCases() {
                postVM.addPost(Post(user: userViewModel.currentUser,title: title, score: score, holes: holes, greensInRegulation: greensInRegulation))
            }
            else {
                showError = true
            }
        } label: {
            ZStack{
                Capsule()
                    .frame(width: 128, height: 48)
                    .foregroundStyle(.green)
                Text("Post")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage()))
        }
    }
    
    var postHeader: some View {
        HStack{
            Text(userViewModel.currentUser.displayName)
                .font(.headline.weight(.bold))
                .frame(height: 16)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.25)
                .padding(.horizontal)
            Spacer()
        }
    }
    
    var courseName: some View {
        TextField("Course", text: $title)
            .frame(height: 25)
            .font(.title3.weight(.light))
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(0.25)
            .padding(.horizontal)
    }
    
    var likeButton: some View {
        Image(systemName: "hand.thumbsup.fill")
            .foregroundStyle(.gray.opacity(0))
    }
    
    var mainContent: some View {
        HStack {
            ZStack{
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.gray.opacity(0.25))
                    .frame(width: 70, height: 70)
                VStack {
                    Text("Score")
                        .font(.caption2)
                    TextField("--", text: $score)
                        .foregroundStyle(.green)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            ZStack{
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.gray.opacity(0.25))
                    .frame(width: 70, height: 70)
                VStack{
                    Text("Holes")
                        .font(.caption2)
                    TextField("--", text: $holes)
                        .foregroundStyle(.green)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            ZStack{
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.gray.opacity(0.25))
                    .frame(width: 70, height: 70)
                VStack{
                    Text("GIR")
                        .font(.caption2)
                    TextField("--", text: $greensInRegulation)
                        .foregroundStyle(.green)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
        }
        .frame(height: 70)
    }
    
    func checkCases() -> Bool {
        // Return true when both fields are full and the score is an int
        if !title.isEmpty && !score.isEmpty {
            for char in score {
                if char.isNumber == false {
                    return false
                }
            }
            if Int(score) ?? 0 < 1000 && Int(holes) ?? 0 < 19 && Int(greensInRegulation) ?? 0 < 19{
                return true
            } else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    func errorMessage() -> String {
        if !title.isEmpty && !score.isEmpty {
            for char in score {
                if char.isNumber == false {
                    return "Must enter a number for Score"
                }
            }
            for char in holes {
                if char.isNumber == false {
                    return "Must enter a number for Holes"
                }
            }
            for char in greensInRegulation {
                if char.isNumber == false {
                    return "Must enter a number for Greens In Regulation"
                }
            }
            if Int(score) ?? 0 < 1000 && Int(holes) ?? 0 < 19 && Int(greensInRegulation) ?? 0 < 19{
                return ""
            } else {
                return "Must be a reasonable number"
            }
            
        }
        else {
            return "Must enter a title and score"
        }
    }
}

#Preview {
    AddPostView(postVM: PostViewModel())
        .environmentObject(UserProfileViewModel())
}
