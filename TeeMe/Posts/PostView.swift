//
//  PostView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 5/20/25.
//

import SwiftUI

struct PostView: View {
    
    @ObservedObject var viewModel = PostViewModel()
    
    var body: some View {
        
    }
}

#Preview {
    PostView(viewModel: PostViewModel())
}
