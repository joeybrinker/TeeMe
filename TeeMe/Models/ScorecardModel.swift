//
//  HoleScore.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  ScorecardModel.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import CloudKit
import MapKit

struct HoleScore: Identifiable, Codable {
    var id = UUID()
    var holeNumber: Int
    var par: Int
    var strokes: Int
    var putts: Int
    var fairwayHit: Bool
    var greenInRegulation: Bool
    var notes: String
    
    var scoreToPar: Int {
        return strokes - par
    }
}

struct Scorecard: Identifiable, Codable {
    var id = UUID()
    var courseName: String
    var courseId: String?
    var date: Date
    var totalScore: Int
    var frontNine: Int
    var backNine: Int
    var holes: [HoleScore]
    var notes: String
    var weather: String
    var teeBox: String
    
    var scoreToPar: Int {
        let totalPar = holes.reduce(0) { $0 + $1.par }
        return totalScore - totalPar
    }
}

class ScorecardModel: ObservableObject {
    @Published var scorecards: [Scorecard] = []
    @Published var currentScorecard: Scorecard?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let cloudDB = CloudKitDatabase()
    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    // Load all scorecards for the user
    func loadScorecards() {
        isLoading = true
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Scorecard", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to load scorecards: \(error.localizedDescription)"
                    return
                }
                
                guard let records = records else { return }
                
                // Convert records to scorecards
                var loadedScorecards: [Scorecard] = []
                
                for record in records {
                    if let scorecard = self?.scorecardFromRecord(record) {
                        loadedScorecards.append(scorecard)
                    }
                }
                
                self?.scorecards = loadedScorecards
            }
        }
    }
    
    // Start a new scorecard for a course
    func startNewRound(for course: MKMapItem) {
        let emptyHoles = (1...18).map { holeNumber in
            return HoleScore(
                holeNumber: holeNumber,
                par: 4, // Default par
                strokes: 0,
                putts: 0,
                fairwayHit: false,
                greenInRegulation: false,
                notes: ""
            )
        }
        
        let newScorecard = Scorecard(
            courseName: course.name ?? "Unknown Course",
            courseId: course.id,
            date: Date(),
            totalScore: 0,
            frontNine: 0,
            backNine: 0,
            holes: emptyHoles,
            notes: "",
            weather: "Sunny", // Default
            teeBox: "White" // Default
        )
        
        self.currentScorecard = newScorecard
    }
    
    // Update hole score
    func updateHoleScore(holeNumber: Int, strokes: Int, putts: Int, fairwayHit: Bool, greenInRegulation: Bool, notes: String) {
        guard var scorecard = currentScorecard else { return }
        
        if let index = scorecard.holes.firstIndex(where: { $0.holeNumber == holeNumber }) {
            scorecard.holes[index].strokes = strokes
            scorecard.holes[index].putts = putts
            scorecard.holes[index].fairwayHit = fairwayHit
            scorecard.holes[index].greenInRegulation = greenInRegulation
            scorecard.holes[index].notes = notes
            
            // Recalculate totals
            updateScorecardTotals(scorecard: &scorecard)
            
            currentScorecard = scorecard
        }
    }
    
    // Finalize and save the current scorecard
    func finalizeScorecard(notes: String, weather: String, teeBox: String) {
        guard var scorecard = currentScorecard else { return }
        
        scorecard.notes = notes
        scorecard.weather = weather
        scorecard.teeBox = teeBox
        
        // Recalculate totals one last time
        updateScorecardTotals(scorecard: &scorecard)
        
        // Save to CloudKit
        saveScorecard(scorecard)
    }
    
    // Save a scorecard to CloudKit
    func saveScorecard(_ scorecard: Scorecard) {
        isLoading = true
        
        let record = CKRecord(recordType: "Scorecard")
        record["courseName"] = scorecard.courseName
        record["courseId"] = scorecard.courseId
        record["date"] = scorecard.date
        record["totalScore"] = scorecard.totalScore
        record["frontNine"] = scorecard.frontNine
        record["backNine"] = scorecard.backNine
        record["notes"] = scorecard.notes
        record["weather"] = scorecard.weather
        record["teeBox"] = scorecard.teeBox
        
        // Encode holes array to JSON
        if let holesData = try? JSONEncoder().encode(scorecard.holes),
           let holesString = String(data: holesData, encoding: .utf8) {
            record["holesData"] = holesString
        }
        
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to save scorecard: \(error.localizedDescription)"
                } else {
                    // Add to local array
                    self?.scorecards.insert(scorecard, at: 0)
                    self?.currentScorecard = nil
                }
            }
        }
    }
    
    // Convert CloudKit record to Scorecard
    private func scorecardFromRecord(_ record: CKRecord) -> Scorecard? {
        guard let holesString = record["holesData"] as? String,
              let holesData = holesString.data(using: .utf8),
              let holes = try? JSONDecoder().decode([HoleScore].self, from: holesData) else {
            return nil
        }
        
        return Scorecard(
            id: UUID(),
            courseName: record["courseName"] as? String ?? "Unknown Course",
            courseId: record["courseId"] as? String,
            date: record["date"] as? Date ?? Date(),
            totalScore: record["totalScore"] as? Int ?? 0,
            frontNine: record["frontNine"] as? Int ?? 0,
            backNine: record["backNine"] as? Int ?? 0,
            holes: holes,
            notes: record["notes"] as? String ?? "",
            weather: record["weather"] as? String ?? "Unknown",
            teeBox: record["teeBox"] as? String ?? "Unknown"
        )
    }
    
    // Helper to update scorecard totals
    private func updateScorecardTotals(scorecard: inout Scorecard) {
        // Calculate front nine
        scorecard.frontNine = scorecard.holes.prefix(9).reduce(0) { $0 + $1.strokes }
        
        // Calculate back nine
        scorecard.backNine = scorecard.holes.suffix(9).reduce(0) { $0 + $1.strokes }
        
        // Calculate total
        scorecard.totalScore = scorecard.frontNine + scorecard.backNine
    }
}