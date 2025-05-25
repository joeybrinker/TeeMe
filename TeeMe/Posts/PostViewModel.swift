//
//  PostViewModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import Foundation
import SwiftUI

class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    
    func likePost(_ post: Post) {
        post.likes += 1
    }
}
