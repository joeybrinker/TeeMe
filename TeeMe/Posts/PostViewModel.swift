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
        // Complete posts with all stats
        Post(user: UserProfileModel(id: "1", username: "golfpro_mike", displayName: "Mike Johnson", handicap: 2.5, dateJoined: Date().addingTimeInterval(-86400 * 365)),
             title: "Pebble Beach Golf Links", score: "72", holes: "18", greensInRegulation: "14", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "2", username: "sarah_golfs", displayName: "Sarah Williams", handicap: 8.2, dateJoined: Date().addingTimeInterval(-86400 * 280)),
             title: "Augusta National Golf Club", score: "79", holes: "18", greensInRegulation: "10", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "3", username: "scottish_links", displayName: "James MacLeod", handicap: 12.0, dateJoined: Date().addingTimeInterval(-86400 * 450)),
             title: "St. Andrews Links", score: "85", holes: "18", greensInRegulation: "8", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "4", username: "weekend_warrior", displayName: "Lisa Chen", handicap: 18.5, dateJoined: Date().addingTimeInterval(-86400 * 120)),
             title: "Torrey Pines Golf Course", score: "92", holes: "18", greensInRegulation: "6", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "5", username: "tiger_woods_fan", displayName: "David Rodriguez", handicap: 15.3, dateJoined: Date().addingTimeInterval(-86400 * 200)),
             title: "TPC Sawgrass", score: "88", holes: "18", greensInRegulation: "12", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        // Posts with missing GIR stats
        Post(user: UserProfileModel(id: "6", username: "quick_nine", displayName: "Emma Thompson", handicap: 6.8, dateJoined: Date().addingTimeInterval(-86400 * 90)),
             title: "Riviera Country Club", score: "42", holes: "9", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "7", username: "black_course_beast", displayName: "Robert Garcia", handicap: 22.1, dateJoined: Date().addingTimeInterval(-86400 * 300)),
             title: "Bethpage Black", score: "95", holes: "18", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "8", username: "pinehurst_player", displayName: "Amanda Foster", handicap: 11.7, dateJoined: Date().addingTimeInterval(-86400 * 180)),
             title: "Pinehurst No. 2", score: "81", holes: "18", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "9", username: "straits_survivor", displayName: "Kevin O'Brien", handicap: nil, dateJoined: Date().addingTimeInterval(-86400 * 60)),
             title: "Whistling Straits", score: "89", holes: "18", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        // Posts with missing holes stats
        Post(user: UserProfileModel(id: "10", username: "oakmont_ace", displayName: "Jessica Park", handicap: 4.2, dateJoined: Date().addingTimeInterval(-86400 * 500)),
             title: "Oakmont Country Club", score: "76", holes: "", greensInRegulation: "11", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "11", username: "winged_foot_walker", displayName: "Michael Davis", handicap: 9.8, dateJoined: Date().addingTimeInterval(-86400 * 240)),
             title: "Winged Foot Golf Club", score: "82", holes: "", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "12", username: "congressional_champ", displayName: "Rachel Kim", handicap: 13.5, dateJoined: Date().addingTimeInterval(-86400 * 350)),
             title: "Congressional Country Club", score: "84", holes: "", greensInRegulation: "9", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        // Posts with both missing
        Post(user: UserProfileModel(id: "13", username: "kiawah_kid", displayName: "Tyler Brown", handicap: 25.0, dateJoined: Date().addingTimeInterval(-86400 * 30)),
             title: "Kiawah Island Golf Resort", score: "98", holes: "", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "14", username: "bandon_wanderer", displayName: "Sophia Martinez", handicap: 16.2, dateJoined: Date().addingTimeInterval(-86400 * 400)),
             title: "Bandon Dunes Golf Resort", score: "91", holes: "", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "15", username: "shinnecock_shooter", displayName: "Andrew Wilson", handicap: nil, dateJoined: Date().addingTimeInterval(-86400 * 150)),
             title: "Shinnecock Hills Golf Club", score: "87", holes: "", greensInRegulation: "", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        // More complete posts
        Post(user: UserProfileModel(id: "16", username: "spyglass_spy", displayName: "Nicole Taylor", handicap: 7.1, dateJoined: Date().addingTimeInterval(-86400 * 320)),
             title: "Spyglass Hill Golf Course", score: "74", holes: "18", greensInRegulation: "15", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "17", username: "chambers_challenger", displayName: "Chris Anderson", handicap: 19.8, dateJoined: Date().addingTimeInterval(-86400 * 75)),
             title: "Chambers Bay Golf Course", score: "93", holes: "18", greensInRegulation: "7", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "18", username: "bay_hill_birdie", displayName: "Megan White", handicap: 10.4, dateJoined: Date().addingTimeInterval(-86400 * 220)),
             title: "Bay Hill Club & Lodge", score: "83", holes: "18", greensInRegulation: "9", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "19", username: "cypress_crusher", displayName: "Jonathan Lee", handicap: 1.8, dateJoined: Date().addingTimeInterval(-86400 * 600)),
             title: "Cypress Point Club", score: "69", holes: "18", greensInRegulation: "16", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))"),
        
        Post(user: UserProfileModel(id: "20", username: "harbour_hero", displayName: "Ashley Johnson", handicap: 14.6, dateJoined: Date().addingTimeInterval(-86400 * 100)),
             title: "Harbour Town Golf Links", score: "86", holes: "18", greensInRegulation: "10", datePosted: "\(Date().formatted(date: .numeric, time: .shortened))")
    ]
    
    func addPost(_ post: Post) {
        self.posts.append(post)
    }
}
