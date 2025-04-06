//
//  TeeTimeBookingView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  TeeTimeBookingView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import MapKit

struct TeeTimeBookingView: View {
    @StateObject private var viewModel = TeeTimeBookingModel()
    @State private var selectedDate = Date()
    @State private var showingCourseSelection = false
    @State private var selectedCourse: MKMapItem?
    @State private var showingTimeSelection = false
    @State private var selectedTime: Date?
    @State private var showingPlayerDetails = false
    @State private var numberOfPlayers = 1
    @State private var playerNames: [String] = ["", "", "", ""]
    @State private var specialRequests = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.green.opacity(0.1).ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.upcomingTeeTimes.isEmpty {
                    emptyStateView
                } else {
                    upcomingTeeTimesView
                }
            }
            .navigationTitle("Tee Times")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCourseSelection = true
                    } label: {
                        Label("Book", systemImage: "plus")
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
            .sheet(isPresented: $showingCourseSelection) {
                courseSelectionView
            }
            .sheet(isPresented: $showingTimeSelection) {
                timeSelectionView
            }
            .sheet(isPresented: $showingPlayerDetails) {
                playerDetailsView
            }
            .onAppear {
                viewModel.loadUpcomingTeeTimes()
            }
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading tee times...")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Upcoming Tee Times")
                .font(.headline)
            
            Text("Book a tee time at your favorite course")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button {
                showingCourseSelection = true
            } label: {
                Text("Book Tee Time")
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top)
        }
        .padding()
    }
    
    // Upcoming tee times view
    private var upcomingTeeTimesView: some View {
        List {
            Section(header: Text("Upcoming Tee Times")) {
                ForEach(viewModel.upcomingTeeTimes) { teeTime in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(teeTime.courseName)
                                    .font(.headline)
                                
                                Text(teeTime.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(teeTime.numberOfPlayers) players")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if let confirmationNumber = teeTime.confirmationNumber {
                                    Text("Conf #: \(confirmationNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // Player names
                        if !teeTime.playerNames.isEmpty {
                            Text("Players: \(teeTime.playerNames.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.cancelTeeTime(teeTime)
                        } label: {
                            Label("Cancel", systemImage: "trash")
                        }
                    }
                }
            }
            
            Section {
                Button {
                    showingCourseSelection = true
                } label: {
                    Label("Book New Tee Time", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }
        }
    }
    
    // Course selection view
    private var courseSelectionView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date selector
                DatePicker("Select Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color.white)
                
                Divider()
                
                List {
                    Section("Select Course") {
                        // This would be populated with real courses from a search or favorites
                        Button {
                            // For demo purposes, create a sample course
                            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369))
                            let mapItem = MKMapItem(placemark: placemark)
                            mapItem.name = "Pine Valley Golf Club"
                            
                            selectedCourse = mapItem
                            viewModel.fetchAvailableTimes(for: mapItem, on: selectedDate)
                            showingCourseSelection = false
                            showingTimeSelection = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Pine Valley Golf Club")
                                        .font(.headline)
                                    Text("Clementon, NJ")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button {
                            // Another sample course
                            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 41.354528, longitude: -70.068369))
                            let mapItem = MKMapItem(placemark: placemark)
                            mapItem.name = "Augusta National Golf Club"
                            
                            selectedCourse = mapItem
                            viewModel.fetchAvailableTimes(for: mapItem, on: selectedDate)
                            showingCourseSelection = false
                            showingTimeSelection = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Augusta National Golf Club")
                                        .font(.headline)
                                    Text("Augusta, GA")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Book Tee Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCourseSelection = false
                    }
                }
            }
        }
    }
    
    // Time selection view
    private var timeSelectionView: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading available times...")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                } else if viewModel.availableTimes.isEmpty {
                    Text("No tee times available for this date.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(viewModel.availableTimes, id: \.self) { time in
                                Button {
                                    selectedTime = time
                                    showingTimeSelection = false
                                    showingPlayerDetails = true
                                } label: {
                                    Text(time.formatted(date: .omitted, time: .shortened))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green.opacity(0.1))
                                        .foregroundStyle(.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(selectedCourse?.name ?? "Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        showingTimeSelection = false
                        showingCourseSelection = true
                    }
                }
            }
        }
    }
    
    // Player details view
    private var playerDetailsView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tee Time Details")) {
                    HStack {
                        Text("Course")
                        Spacer()
                        Text(selectedCourse?.name ?? "")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(selectedTime?.formatted(date: .omitted, time: .shortened) ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Number of Players")) {
                    Picker("Number of Players", selection: $numberOfPlayers) {
                        ForEach(1...4, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Player Names")) {
                    ForEach(0..<numberOfPlayers, id: \.self) { index in
                        TextField("Player \(index + 1) Name", text: $playerNames[index])
                    }
                }
                
                Section(header: Text("Special Requests (Optional)")) {
                    TextField("Special requests or notes", text: $specialRequests, axis: .vertical)
                        .lineLimit(3...)
                }
                
                Section {
                    Button {
                        bookTeeTime()
                    } label: {
                        Text("Book Tee Time")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.green)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Complete Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        showingPlayerDetails = false
                        showingTimeSelection = true
                    }
                }
            }
        }
    }
    
    // Function to book tee time
    private func bookTeeTime() {
        guard let course = selectedCourse, let time = selectedTime else { return }
        
        // Filter player names to only include non-empty names
        let filteredNames = playerNames.prefix(numberOfPlayers).filter { !$0.isEmpty }
        
        viewModel.bookTeeTime(
            course: course,
            date: time,
            players: numberOfPlayers,
            names: Array(filteredNames),
            requests: specialRequests
        )
        
        // Reset form
        numberOfPlayers = 1
        playerNames = ["", "", "", ""]
        specialRequests = ""
        
        // Close sheet
        showingPlayerDetails = false
    }
}

#Preview {
    TeeTimeBookingView()
}