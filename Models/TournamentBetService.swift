//
//  TournamentBetService.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  TournamentBetService.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//  Version: 1.0.0 - Initial implementation for tournament betting
//

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
        
        // 2. Check if game is locked
        let game = try await fetchGame(id: bet.gameId)
        if game.isLocked || game.shouldBeLocked {
            throw BetError.gameIsLocked
        }
        
        // 3. Verify user has enough coins
        let leaderboardEntry = try await fetchLeaderboardEntry(userId: bet.userId, tournamentId: bet.tournamentId)
        if leaderboardEntry.coinsRemaining < bet.amount {
            throw BetError.insufficientCoins
        }
        
        // 4. Save bet to Firestore
        try await db.collection("bets").document(bet.id).setData(bet.toDictionary())
        
        // 5. Update user's leaderboard entry
        try await updateLeaderboard(
            entryId: leaderboardEntry.id,
            betAmount: bet.amount
        )
        
        // 6. Update user's tournament stats
        try await updateUserTournamentStats(userId: bet.userId)
        
        var updatedBet = bet
        updatedBet.status = .pending
        
        return updatedBet
    }
    
    /// Cancels a bet if allowed
    /// - Parameter betId: The ID of the bet to cancel
    func cancelBet(_ betId: String) async throws {
        // Fetch the bet
        let betDoc = try await db.collection("bets").document(betId).getDocument()
        guard let data = betDoc.data(),
              let statusString = data["status"] as? String,
              let status = BetStatus(rawValue: statusString),
              status == .pending,  // Only pending bets can be cancelled
              let userId = data["userId"] as? String,
              let tournamentId = data["tournamentId"] as? String,
              let amount = data["amount"] as? Int else {
            throw BetError.cannotCancel
        }
        
        // Update status to cancelled
        try await db.collection("bets").document(betId).updateData([
            "status": BetStatus.cancelled.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
        
        // Refund tournament coins
        try await refundCoins(
            userId: userId,
            tournamentId: tournamentId,
            amount: amount
        )
    }
    
    // MARK: - Private Methods
    
    /// Fetches a tournament by ID
    private func fetchTournament(id: String) async throws -> Tournament? {
        let document = try await db.collection("tournaments").document(id).getDocument()
        return Tournament(document: document)
    }
    
    /// Fetches a game by ID
    private func fetchGame(id: String) async throws -> Game {
        let document = try await db.collection("games").document(id).getDocument()
        guard let game = Game(from: document) else {
            throw BetError.gameNotFound
        }
        return game
    }
    
    /// Fetches a user's leaderboard entry
    private func fetchLeaderboardEntry(userId: String, tournamentId: String) async throws -> LeaderboardEntry {
        let querySnapshot = try await db.collection("leaderboard")
            .whereField("userId", isEqualTo: userId)
            .whereField("tournamentId", isEqualTo: tournamentId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            throw BetError.leaderboardEntryNotFound
        }
        
        let data = document.data()
        guard let username = data["username"] as? String,
              let rank = data["rank"] as? Int,
              let coinsRemaining = data["coinsRemaining"] as? Int,
              let coinsBet = data["coinsBet"] as? Int,
              let coinsWon = data["coinsWon"] as? Int,
              let betsPlaced = data["betsPlaced"] as? Int,
              let betsWon = data["betsWon"] as? Int else {
            throw BetError.invalidLeaderboardData
        }
        
        return LeaderboardEntry(
            id: document.documentID,
            userId: userId,
            tournamentId: tournamentId,
            username: username,
            rank: rank,
            coinsRemaining: coinsRemaining,
            coinsBet: coinsBet,
            coinsWon: coinsWon,
            betsPlaced: betsPlaced,
            betsWon: betsWon,
            avatarURL: data["avatarURL"] as? String
        )
    }
    
    /// Updates user's leaderboard entry
    private func updateLeaderboard(entryId: String, betAmount: Int) async throws {
        try await db.collection("leaderboard").document(entryId).updateData([
            "coinsRemaining": FieldValue.increment(Int64(-betAmount)),
            "coinsBet": FieldValue.increment(Int64(betAmount)),
            "betsPlaced": FieldValue.increment(Int64(1))
        ])
    }
    
    /// Updates user's tournament stats
    private func updateUserTournamentStats(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "tournamentStats.lifetimeBets": FieldValue.increment(Int64(1))
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
        
        // Update coins and bet count
        try await db.collection("leaderboard").document(document.documentID).updateData([
            "coinsRemaining": FieldValue.increment(Int64(amount)),
            "coinsBet": FieldValue.increment(Int64(-amount)),
            "betsPlaced": FieldValue.increment(Int64(-1))
        ])
    }
    
    // MARK: - Error Handling
    enum BetError: Error, LocalizedError {
        case invalidTournament
        case tournamentInactive
        case insufficientCoins
        case gameIsLocked
        case gameNotFound
        case invalidSpread
        case cannotCancel
        case leaderboardEntryNotFound
        case invalidLeaderboardData
        
        var errorDescription: String? {
            switch self {
            case .invalidTournament:
                return "Tournament not found or invalid"
            case .tournamentInactive:
                return "Tournament is not active"
            case .insufficientCoins:
                return "Insufficient tournament coins"
            case .gameIsLocked:
                return "Game is locked for betting"
            case .gameNotFound:
                return "Game not found"
            case .invalidSpread:
                return "Spread has changed significantly"
            case .cannotCancel:
                return "Bet cannot be cancelled"
            case .leaderboardEntryNotFound:
                return "Leaderboard entry not found"
            case .invalidLeaderboardData:
                return "Invalid leaderboard data"
            }
        }
    }
}