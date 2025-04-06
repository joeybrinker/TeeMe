//
//  RecordKeys.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/1/25.
//


//
//  CloudKitDatabase.swift
//  TeeMe
//
//  Created by Claude on 4/1/25.
//

import SwiftUI
import CloudKit
import MapKit

// Keys for record fields
struct RecordKeys {
    static let type = "recordType"
    static let courseName = "courseName"
    static let courseIdentifier = "courseIdentifier"
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let address = "address"
    static let city = "city"
    static let state = "state"
    static let phoneNumber = "phoneNumber"
    static let websiteURL = "websiteURL"
    static let dateAdded = "dateAdded"
}

class CloudKitDatabase: ObservableObject {
    
    // MARK: - Properties
    
    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    // MARK: - Record Types
    
    enum RecordType: String {
        case favoriteCourse = "FavoriteCourse"
        case scorecard = "Scorecard"
        case userStats = "UserStats"
        case teeTime = "TeeTime"
    }
    
    // MARK: - Save Methods
    
    func saveFavoriteCourse(_ mapItem: MKMapItem, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = CKRecord(recordType: RecordType.favoriteCourse.rawValue)
        
        record[RecordKeys.courseName] = mapItem.name as CKRecordValue?
        record[RecordKeys.courseIdentifier] = mapItem.id as CKRecordValue?
        record[RecordKeys.latitude] = mapItem.placemark.coordinate.latitude as CKRecordValue
        record[RecordKeys.longitude] = mapItem.placemark.coordinate.longitude as CKRecordValue
        
        // Add address information if available
        if let address = mapItem.placemark.postalAddress {
            record[RecordKeys.address] = address.street as CKRecordValue?
            record[RecordKeys.city] = address.city as CKRecordValue?
            record[RecordKeys.state] = address.state as CKRecordValue?
        }
        
        // Add phone and website if available
        record[RecordKeys.phoneNumber] = mapItem.phoneNumber as CKRecordValue?
        if let url = mapItem.url?.absoluteString {
            record[RecordKeys.websiteURL] = url as CKRecordValue
        }
        
        // Add timestamp
        record[RecordKeys.dateAdded] = Date() as CKRecordValue
        
        saveRecord(record, completion: completion)
    }
    
    private func saveRecord(_ record: CKRecord, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        database.save(record) { record, error in
            if let error = error {
                print("Error saving to CloudKit: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let record = record {
                print("Successfully saved to CloudKit")
                completion(.success(record))
            }
        }
    }
    
    // MARK: - Fetch Methods
    
    func fetchFavoriteCourses(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.favoriteCourse.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: RecordKeys.dateAdded, ascending: false)]
        
        database.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("Error fetching from CloudKit: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let records = records {
                print("Successfully fetched \(records.count) records from CloudKit")
                completion(.success(records))
            }
        }
    }
    
    // MARK: - Delete Methods
    
    func deleteFavoriteCourse(with courseId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // First find the record with matching courseId
        let predicate = NSPredicate(format: "%K == %@", RecordKeys.courseIdentifier, courseId)
        let query = CKQuery(recordType: RecordType.favoriteCourse.rawValue, predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first else {
                completion(.failure(NSError(domain: "TeeMeApp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Course not found"])))
                return
            }
            
            // Delete the record
            self.database.delete(withRecordID: record.recordID) { recordID, error in
                if let error = error {
                    completion(.failure(error))
                } else if let recordID = recordID {
                    completion(.success(recordID.recordName))
                }
            }
        }
    }
    
    // MARK: - Conversion Methods
    
    func mapItemFromRecord(_ record: CKRecord) -> MKMapItem? {
        guard let latitude = record[RecordKeys.latitude] as? Double,
              let longitude = record[RecordKeys.longitude] as? Double,
              let name = record[RecordKeys.courseName] as? String else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.phoneNumber = record[RecordKeys.phoneNumber] as? String
        
        if let urlString = record[RecordKeys.websiteURL] as? String {
            mapItem.url = URL(string: urlString)
        }
        
        return mapItem
    }
}