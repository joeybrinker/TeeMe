//
//  PostViewModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import Foundation
import SwiftUI

class PostViewModel: ObservableObject {
    @Published var posts: [Post] = [
        Post(
            user: UserProfileModel(
                id: "",
                username: "user1",
                displayName: "joebob",
                handicap: 12,
                dateJoined: Date()
            ),
            title: "Hello",
            score: "12",
            holes: "",
            greensInRegulation: "1"
        ),
        Post(
            user: UserProfileModel(
                id: "",
                username: "abcdefg1",
                displayName: "user15",
                dateJoined: Date()
            ) ,
            title: "HELOO",
            score: "hahaha",
            holes: "12",
            greensInRegulation: "3"
        )
    ]
    
    func addPost(_ post: Post) {
        self.posts.append(post)
    }
}
