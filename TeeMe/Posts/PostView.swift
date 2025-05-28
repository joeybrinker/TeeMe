//
//  PostView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import SwiftUI

struct PostView: View {
        
    @StateObject var post: Post
    
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
    }
    
    var postHeader: some View {
        HStack{
            Text(post.user.displayName)
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
        Text(post.title.capitalized)
            .frame(height: 25)
            .font(.title3.weight(.light))
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(0.25)
            .padding(.horizontal)
    }
    
    var likeButton: some View {
        Button {
            if post.isLiked {
                post.dislikePost()
            } else {
                post.likePost()
            }
        } label: {
            ZStack{
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundStyle(post.isLiked ? .green : .gray.opacity(0.35))
            }
        }
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
    PostView(post: Post(user: UserProfileModel(id: "firebaseID", username: "username", displayName: "displayname", dateJoined: Date()) ,title: "Detroit Golf Club", score: "72", holes: "18", greensInRegulation: ""))
}
