// Updated version of Models/BetMatchingService.swift
// Version: 3.0.0 - Converted to TournamentBetService
// Updated: April 2025

import Foundation
import FirebaseFirestore

actor TournamentBetService {
    // MARK: - Properties
    static let shared = TournamentBetService()
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Public Methods
    
    /// Places a bet in the tournament system
    /// - Parameter bet: The new bet to place
    /// - Returns: Updated bet with status
    func placeBet(_ bet: Bet) async throws -> Bet {
        print("🎲 Processing tournament bet: \(bet.id)")
        
        // 1. Validate tournament exists and is active
        guard let tournament = try await fetchTournament(id: bet.tournamentId) else {
            throw BetError.invalidTournament
        }
        
        if tournament.status != .active {
            throw BetError.tournamentInactive
        }
        
        // 2. Save bet to Firestore
        try await db.collection("bets").document(bet.id).setData(bet.toDictionary())
        
        // 3. Update user's leaderboard entry
        try await updateLeaderboard(
            userId: bet.userId,
            tournamentId: bet.tournamentId,
            betAmount: bet.amount
        )
        
        var updatedBet = bet
        updatedBet.status = .pending
        
        return updatedBet
    }
    
    /// Cancels a bet if allowed
    /// - Parameter bet: The bet to cancel
    func cancelBet(_ bet: Bet) async throws {
        guard bet.canBeCancelled else {
            throw BetError.cannotCancel
        }
        
        // Update status to cancelled
        try await db.collection("bets").document(bet.id).updateData([
            "status": BetStatus.cancelled.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
        
        // Refund tournament coins
        try await refundCoins(
            userId: bet.userId,
            tournamentId: bet.tournamentId,
            amount: bet.amount
        )
    }
    
    // MARK: - Private Methods
    
    /// Fetches a tournament by ID
    private func fetchTournament(id: String) async throws -> Tournament? {
        let document = try await db.collection("tournaments").document(id).getDocument()
        return Tournament(document: document)
    }
    
    /// Updates user's leaderboard entry
    private func updateLeaderboard(userId: String, tournamentId: String, betAmount: Int) async throws {
        // Get leaderboard entry
        let querySnapshot = try await db.collection("leaderboard")
            .whereField("userId", isEqualTo: userId)
            .whereField("tournamentId", isEqualTo: tournamentId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            throw BetError.leaderboardEntryNotFound
        }
        
        // Fixed: Using document.documentID instead of document.id
        try await db.collection("leaderboard").document(document.documentID).updateData([
            "coinsRemaining": FieldValue.increment(Int64(-betAmount)),
            "coinsBet": FieldValue.increment(Int64(betAmount)),
            "betsPlaced": FieldValue.increment(Int64(1))
        ])
    }
    
    /// Refunds coins to user's tournament balance
    private func refundCoins(userId: String, tournamentId: String, amount: Int) async throws {
        // Get leaderboard entry
        let querySnapshot = try await db.collection("leaderboard")
            .whereField("userId", isEqualTo: userId)
            .whereField("tournamentId", isEqualTo: tournamentId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            throw BetError.leaderboardEntryNotFound
        }
        
        // Fixed: Using document.documentID instead of document.id
        try await db.collection("leaderboard").document(document.documentID).updateData([
            "coinsRemaining": FieldValue.increment(Int64(amount)),
            "coinsBet": FieldValue.increment(Int64(-amount))
        ])
    }
    
    // MARK: - Error Handling
    enum BetError: Error {
        case invalidTournament
        case tournamentInactive
        case insufficientCoins
        case gameIsLocked
        case invalidSpread
        case cannotCancel
        case leaderboardEntryNotFound
        
        var description: String {
            switch self {
            case .invalidTournament:
                return "Tournament not found or invalid"
            case .tournamentInactive:
                return "Tournament is not active"
            case .insufficientCoins:
                return "Insufficient coins to place bet"
            case .gameIsLocked:
                return "Game is locked for betting"
            case .invalidSpread:
                return "Spread has changed significantly"
            case .cannotCancel:
                return "Bet cannot be cancelled"
            case .leaderboardEntryNotFound:
                return "Leaderboard entry not found"
            }
        }
    }
}
