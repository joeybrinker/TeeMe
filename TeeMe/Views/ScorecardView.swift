//
//  ScorecardView.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  ScorecardView.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import MapKit

struct ScorecardView: View {
    @StateObject private var viewModel = ScorecardModel()
    @State private var showingNewRound = false
    @State private var selectedCourse: MKMapItem?
    @State private var showingCourseSelection = false
    @State private var isEditingActiveRound = false
    @State private var editingHoleIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.green.opacity(0.1).ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if let activeScorecard = viewModel.currentScorecard {
                    activeRoundView(activeScorecard)
                } else if viewModel.scorecards.isEmpty {
                    emptyStateView
                } else {
                    roundHistoryView
                }
            }
            .navigationTitle("Scorecards")
            .toolbar {
                if viewModel.currentScorecard == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingCourseSelection = true
                        } label: {
                            Label("New Round", systemImage: "plus")
                        }
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
            .sheet(isPresented: $isEditingActiveRound) {
                holeEditView
            }
            .onAppear {
                viewModel.loadScorecards()
            }
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading scorecards...")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
    }
    
    // Empty state view when no scorecards
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Scorecards")
                .font(.headline)
            
            Text("Start tracking your golf rounds by tapping the plus button")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button {
                showingCourseSelection = true
            } label: {
                Text("Start New Round")
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top)
        }
        .padding()
    }
    
    // Course selection view
    private var courseSelectionView: some View {
        NavigationStack {
            List {
                Section {
                    // Eventually expand this to fetch favorite courses
                    Text("Select a course to start your round")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Favorite Courses") {
                    // This would be populated from your favorites
                    Text("No favorite courses yet")
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button {
                        // For demo purposes, create a sample course
                        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369))
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = "Sample Golf Club"
                        
                        selectedCourse = mapItem
                        viewModel.startNewRound(for: mapItem)
                        showingCourseSelection = false
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text("Create Sample Round")
                        }
                    }
                }
            }
            .navigationTitle("Select Course")
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
    
    // Active round view
    private func activeRoundView(_ scorecard: Scorecard) -> some View {
        VStack(spacing: 0) {
            // Header with course info
            roundHeaderView(scorecard)
            
            Divider()
            
            // Scorecard table
            ScrollView {
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("Hole")
                            .frame(width: 60, alignment: .leading)
                            .padding(.leading)
                        
                        Text("Par")
                            .frame(width: 40)
                        
                        Text("Score")
                            .frame(width: 60)
                        
                        Text("+/-")
                            .frame(width: 40)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.2))
                    .fontWeight(.semibold)
                    
                    ForEach(Array(scorecard.holes.enumerated()), id: \.element.id) { index, hole in
                        HStack {
                            Text("\(hole.holeNumber)")
                                .frame(width: 60, alignment: .leading)
                                .padding(.leading)
                            
                            Text("\(hole.par)")
                                .frame(width: 40)
                            
                            Text(hole.strokes > 0 ? "\(hole.strokes)" : "-")
                                .frame(width: 60)
                            
                            if hole.strokes > 0 {
                                let scoreToPar = hole.strokes - hole.par
                                Text(scoreToParText(scoreToPar))
                                    .frame(width: 40)
                                    .foregroundStyle(scoreToParColor(scoreToPar))
                            } else {
                                Text("-")
                                    .frame(width: 40)
                            }
                            
                            Spacer()
                            
                            Button {
                                editingHoleIndex = index
                                isEditingActiveRound = true
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(.green)
                            }
                            .padding(.trailing)
                        }
                        .padding(.vertical, 10)
                        .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                    }
                    
                    // Totals row
                    HStack {
                        Text("Total")
                            .frame(width: 60, alignment: .leading)
                            .padding(.leading)
                            .fontWeight(.bold)
                        
                        let totalPar = scorecard.holes.reduce(0) { $0 + $1.par }
                        Text("\(totalPar)")
                            .frame(width: 40)
                            .fontWeight(.bold)
                        
                        Text("\(scorecard.totalScore)")
                            .frame(width: 60)
                            .fontWeight(.bold)
                        
                        if scorecard.totalScore > 0 {
                            let totalScoreToPar = scorecard.totalScore - totalPar
                            Text(scoreToParText(totalScoreToPar))
                                .frame(width: 40)
                                .foregroundStyle(scoreToParColor(totalScoreToPar))
                                .fontWeight(.bold)
                        } else {
                            Text("-")
                                .frame(width: 40)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.2))
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // Stats summary
                statsView(scorecard)
                
                // Finish round button
                Button {
                    viewModel.finalizeScorecard(notes: "", weather: "Sunny", teeBox: "White")
                } label: {
                    Text("Finish Round")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding()
                .disabled(scorecard.totalScore == 0)
            }
        }
    }
    
    // Round header view
    private func roundHeaderView(_ scorecard: Scorecard) -> some View {
        VStack(spacing: 5) {
            Text(scorecard.courseName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Today, \(scorecard.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
    }
    
    // Stats view for current round
    private func statsView(_ scorecard: Scorecard) -> some View {
        VStack(alignment: .leading) {
            Text("Round Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // Front nine stats
                VStack {
                    Text("Front 9")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(scorecard.frontNine > 0 ? "\(scorecard.frontNine)" : "-")
                        .font(.system(size: 24, weight: .bold))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Back nine stats
                VStack {
                    Text("Back 9")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(scorecard.backNine > 0 ? "\(scorecard.backNine)" : "-")
                        .font(.system(size: 24, weight: .bold))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
            
            // Additional stats could be added here
        }
        .padding(.vertical)
    }
    
    // List of past rounds
    private var roundHistoryView: some View {
        List {
            ForEach(viewModel.scorecards) { scorecard in
                NavigationLink {
                    historicRoundDetailView(scorecard)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scorecard.courseName)
                            .font(.headline)
                        
                        HStack {
                            Text(scorecard.date.formatted(date: .abbreviated, time: .omitted))
                            
                            Spacer()
                            
                            if scorecard.totalScore > 0 {
                                let totalPar = scorecard.holes.reduce(0) { $0 + $1.par }
                                let scoreToPar = scorecard.totalScore - totalPar
                                Text("\(scorecard.totalScore) (\(scoreToParText(scoreToPar)))")
                                    .foregroundStyle(scoreToParColor(scoreToPar))
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // Historic round detail view
    private func historicRoundDetailView(_ scorecard: Scorecard) -> some View {
        ScrollView {
            VStack(spacing: 15) {
                // Header
                VStack(spacing: 5) {
                    Text(scorecard.courseName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(scorecard.date.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Label(scorecard.weather, systemImage: "sun.max")
                        
                        Divider()
                            .frame(height: 20)
                        
                        Label(scorecard.teeBox, systemImage: "figure.golf")
                    }
                    .padding(.top, 5)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding(.horizontal)
                
                // Score summary
                HStack(spacing: 20) {
                    // Total score
                    VStack {
                        Text("Total")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(scorecard.totalScore)")
                            .font(.system(size: 32, weight: .bold))
                        
                        let totalPar = scorecard.holes.reduce(0) { $0 + $1.par }
                        let scoreToPar = scorecard.totalScore - totalPar
                        Text(scoreToParText(scoreToPar))
                            .foregroundStyle(scoreToParColor(scoreToPar))
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // 9-hole splits
                    VStack(spacing: 10) {
                        HStack {
                            Text("Front")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("\(scorecard.frontNine)")
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Back")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("\(scorecard.backNine)")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)
                
                // Full scorecard
                VStack {
                    // Scorecard header
                    Text("Full Scorecard")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Scorecard table
                    VStack(spacing: 0) {
                        // Header row
                        HStack {
                            Text("Hole")
                                .frame(width: 50, alignment: .leading)
                                .padding(.leading)
                            
                            Text("Par")
                                .frame(width: 40)
                            
                            Text("Score")
                                .frame(width: 50)
                            
                            Text("+/-")
                                .frame(width: 40)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.2))
                        .fontWeight(.semibold)
                        
                        ForEach(Array(scorecard.holes.enumerated()), id: \.element.id) { index, hole in
                            HStack {
                                Text("\(hole.holeNumber)")
                                    .frame(width: 50, alignment: .leading)
                                    .padding(.leading)
                                
                                Text("\(hole.par)")
                                    .frame(width: 40)
                                
                                Text(hole.strokes > 0 ? "\(hole.strokes)" : "-")
                                    .frame(width: 50)
                                
                                if hole.strokes > 0 {
                                    let scoreToPar = hole.strokes - hole.par
                                    Text(scoreToParText(scoreToPar))
                                        .frame(width: 40)
                                        .foregroundStyle(scoreToParColor(scoreToPar))
                                } else {
                                    Text("-")
                                        .frame(width: 40)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                        }
                        
                        // Totals row
                        HStack {
                            Text("Total")
                                .frame(width: 50, alignment: .leading)
                                .padding(.leading)
                                .fontWeight(.bold)
                            
                            let totalPar = scorecard.holes.reduce(0) { $0 + $1.par }
                            Text("\(totalPar)")
                                .frame(width: 40)
                                .fontWeight(.bold)
                            
                            Text("\(scorecard.totalScore)")
                                .frame(width: 50)
                                .fontWeight(.bold)
                            
                            if scorecard.totalScore > 0 {
                                let totalScoreToPar = scorecard.totalScore - totalPar
                                Text(scoreToParText(totalScoreToPar))
                                    .frame(width: 40)
                                    .foregroundStyle(scoreToParColor(totalScoreToPar))
                                    .fontWeight(.bold)
                            } else {
                                Text("-")
                                    .frame(width: 40)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.2))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    .padding(.horizontal)
                }
                
                // Notes section if available
                if !scorecard.notes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(.headline)
                        
                        Text(scorecard.notes)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Scorecard Details")
            .padding(.bottom, 20)
        }
    }
    
    // Hole edit view
    private var holeEditView: some View {
        @State var strokes = 0
        @State var putts = 0
        @State var fairwayHit = false
        @State var greenInRegulation = false
        @State var notes = ""
        
        return NavigationStack {
            if let scorecard = viewModel.currentScorecard,
               editingHoleIndex < scorecard.holes.count {
                let hole = scorecard.holes[editingHoleIndex]
                
                Form {
                    Section(header: Text("Hole \(hole.holeNumber) • Par \(hole.par)")) {
                        Stepper("Strokes: \(hole.strokes)", value: Binding(
                            get: { hole.strokes },
                            set: { newValue in
                                var updatedHoles = scorecard.holes
                                updatedHoles[editingHoleIndex].strokes = newValue
                                viewModel.updateHoleScore(
                                    holeNumber: hole.holeNumber,
                                    strokes: newValue,
                                    putts: hole.putts,
                                    fairwayHit: hole.fairwayHit,
                                    greenInRegulation: hole.greenInRegulation,
                                    notes: hole.notes
                                )
                            }
                        ), in: 1...20)
                        
                        Stepper("Putts: \(hole.putts)", value: Binding(
                            get: { hole.putts },
                            set: { newValue in
                                var updatedHoles = scorecard.holes
                                updatedHoles[editingHoleIndex].putts = newValue
                                viewModel.updateHoleScore(
                                    holeNumber: hole.holeNumber,
                                    strokes: hole.strokes,
                                    putts: newValue,
                                    fairwayHit: hole.fairwayHit,
                                    greenInRegulation: hole.greenInRegulation,
                                    notes: hole.notes
                                )
                            }
                        ), in: 0...10)
                        
                        Toggle("Fairway Hit", isOn: Binding(
                            get: { hole.fairwayHit },
                            set: { newValue in
                                var updatedHoles = scorecard.holes
                                updatedHoles[editingHoleIndex].fairwayHit = newValue
                                viewModel.updateHoleScore(
                                    holeNumber: hole.holeNumber,
                                    strokes: hole.strokes,
                                    putts: hole.putts,
                                    fairwayHit: newValue,
                                    greenInRegulation: hole.greenInRegulation,
                                    notes: hole.notes
                                )
                            }
                        ))
                        
                        Toggle("Green in Regulation", isOn: Binding(
                            get: { hole.greenInRegulation },
                            set: { newValue in
                                var updatedHoles = scorecard.holes
                                updatedHoles[editingHoleIndex].greenInRegulation = newValue
                                viewModel.updateHoleScore(
                                    holeNumber: hole.holeNumber,
                                    strokes: hole.strokes,
                                    putts: hole.putts,
                                    fairwayHit: hole.fairwayHit,
                                    greenInRegulation: newValue,
                                    notes: hole.notes
                                )
                            }
                        ))
                        
                        TextField("Notes", text: Binding(
                            get: { hole.notes },
                            set: { newValue in
                                var updatedHoles = scorecard.holes
                                updatedHoles[editingHoleIndex].notes = newValue
                                viewModel.updateHoleScore(
                                    holeNumber: hole.holeNumber,
                                    strokes: hole.strokes,
                                    putts: hole.putts,
                                    fairwayHit: hole.fairwayHit,
                                    greenInRegulation: hole.greenInRegulation,
                                    notes: newValue
                                )
                            }
                        ), axis: .vertical)
                        .lineLimit(3...)
                    }
                    
                    // Navigation buttons for previous/next hole
                    Section {
                        HStack {
                            Button {
                                if editingHoleIndex > 0 {
                                    editingHoleIndex -= 1
                                }
                            } label: {
                                Label("Previous Hole", systemImage: "chevron.left")
                            }
                            .disabled(editingHoleIndex == 0)
                            
                            Spacer()
                            
                            Button {
                                if editingHoleIndex < scorecard.holes.count - 1 {
                                    editingHoleIndex += 1
                                }
                            } label: {
                                Label("Next Hole", systemImage: "chevron.right")
                            }
                            .disabled(editingHoleIndex == scorecard.holes.count - 1)
                        }
                    }
                }
                .navigationTitle("Enter Score")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isEditingActiveRound = false
                        }
                    }
                }
            }
        }
    }
    
    // Helper functions
    private func scoreToParText(_ scoreToPar: Int) -> String {
        if scoreToPar == 0 {
            return "E"
        } else if scoreToPar > 0 {
            return "+\(scoreToPar)"
        } else {
            return "\(scoreToPar)"
        }
    }
    
    private func scoreToParColor(_ scoreToPar: Int) -> Color {
        if scoreToPar == 0 {
            return .primary
        } else if scoreToPar < 0 {
            return .green
        } else {
            return .red
        }
    }
}

#Preview {
    ScorecardView()
}