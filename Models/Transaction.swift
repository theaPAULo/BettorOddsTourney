//
//  Transaction.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import Foundation
import FirebaseFirestore

/// Model for financial transactions in the tournament system
struct Transaction: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let userId: String
    let amount: Double
    let type: TransactionType
    let timestamp: Date
    let notes: String?
    let tournamentId: String?
    let status: TransactionStatus
    
    // MARK: - Computed Properties
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         userId: String,
         amount: Double,
         type: TransactionType,
         timestamp: Date = Date(),
         notes: String? = nil,
         tournamentId: String? = nil,
         status: TransactionStatus = .completed) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.type = type
        self.timestamp = timestamp
        self.notes = notes
        self.tournamentId = tournamentId
        self.status = status
    }
    
    // MARK: - Firestore Conversion
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.userId = data["userId"] as? String ?? ""
        self.amount = data["amount"] as? Double ?? 0.0
        
        if let typeString = data["type"] as? String,
           let type = TransactionType(rawValue: typeString) {
            self.type = type
        } else {
            self.type = .unknown
        }
        
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.notes = data["notes"] as? String
        self.tournamentId = data["tournamentId"] as? String
        
        if let statusString = data["status"] as? String,
           let status = TransactionStatus(rawValue: statusString) {
            self.status = status
        } else {
            self.status = .completed
        }
    }
    
    // MARK: - To Dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "type": type.rawValue,
            "timestamp": Timestamp(date: timestamp),
            "status": status.rawValue
        ]
        
        // Optional fields
        if let notes = notes {
            dict["notes"] = notes
        }
        
        if let tournamentId = tournamentId {
            dict["tournamentId"] = tournamentId
        }
        
        return dict
    }
}

// MARK: - Transaction Type
enum TransactionType: String, Codable, CaseIterable {
    case subscription = "Subscription"
    case tournamentPrize = "Tournament Prize"
    case coinPurchase = "Coin Purchase"
    case refund = "Refund"
    case unknown = "Unknown"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Transaction Status
enum TransactionStatus: String, Codable {
    case pending = "Pending"
    case completed = "Completed"
    case failed = "Failed"
    case refunded = "Refunded"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .completed: return .green
        case .failed: return .red
        case .refunded: return .blue
        }
    }
}

import SwiftUI
