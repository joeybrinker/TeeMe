//
//  GolferProfile.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  GolferSocialModel.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import CloudKit
import FirebaseAuth

struct GolferProfile: Identifiable, Equatable {
    var id: String
    var displayName: String
    var handicap: Double?
    var homeCourseName: String?
    var joinDate: Date
    var bio: String
    var profileImageURL: URL?
    var isFollowing: Bool
    
    static func == (lhs: GolferProfile, rhs: GolferProfile) -> Bool {
        return lhs.id == rhs.id
    }
}

struct GolfEvent: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var courseName: String
    var date: Date
    var organizer: String
    var organizerId: String
    var attendees: [String] // IDs of attendees
    var maxAttendees: Int
    var type: EventType
    var skill: SkillLevel
    
    enum EventType: String, CaseIterable {
        case casual = "Casual Round"
        case tournament = "Tournament"
        case lesson = "Group Lesson"
        case networking = "Networking"
    }
    
    enum SkillLevel: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case allLevels = "All Levels"
    }
}

class GolferSocialModel: ObservableObject {
    @Published var golfers: [GolferProfile] = []
    @Published var followedGolfers: [GolferProfile] = []
    @Published var upcomingEvents: [GolfEvent] = []
    @Published var myEvents: [GolfEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    // Load nearby golfers
    func loadNearbyGolfers() {
        isLoading = true
        
        // In a real app, this would search for users near the user's location
        // For demo purposes, we'll generate sample golfers
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Generate sample golfers
            let sampleGolfers = [
                GolferProfile(
                    id: "user1",
                    displayName: "John Smith",
                    handicap: 12.5,
                    homeCourseName: "Pine Valley Golf Club",
                    joinDate: Date().addingTimeInterval(-86400 * 180), // 180 days ago
                    bio: "Avid golfer for 10 years. Love playing on weekends and meeting new golf buddies.",
                    profileImageURL: nil,
                    isFollowing: false
                ),
                GolferProfile(
                    id: "user2",
                    displayName: "Sarah Johnson",
                    handicap: 8.2,
                    homeCourseName: "Augusta National",
                    joinDate: Date().addingTimeInterval(-86400 * 90), // 90 days ago
                    bio: "Former college player. Looking for competitive rounds.",
                    profileImageURL: nil,
                    isFollowing: true
                ),
                GolferProfile(
                    id: "user3",
                    displayName: "Mike Wilson",
                    handicap: 18.7,
                    homeCourseName: "Local Municipal Course",
                    joinDate: Date().addingTimeInterval(-86400 * 45), // 45 days ago
                    bio: "Beginner looking to improve. Open to tips and casual rounds.",
                    profileImageURL: nil,
                    isFollowing: false
                ),
                GolferProfile(
                    id: "user4",
                    displayName: "Emily Chen",
                    handicap: 14.3,
                    homeCourseName: "Pebble Beach",
                    joinDate: Date().addingTimeInterval(-86400 * 120), // 120 days ago
                    bio: "Weekend golfer who enjoys the social aspect of the game.",
                    profileImageURL: nil,
                    isFollowing: false
                ),
                GolferProfile(
                    id: "user5",
                    displayName: "David Rodriguez",
                    handicap: 6.8,
                    homeCourseName: "TPC Sawgrass",
                    joinDate: Date().addingTimeInterval(-86400 * 200), // 200 days ago
                    bio: "Competitive player looking for regular golf partners.",
                    profileImageURL: nil,
                    isFollowing: true
                )
            ]
            
            self?.golfers = sampleGolfers
            self?.followedGolfers = sampleGolfers.filter { $0.isFollowing }
        }
    }
    
    // Follow or unfollow a golfer
    func toggleFollow(golfer: GolferProfile) {
        guard let index = golfers.firstIndex(of: golfer) else { return }
        
        // Toggle following status
        golfers[index].isFollowing.toggle()
        
        if golfers[index].isFollowing {
            // Add to followed golfers
            followedGolfers.append(golfers[index])
        } else {
            // Remove from followed golfers
            followedGolfers.removeAll { $0.id == golfer.id }
        }
        
        // In a real app, this would update a CloudKit record
    }
    
    // Load upcoming golf events
    func loadUpcomingEvents() {
        isLoading = true
        
        // In a real app, this would fetch events from CloudKit
        // For demo purposes, we'll generate sample events
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Generate sample events
            let sampleEvents = [
                GolfEvent(
                    title: "Weekend Scramble",
                    description: "Casual 4-person scramble format. All skill levels welcome!",
                    courseName: "Pine Valley Golf Club",
                    date: Date().addingTimeInterval(86400 * 3), // 3 days from now
                    organizer: "John Smith",
                    organizerId: "user1",
                    attendees: ["user1", "user3"],
                    maxAttendees: 4,
                    type: .casual,
                    skill: .allLevels
                ),
                GolfEvent(
                    title: "Beginner Lesson Group",
                    description: "Group lesson for beginners. Focus on putting and short game.",
                    courseName: "Local Municipal Course",
                    date: Date().addingTimeInterval(86400 * 5), // 5 days from now
                    organizer: "Mike Wilson",
                    organizerId: "user3",
                    attendees: ["user3"],
                    maxAttendees: 6,
                    type: .lesson,
                    skill: .beginner
                ),
                GolfEvent(
                    title: "Monthly Tournament",
                    description: "Competitive stroke play tournament. Prizes available!",
                    courseName: "Augusta National",
                    date: Date().addingTimeInterval(86400 * 10), // 10 days from now
                    organizer: "Sarah Johnson",
                    organizerId: "user2",
                    attendees: ["user2", "user5"],
                    maxAttendees: 12,
                    type: .tournament,
                    skill: .advanced
                ),
                GolfEvent(
                    title: "Business Networking Round",
                    description: "Casual golf with local professionals. Great networking opportunity.",
                    courseName: "TPC Sawgrass",
                    date: Date().addingTimeInterval(86400 * 7), // 7 days from now
                    organizer: "David Rodriguez",
                    organizerId: "user5",
                    attendees: ["user5", "user4", "user2"],
                    maxAttendees: 4,
                    type: .networking,
                    skill: .intermediate
                )
            ]
            
            self?.upcomingEvents = sampleEvents
            
            // Filter events the current user is organizing or attending
            if let currentUserId = Auth.auth().currentUser?.uid {
                self?.myEvents = sampleEvents.filter { event in
                    event.organizerId == currentUserId || event.attendees.contains(currentUserId)
                }
            }
        }
    }
    
    // Create a new golf event
    func createEvent(title: String, description: String, courseName: String, date: Date, maxAttendees: Int, type: GolfEvent.EventType, skill: GolfEvent.SkillLevel) {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to create events"
            return
        }
        
        let newEvent = GolfEvent(
            title: title,
            description: description,
            courseName: courseName,
            date: date,
            organizer: currentUser.displayName ?? "Anonymous",
            organizerId: currentUser.uid,
            attendees: [currentUser.uid],
            maxAttendees: maxAttendees,
            type: type,
            skill: skill
        )
        
        // In a real app, this would save to CloudKit
        // For demo purposes, we'll just update our local arrays
        upcomingEvents.append(newEvent)
        myEvents.append(newEvent)
    }
    
    // Join an event
    func joinEvent(_ event: GolfEvent) {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to join events"
            return
        }
        
        // Check if event is full
        if event.attendees.count >= event.maxAttendees {
            errorMessage = "This event is full"
            return
        }
        
        // Check if already joined
        if event.attendees.contains(currentUser.uid) {
            errorMessage = "You've already joined this event"
            return
        }
        
        // Find the event in our arrays
        if let index = upcomingEvents.firstIndex(where: { $0.id == event.id }) {
            // Add user to attendees
            upcomingEvents[index].attendees.append(currentUser.uid)
            
            // Add to my events if not already there
            if !myEvents.contains(where: { $0.id == event.id }) {
                myEvents.append(upcomingEvents[index])
            }
        }
        
        // In a real app, this would update CloudKit
    }
    
    // Leave an event
    func leaveEvent(_ event: GolfEvent) {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to leave events"
            return
        }
        
        // Check if organizer
        if event.organizerId == currentUser.uid {
            errorMessage = "As the organizer, you cannot leave this event"
            return
        }
        
        // Find the event in our arrays
        if let index = upcomingEvents.firstIndex(where: { $0.id == event.id }) {
            // Remove user from attendees
            upcomingEvents[index].attendees.removeAll { $0 == currentUser.uid }
        }
        
        // Remove from my events
        myEvents.removeAll { $0.id == event.id }
        
        // In a real app, this would update CloudKit
    }
}
