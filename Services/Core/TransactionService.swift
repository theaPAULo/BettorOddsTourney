//
//  TransactionService.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// Explicitly import our Transaction model types
import struct BettorOdds.Transaction
import enum BettorOdds.TransactionType
import enum BettorOdds.TransactionStatus

/// Service for managing financial transactions in the tournament system
class TransactionService {
    // MARK: - Properties
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Transaction Methods
    
    /// Records a new transaction
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: The transaction amount
    ///   - type: The transaction type
    ///   - notes: Optional transaction notes
    ///   - tournamentId: Optional related tournament ID
    /// - Returns: The created transaction
    func recordTransaction(
        userId: String,
        amount: Double,
        type: BettorOdds.TransactionType,
        notes: String? = nil,
        tournamentId: String? = nil
    ) async throws -> BettorOdds.Transaction {
        // Create transaction
        let transaction = BettorOdds.Transaction(
            userId: userId,
            amount: amount,
            type: type,
            notes: notes,
            tournamentId: tournamentId
        )
        
        // Save to Firestore
        try await db.collection("transactions").document(transaction.id).setData(transaction.toDictionary())
        
        return transaction
    }
    
    /// Records a subscription payment
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: The subscription amount
    ///   - notes: Optional notes
    /// - Returns: The created transaction
    func recordSubscription(
        userId: String,
        amount: Double = 19.99,
        notes: String? = nil
    ) async throws -> BettorOdds.Transaction {
        return try await recordTransaction(
            userId: userId,
            amount: amount,
            type: .subscription,
            notes: notes ?? "Monthly subscription"
        )
    }
    
    /// Records a tournament prize payout
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: The prize amount
    ///   - tournamentId: The tournament ID
    ///   - notes: Optional notes
    /// - Returns: The created transaction
    func recordTournamentPrize(
        userId: String,
        amount: Double,
        tournamentId: String,
        notes: String? = nil
    ) async throws -> BettorOdds.Transaction {
        return try await recordTransaction(
            userId: userId,
            amount: amount,
            type: .tournamentPrize,
            notes: notes ?? "Tournament prize",
            tournamentId: tournamentId
        )
    }
    
    /// Fetches user's transaction history
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - limit: Maximum number of transactions to fetch
    /// - Returns: Array of transactions
    func fetchUserTransactions(userId: String, limit: Int = 20) async throws -> [BettorOdds.Transaction] {
        let snapshot = try await db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { BettorOdds.Transaction(document: $0) }
    }
}
