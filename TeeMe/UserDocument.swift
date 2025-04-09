//
//  UserDocument.swift
//  TeeMe
//
//  Created by Joseph Brinker on 4/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

func createUserDocument(for user: User) {
    let db = Firestore.firestore()
    db.collection("users").document(user.uid).setData([
        "email": user.email ?? "",
        "uid": user.uid,
        "joinDate": FieldValue.serverTimestamp()
    ])
    { error in
        if let error = error{
            print("Error creating user doc: \(error)")
        }
    }
}
