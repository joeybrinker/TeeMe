//
//  FeedView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/27/25.
//

import SwiftUI

struct FeedView: View {
    @StateObject var postViewModel = PostViewModel()
    
    @State var showAddPostView = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                ScrollView {
                    VStack{
                        ForEach(postViewModel.posts, id: \.self) { post in
                            PostView(post: post)
                                .padding(.top)
                        }
                    }
                }
                .navigationTitle(Text("Feed"))
                .toolbar {
                    ToolbarItem {
                        Button {
                            showAddPostView = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .sheet(isPresented: $showAddPostView){ AddPostView(postVM: postViewModel)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(UserProfileViewModel())
}
