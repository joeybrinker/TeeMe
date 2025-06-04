//
//  CourseGroupView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 6/4/25.
//

import SwiftUI

struct CourseGroupView: View {
    let courseName: String
    let posts: [Post]
    @State private var isExpanded: Bool = false
    
    // Sort posts by date (most recent first)
    private var sortedPosts: [Post] {
        posts.sorted { (post1: Post, post2: Post) in
            // Convert datePosted strings to dates for proper sorting
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            
            let date1 = formatter.date(from: post1.datePosted) ?? Date.distantPast
            let date2 = formatter.date(from: post2.datePosted) ?? Date.distantPast
            
            return date1 > date2
        }
    }
    
    // Calculate stats for this course
    private var courseStats: (bestScore: Int?, averageScore: Double, totalRounds: Int) {
        let scores = posts.compactMap { Int($0.score) }
        let bestScore = scores.min()
        let averageScore = scores.isEmpty ? 0 : Double(scores.reduce(0, +)) / Double(scores.count)
        return (bestScore, averageScore, scores.count)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Course header with stats
            courseHeader
            
            // Posts list (collapsible)
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(sortedPosts, id: \.self) { post in
                        PostView(post: post)
                            .environmentObject(PostViewModel()) // You might need to pass this properly
                    }
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(.horizontal)
    }
    
    private var courseHeader: some View {
        VStack(spacing: 8) {
            // Course name and expand/collapse button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(courseName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("\(courseStats.totalRounds) round\(courseStats.totalRounds == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            // Stats summary
            HStack(spacing: 20) {
                if let bestScore = courseStats.bestScore {
                    StatItem(title: "Best", value: "\(bestScore)")
                }
                
                if courseStats.totalRounds > 1 {
                    StatItem(title: "Average", value: String(format: "%.1f", courseStats.averageScore))
                }
                
                StatItem(title: "Last Played", value: sortedPosts.first?.datePosted ?? "")
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(.green)
        }
    }
}
