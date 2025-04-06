//
//  GolferSocialView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  GolferSocialView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI

struct GolferSocialView: View {
    @StateObject private var viewModel = GolferSocialModel()
    @State private var selectedTab = 0
    @State private var showingEventCreation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control for tabs
                Picker("View", selection: $selectedTab) {
                    Text("Events").tag(0)
                    Text("Golfers").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                ZStack {
                    // Background
                    Color.green.opacity(0.1).ignoresSafeArea()
                    
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        TabView(selection: $selectedTab) {
                            // Events tab
                            eventsTab
                                .tag(0)
                            
                            // Golfers tab
                            golfersTab
                                .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
            .navigationTitle("Golf Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEventCreation = true
                    } label: {
                        Label("Create Event", systemImage: "plus")
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showingEventCreation) {
                eventCreationView
            }
            .onAppear {
                viewModel.loadUpcomingEvents()
                viewModel.loadNearbyGolfers()
            }
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
    }
    
    // Events tab content
    private var eventsTab: some View {
        ScrollView {
            LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                // My events section
                Section {
                    if viewModel.myEvents.isEmpty {
                        Text("You haven't joined any events yet")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.myEvents) { event in
                            eventCard(event, isJoined: true)
                        }
                    }
                } header: {
                    Text("My Events")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                }
                
                // Upcoming events section
                Section {
                    if viewModel.upcomingEvents.isEmpty {
                        Text("No upcoming events")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.upcomingEvents) { event in
                            let isJoined = viewModel.myEvents.contains { $0.id == event.id }
                            eventCard(event, isJoined: isJoined)
                        }
                    }
                } header: {
                    Text("Upcoming Events")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Event card view
    private func eventCard(_ event: GolfEvent, isJoined: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Event title and type
            HStack {
                Text(event.title)
                    .font(.headline)
                
                Spacer()
                
                Text(event.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(eventTypeColor(event.type).opacity(0.2))
                    .foregroundStyle(eventTypeColor(event.type))
                    .clipShape(Capsule())
            }
            
            // Event details
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text(event.courseName)
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "calendar")
                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "person.2")
                Text("\(event.attendees.count)/\(event.maxAttendees) participants")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            
            // Skill level
            HStack {
                Image(systemName: "figure.golf")
                Text(event.skill.rawValue)
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            
            // Description
            Text(event.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 5)
            
            // Action button
            Button {
                if isJoined {
                    viewModel.leaveEvent(event)
                } else {
                    viewModel.joinEvent(event)
                }
            } label: {
                Text(isJoined ? "Leave Event" : "Join Event")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isJoined ? Color.red : Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(event.attendees.count >= event.maxAttendees && !isJoined)
            .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // Golfers tab content
    private var golfersTab: some View {
        ScrollView {
            LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                // Followed golfers section
                Section {
                    if viewModel.followedGolfers.isEmpty {
                        Text("You're not following any golfers yet")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.followedGolfers) { golfer in
                            golferCard(golfer)
                        }
                    }
                } header: {
                    Text("Golfers You Follow")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                }
                
                // Nearby golfers section
                Section {
                    if viewModel.golfers.isEmpty {
                        Text("No golfers found nearby")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.golfers) { golfer in
                            golferCard(golfer)
                        }
                    }
                } header: {
                    Text("Golfers Nearby")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Golfer card view
    private func golferCard(_ golfer: GolferProfile) -> some View {
        HStack(spacing: 15) {
            // Profile image or placeholder
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 60, height: 60)
                
                Text(String(golfer.displayName.prefix(1).uppercased()))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            // Golfer details
            VStack(alignment: .leading, spacing: 5) {
                Text(golfer.displayName)
                    .font(.headline)
                
                if let handicap = golfer.handicap {
                    Text("Handicap: \(String(format: "%.1f", handicap))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let homeCourse = golfer.homeCourseName {
                    Text("Home Course: \(homeCourse)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Follow button
            Button {
                viewModel.toggleFollow(golfer: golfer)
            } label: {
                Text(golfer.isFollowing ? "Unfollow" : "Follow")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(golfer.isFollowing ? Color.gray.opacity(0.2) : Color.green)
                    .foregroundStyle(golfer.isFollowing ? .primary : Color.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // Event creation view
    private var eventCreationView: some View {
        @State var eventTitle = ""
        @State var eventDescription = ""
        @State var eventCourse = ""
        @State var eventDate = Date().addingTimeInterval(86400) // Tomorrow
        @State var eventMaxAttendees = 4
        @State var eventType = GolfEvent.EventType.casual
        @State var eventSkill = GolfEvent.SkillLevel.allLevels
        
        return NavigationStack {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $eventTitle)
                    
                    TextField("Description", text: $eventDescription, axis: .vertical)
                        .lineLimit(3...)
                    
                    TextField("Course Name", text: $eventCourse)
                    
                    DatePicker("Date & Time", selection: $eventDate, in: Date()...)
                }
                
                Section(header: Text("Event Type")) {
                    Picker("Type", selection: $eventType) {
                        ForEach(GolfEvent.EventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Skill Level", selection: $eventSkill) {
                        ForEach(GolfEvent.SkillLevel.allCases, id: \.self) { skill in
                            Text(skill.rawValue).tag(skill)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Participants")) {
                    Stepper("Max Participants: \(eventMaxAttendees)", value: $eventMaxAttendees, in: 1...16)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEventCreation = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createEvent(
                            title: eventTitle,
                            description: eventDescription,
                            courseName: eventCourse,
                            date: eventDate,
                            maxAttendees: eventMaxAttendees,
                            type: eventType,
                            skill: eventSkill
                        )
                        showingEventCreation = false
                    }
                    .disabled(eventTitle.isEmpty || eventCourse.isEmpty)
                }
            }
        }
    }
    
    // Helper function for event type colors
    private func eventTypeColor(_ type: GolfEvent.EventType) -> Color {
        switch type {
        case .casual:
            return .green
        case .tournament:
            return .blue
        case .lesson:
            return .orange
        case .networking:
            return .purple
        }
    }
}

#Preview {
    GolferSocialView()
}
