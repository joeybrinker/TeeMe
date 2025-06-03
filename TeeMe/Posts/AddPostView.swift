//
//  AddPostView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/27/25.
//

import SwiftUI

struct AddPostView: View {
    @EnvironmentObject var userViewModel: UserProfileViewModel
    @EnvironmentObject var courseModel: CourseDataModel
    @Environment(\.dismiss) var dismiss
    
    @State var postVM: PostViewModel
    
    @State private var title = ""
    @State private var score = ""
    @State private var holes = ""
    @State private var greensInRegulation = ""
    @State private var showError: Bool = false
    @State private var isPosting: Bool = false
    
    private var courseNames: [String] {
        courseModel.favoriteCourses.compactMap { $0.name }
    }
    
    var conditionCheck: Bool {
        if holes.isEmpty || greensInRegulation.isEmpty{
            true
        } else {
            Int(score) ?? 0 < 1000 && Int(holes) ?? 0 < 19 && Int(greensInRegulation) ?? 0 < 19 && Int(score) ?? 0 > 0 && Int(holes) ?? 0 > 0 && Int(greensInRegulation) ?? 0 > 0
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Preview of the post
                postPreview
                
                // Post button
                Button {
                    createPost()
                } label: {
                    ZStack {
                        Capsule()
                            .frame(width: 128, height: 48)
                            .foregroundStyle(isPosting ? .gray : .green)
                        
                        if isPosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Post")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share Your Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage()))
            }
        }
    }
    
    var postPreview: some View {
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
        Picker("", selection: $title){
            Text(courseModel.favoriteCourses.isEmpty ? "Favorite a course to get started" : "Select Favorite Course*").tag("")
            ForEach(courseNames, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        .pickerStyle(.automatic)
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
                    Text("Score*")
                        .font(.caption2)
                    TextField("--", text: $score)
                        .foregroundStyle(.green)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.numberPad)
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
                        .keyboardType(.numberPad)
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
                        .keyboardType(.numberPad)
                }
            }
        }
        .frame(height: 70)
    }
    
    // MARK: - Methods
    
    func createPost() {
        guard isValidPost() else {
            showError = true
            return
        }
        
        userViewModel.loadCurrentUser()
        
        isPosting = true
        
        let newPost = Post(
            user: userViewModel.currentUser,
            title: title,
            score: score,
            holes: holes,
            greensInRegulation: greensInRegulation,
            datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"
        )
        
        postVM.addPost(newPost)
        
        // Give a moment for the post to save, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isPosting = false
            dismiss()
        }
    }
    
    func isValidPost() -> Bool {
        return !title.isEmpty && !score.isEmpty && checkCases()
    }
    
    func checkCases() -> Bool {
        // Return true when both fields are full and the score is an int
        if !title.isEmpty && !score.isEmpty {
            for char in score {
                if char.isNumber == false {
                    return false
                }
            }

            if conditionCheck {
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
                    return "Must enter a number for GIR"
                }
            }
            if conditionCheck {
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
        .environmentObject(CourseDataModel())
}
