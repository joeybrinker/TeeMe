//
//  PostModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import Foundation
import SwiftUI

class Post: ObservableObject, Hashable {
    
    let id: UUID = UUID()
    let user: UserProfileModel
    let title: String
    let score: String
    let holes: String
    let greensInRegulation: String
    //let yardage: String
    
    @Published var likes: Int = 0
    var isLiked: Bool = false
    
    init(user: UserProfileModel, title: String, score: String, holes: String, greensInRegulation: String) {
        self.user = user
        self.title = title
        self.score = score
        self.holes = holes
        self.greensInRegulation = greensInRegulation
    }
    
    func likePost() {
        likes += 1
        isLiked = true
    }
    
    func dislikePost() {
        likes -= 1
        isLiked = false
    }
    
    // MARK: - Hashable Conformance
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

