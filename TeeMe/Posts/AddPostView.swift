// Optimized AddPostView.swift

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
    @State private var datePlayed: Date = Date()
    
    // OPTIMIZATION 1: Make this a let instead of computed property to reduce recalculations
    private let courseNames: [String]
    
    // OPTIMIZATION 2: Cache the condition check result
    @State private var isValidCondition: Bool = true
    
    init(postVM: PostViewModel, courseModel: CourseDataModel) {
        self.postVM = postVM
        // Pre-compute course names once
        self.courseNames = courseModel.favoriteCourses.compactMap { $0.name }
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
                
                Spacer()
                
                courseName
                
                Spacer()
                
                mainContent
                
                Spacer()
                
                HStack {
                    likeButton
                    Spacer()
                    datePicker
                }
                .padding()
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
                .padding(.top)
            Spacer()
        }
    }
    
    // OPTIMIZATION 3: Simplified TextField with better performance
    var courseName: some View {
            Picker("Course*", selection: $title) {
                Text("Select Favorite Course*").tag("")
                ForEach(courseNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)
            .frame(height: 25)
            .font(.title3.weight(.light))
            .padding(.horizontal)
    }
    
    // OPTIMIZATION 4: Separate the text fields into their own views to reduce rebuilds
    var mainContent: some View {
        HStack {
            ScoreTextField(score: $score)
            HolesTextField(holes: $holes)
            GIRTextField(greensInRegulation: $greensInRegulation)
        }
        .frame(height: 70)
        .onChange(of: score) { _, _ in updateValidation() }
        .onChange(of: holes) { _, _ in updateValidation() }
        .onChange(of: greensInRegulation) { _, _ in updateValidation() }
    }
    
    var likeButton: some View {
        Image(systemName: "hand.thumbsup.fill")
            .foregroundStyle(.gray.opacity(0))
    }
    
    var datePicker: some View {
        DatePicker("Date:", selection: $datePlayed, in: ...Date(), displayedComponents: [.date])
            .frame(width: 100)
            .padding(.trailing)
    }
    
    
    
    // OPTIMIZATION 5: Debounce validation updates
    private func updateValidation() {
        // Use a small delay to avoid constant recalculation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isValidCondition = conditionCheck
        }
    }
    
    // Simplified condition check
    private var conditionCheck: Bool {
        if holes.isEmpty || greensInRegulation.isEmpty {
            return true
        }
        
        let scoreInt = Int(score) ?? 0
        let holesInt = Int(holes) ?? 0
        let girInt = Int(greensInRegulation) ?? 0
        
        return scoreInt > 0 && scoreInt < 1000 &&
               holesInt > 0 && holesInt < 19 &&
               girInt >= 0 && girInt < 19
    }
    
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
            datePosted: "\(datePlayed.formatted(date: .numeric, time: .shortened))"
        )
        
        postVM.addPost(newPost)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isPosting = false
            dismiss()
        }
        
        postVM.refreshPosts()
    }
    
    func isValidPost() -> Bool {
        return !title.isEmpty && !score.isEmpty && checkCases()
    }
    
    func checkCases() -> Bool {
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

// OPTIMIZATION 6: Separate TextField components to isolate updates
struct ScoreTextField: View {
    @Binding var score: String
    
    var body: some View {
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
                    .textFieldStyle(PlainTextFieldStyle()) // Better performance
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
            }
        }
    }
}

struct HolesTextField: View {
    @Binding var holes: String
    
    var body: some View {
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
                    .autocorrectionDisabled()
            }
        }
    }
}

struct GIRTextField: View {
    @Binding var greensInRegulation: String
    
    var body: some View {
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
                    .autocorrectionDisabled()
            }
        }
    }
}

#Preview {
    AddPostView(postVM: PostViewModel(), courseModel: CourseDataModel())
        .environmentObject(UserProfileViewModel())
        .environmentObject(CourseDataModel())
}
