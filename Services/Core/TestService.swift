//
//  TestService.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/10/25.
//


// Services/Core/TestService.swift
// Version: 1.0.0
// Created: April 10, 2025
// Description: Service to test Firebase connectivity

import Foundation
import Firebase
import FirebaseFirestore

class TestService {
    // MARK: - Singleton
    static let shared = TestService()
    
    // MARK: - Testing Methods
    
    /// Tests Firebase connectivity
    func testFirebaseConnection(completion: @escaping (Bool, String) -> Void) {
        let db = FirebaseConfig.shared.db
        
        // Try to write a test document to a test collection
        let testRef = db.collection("_test").document("connectivity")
        testRef.setData([
            "timestamp": Timestamp(date: Date()),
            "message": "Firebase connection successful"
        ]) { error in
            if let error = error {
                completion(false, "Firebase connection test failed: \(error.localizedDescription)")
            } else {
                // Now try to read the document back
                testRef.getDocument { (document, error) in
                    if let error = error {
                        completion(false, "Firebase read test failed: \(error.localizedDescription)")
                    } else if let document = document, document.exists {
                        // Delete the test document
                        testRef.delete { error in
                            if let error = error {
                                completion(false, "Firebase delete test failed: \(error.localizedDescription)")
                            } else {
                                completion(true, "All Firebase operations successful")
                            }
                        }
                    } else {
                        completion(false, "Firebase read test failed: Document not found")
                    }
                }
            }
        }
    }
}