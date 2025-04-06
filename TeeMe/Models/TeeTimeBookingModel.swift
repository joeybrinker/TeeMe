//
//  TeeTimeBookingModel.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import CloudKit
import MapKit

struct TeeTime: Identifiable, Equatable {
    var id = UUID()
    var courseId: String
    var courseName: String
    var date: Date
    var numberOfPlayers: Int
    var confirmed: Bool
    var confirmationNumber: String?
    var specialRequests: String
    var playerNames: [String]
    
    static func == (lhs: TeeTime, rhs: TeeTime) -> Bool {
        return lhs.id == rhs.id
    }
}

class TeeTimeBookingModel: ObservableObject {
    @Published var upcomingTeeTimes: [TeeTime] = []
    @Published var availableTimes: [Date] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    // Load upcoming tee times
    func loadUpcomingTeeTimes() {
        isLoading = true
        
        let now = Date()
        let predicate = NSPredicate(format: "date >= %@", now as NSDate)
        let query = CKQuery(recordType: "TeeTime", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to load tee times: \(error.localizedDescription)"
                    return
                }
                
                guard let records = records else { return }
                
                // Convert records to tee times
                var loadedTeeTimes: [TeeTime] = []
                
                for record in records {
                    if let teeTime = self?.teeTimeFromRecord(record) {
                        loadedTeeTimes.append(teeTime)
                    }
                }
                
                self?.upcomingTeeTimes = loadedTeeTimes
            }
        }
    }
    
    // Convert CloudKit record to TeeTime
    private func teeTimeFromRecord(_ record: CKRecord) -> TeeTime? {
        guard let courseId = record["courseId"] as? String,
              let courseName = record["courseName"] as? String,
              let date = record["date"] as? Date,
              let players = record["numberOfPlayers"] as? Int else {
            return nil
        }
        
        // Get player names from JSON string
        var playerNames: [String] = []
        if let namesString = record["playerNames"] as? String,
           let namesData = namesString.data(using: .utf8) {
            playerNames = (try? JSONDecoder().decode([String].self, from: namesData)) ?? []
        }
        
        return TeeTime(
            id: UUID(),
            courseId: courseId,
            courseName: courseName,
            date: date,
            numberOfPlayers: players,
            confirmed: record["confirmed"] as? Bool ?? false,
            confirmationNumber: record["confirmationNumber"] as? String,
            specialRequests: record["specialRequests"] as? String ?? "",
            playerNames: playerNames
        )
    }
    
    // Fetch available tee times for a course on a specific date
    func fetchAvailableTimes(for course: MKMapItem, on date: Date) {
        // In a real app, this would connect to a course API
        // For now, generate some mock times
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Create times between 7am and 5pm every 10 minutes
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 7
            components.minute = 0
            
            guard let startTime = calendar.date(from: components) else { return }
            
            var availableTimes: [Date] = []
            var currentTime = startTime
            
            while calendar.component(.hour, from: currentTime) < 17 {
                availableTimes.append(currentTime)
                currentTime = calendar.date(byAdding: .minute, value: 10, to: currentTime)!
            }
            
            self?.availableTimes = availableTimes
        }
    }
    
    // Book a tee time
    func bookTeeTime(course: MKMapItem, date: Date, players: Int, names: [String], requests: String) {
        isLoading = true
        
        let teeTime = TeeTime(
            courseId: course.id,
            courseName: course.name ?? "Unknown Course",
            date: date,
            numberOfPlayers: players,
            confirmed: true,
            confirmationNumber: String(format: "%06d", Int.random(in: 100000...999999)),
            specialRequests: requests,
            playerNames: names
        )
        
        // Create CloudKit record
        let record = CKRecord(recordType: "TeeTime")
        record["courseId"] = teeTime.courseId
        record["courseName"] = teeTime.courseName
        record["date"] = teeTime.date
        record["numberOfPlayers"] = teeTime.numberOfPlayers
        record["confirmed"] = teeTime.confirmed
        record["confirmationNumber"] = teeTime.confirmationNumber
        record["specialRequests"] = teeTime.specialRequests
        
        // Encode player names to JSON
        if let namesData = try? JSONEncoder().encode(teeTime.playerNames),
           let namesString = String(data: namesData, encoding: .utf8) {
            record["playerNames"] = namesString
        }
        
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to book tee time: \(error.localizedDescription)"
                } else {
                    // Add to local array
                    self?.upcomingTeeTimes.append(teeTime)
                    // Sort by date
                    self?.upcomingTeeTimes.sort { $0.date < $1.date }
                }
            }
        }
    }
    
    // Cancel a tee time
    func cancelTeeTime(_ teeTime: TeeTime) {
        isLoading = true
        
        // Find the record ID first
        let predicate = NSPredicate(format: "confirmationNumber == %@", teeTime.confirmationNumber ?? "")
        let query = CKQuery(recordType: "TeeTime", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to cancel tee time: \(error.localizedDescription)"
                }
                return
            }
            
            guard let record = records?.first else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Could not find tee time to cancel"
                }
                return
            }
            
            // Delete the record
            self?.database.delete(withRecordID: record.recordID) { _, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Failed to cancel tee time: \(error.localizedDescription)"
                    } else {
                        // Remove from local array
                        self?.upcomingTeeTimes.removeAll { tee in
                            tee.id == teeTime.id
                        }
                    }
                }
            }
        }
    }
}
