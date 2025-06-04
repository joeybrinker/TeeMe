//
//  PostView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import SwiftUI
import FirebaseAuth

struct PostView: View {
    @EnvironmentObject var postViewModel: PostViewModel
    @StateObject var post: Post
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray.opacity(0.20))
            VStack(spacing: 0) {
                postHeader
                
                Spacer()
                
                courseName
                
                Spacer()
                
                mainContent
                
                Spacer()
                
                postFooter
                
            }
        }
        .frame(width: 325, height: 200)
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                postViewModel.deletePost(post)
                postViewModel.refreshPosts()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    var postHeader: some View {
        HStack{
            Text(post.user.displayName)
                .font(.headline.weight(.bold))
            Text("@\(post.user.username)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Menu button - only show if user owns the post
            if post.user.id == Auth.auth().currentUser?.uid {
                Menu {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.gray)
                        .font(.title3)
                }
            }
        }
        .frame(height: 16)
        .lineLimit(1)
        .allowsTightening(true)
        .minimumScaleFactor(0.25)
        .padding(.horizontal)
        .padding(.top)
    }
    
    var courseName: some View {
        Text(post.title.capitalized)
            .frame(height: 25)
            .font(.title3.weight(.light))
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(0.25)
            .padding(.horizontal)
    }
    
    var postFooter: some View {
        HStack(spacing: 4){
            Button {
                if post.isLiked {
                    post.dislikePost()
                } else {
                    post.likePost()
                }
            } label: {
                ZStack{
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundStyle(post.isLiked ? .green : .gray.opacity(0.50))
                }
            }
            .padding(.leading)
            
            Text("\(post.likes)")
                .font(.caption.weight(.medium))
            
            Spacer()
            
            Text(post.datePosted)
                .font(.caption.weight(.thin))
                .padding(.trailing)
        }
        .padding(.bottom)
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
                    Text("\(post.score)")
                        .foregroundStyle(.green)
                        .font(.title.bold())
                }
            }
            ZStack{
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.gray.opacity(0.25))
                    .frame(width: 70, height: 70)
                VStack{
                    Text("Holes")
                        .font(.caption2)
                    Text(post.holes.isEmpty ? "--" :    post.holes)
                        .foregroundStyle(.green)
                        .font(.title.bold())
                }
            }
            ZStack{
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.gray.opacity(0.25))
                    .frame(width: 70, height: 70)
                VStack{
                    Text("GIR")
                        .font(.caption2)
                    Text(post.greensInRegulation.isEmpty ? "--" : post.greensInRegulation)
                        .foregroundStyle(.green)
                        .font(.title.bold())
                }
            }
        }
        .frame(height: 70)
    }
}

#Preview {
    PostView(post: Post(user: UserProfileModel(id: "firebaseID", username: "username", displayName: "displayname", dateJoined: Date()) ,title: "Detroit Golf Club", score: "72", holes: "18", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"))
        .environmentObject(PostViewModel())
}
