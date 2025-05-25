//
//  PostModel.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import Foundation
import SwiftUI

class Post {
    let title: String
    let content: String
    var likes: Int = 0
    
    init(title: String, content: String) {
        self.title = title
        self.content = content
    }
}
