//
//  TournamentService.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 1.0.1 - Fixed missing try
//

import Foundation
import FirebaseFirestore

actor TournamentService {
    // MARK: - Properties
    static let shared = TournamentService()
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Tournament Methods
    
    /// Fetches the active tournament
    /// - Returns: The currently active tournament, if any
    func fetchActiveTournament() async throws -> Tournament? {
        let snapshot = try await db.collection("tournaments")
            .whereField("status", isEqualTo: TournamentStatus.active.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return Tournament(document: document)
    }
    
    /// Fetches a specific tournament by ID
    /// - Parameter tournamentId: The tournament ID
    /// - Returns: The tournament if found
    func fetchTournament(tournamentId: String) async throws -> Tournament {
        let document = try await db.collection("tournaments").document(tournamentId).getDocument()
        
        guard let tournament = Tournament(document: document) else {
            throw TournamentError.tournamentNotFound
        }
        
        return tournament
    }
    
    /// Fetches tournaments with optional status filter
    /// - Parameter status: Optional tournament status filter
    /// - Returns: Array of tournaments
    func fetchTournaments(status: TournamentStatus? = nil) async throws -> [Tournament] {
        let query: Query
        
        if let status = status {
            query = db.collection("tournaments")
                .whereField("status", isEqualTo: status.rawValue)
                .order(by: "startDate", descending: true)
        } else {
            query = db.collection("tournaments")
                .order(by: "startDate", descending: true)
        }
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { Tournament(document: $0) }
    }
    
    // MARK: - Leaderboard Methods
    
    /// Fetches top leaderboard entries for a tournament
    /// - Parameters:
    ///   - tournamentId: The tournament ID
    ///   - limit: Maximum number of entries to fetch
    /// - Returns: Array of leaderboard entries
    func fetchLeaderboard(tournamentId: String, limit: Int = 20) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection("leaderboard")
            .whereField("tournamentId", isEqualTo: tournamentId)
            .order(by: "rank", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> LeaderboardEntry? in
            let data = document.data()
            guard let userId = data["userId"] as? String,
                  let username = data["username"] as? String,
                  let rank = data["rank"] as? Int,
                  let coinsRemaining = data["coinsRemaining"] as? Int,
                  let coinsBet = data["coinsBet"] as? Int,
                  let coinsWon = data["coinsWon"] as? Int,
                  let betsPlaced = data["betsPlaced"] as? Int,
                  let betsWon = data["betsWon"] as? Int else {
                return nil
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
    }
    
    /// Fetches a user's leaderboard entry
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - tournamentId: The tournament ID
    /// - Returns: The user's leaderboard entry
    func fetchUserLeaderboardEntry(userId: String, tournamentId: String) async throws -> LeaderboardEntry? {
        let snapshot = try await db.collection("leaderboard")
            .whereField("userId", isEqualTo: userId)
            .whereField("tournamentId", isEqualTo: tournamentId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        let data = document.data()
        guard let username = data["username"] as? String,
              let rank = data["rank"] as? Int,
              let coinsRemaining = data["coinsRemaining"] as? Int,
              let coinsBet = data["coinsBet"] as? Int,
              let coinsWon = data["coinsWon"] as? Int,
              let betsPlaced = data["betsPlaced"] as? Int,
              let betsWon = data["betsWon"] as? Int else {
            throw TournamentError.invalidLeaderboardData
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
    
    // MARK: - Subscription Methods
    
    /// Subscribes a user to the tournament system
    /// - Parameter userId: The user's ID
    /// - Returns: Updated subscription status
    func subscribeUser(userId: String) async throws -> SubscriptionStatus {
        // Set expiry to one month from now
        let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        // Update user subscription status
        try await db.collection("users").document(userId).updateData([
            "subscriptionStatus": SubscriptionStatus.active.rawValue,
            "subscriptionExpiryDate": Timestamp(date: expiryDate)
        ])
        
        // Get active tournament
        let tournament = try await fetchActiveTournament()
        
        // Register for tournament if active one exists
        if let tournament = tournament {
            try await registerForTournament(userId: userId, tournamentId: tournament.id)
        }
        
        return .active
    }
    
    /// Cancels a user's subscription
    /// - Parameter userId: The user's ID
    /// - Returns: Updated subscription status
    func cancelSubscription(userId: String) async throws -> SubscriptionStatus {
        // Update user subscription status
        try await db.collection("users").document(userId).updateData([
            "subscriptionStatus": SubscriptionStatus.cancelled.rawValue
        ])
        
        return .cancelled
    }
    
    /// Registers a user for a tournament
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - tournamentId: The tournament ID
    func registerForTournament(userId: String, tournamentId: String) async throws {
        // Get user document
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(),
              let email = userData["email"] as? String else {
            throw TournamentError.userNotFound
        }
        
        // Check if user already has a leaderboard entry
        let leaderboardQuery = try await db.collection("leaderboard")
            .whereField("tournamentId", isEqualTo: tournamentId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        if leaderboardQuery.documents.isEmpty {
            // Generate username from email
            let username = email.components(separatedBy: "@").first ?? "User"
            
            // Create leaderboard entry
            try await db.collection("leaderboard").addDocument(data: [
                "userId": userId,
                "tournamentId": tournamentId,
                "username": username,
                "rank": 0, // Will be updated by cloud function
                "coinsRemaining": 1000,
                "coinsBet": 0,
                "coinsWon": 0,
                "betsPlaced": 0,
                "betsWon": 0,
                "createdAt": Timestamp(date: Date())
            ])
            
            // Update tournament participant count
            try await db.collection("tournaments").document(tournamentId).updateData([
                "participantCount": FieldValue.increment(Int64(1))
            ])
            
            // Update user's current tournament
            try await db.collection("users").document(userId).updateData([
                "currentTournamentId": tournamentId,
                "tournamentStats.tournamentsEntered": FieldValue.increment(Int64(1))
            ])
        } else {
            // Reset existing entry's weekly coins
            try await db.collection("leaderboard").document(leaderboardQuery.documents.first!.documentID).updateData([
                "coinsRemaining": 1000,
                "coinsBet": 0,
                "coinsWon": 0,
                "betsPlaced": 0,
                "betsWon": 0
            ])
        }
    }
    
    /// Claims daily login bonus coins
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - tournamentId: The tournament ID
    /// - Returns: Bonus amount claimed
    func claimDailyBonus(userId: String, tournamentId: String) async throws -> Int {
        // Fetch user to get login streak
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data() else {
            throw TournamentError.userNotFound
        }
        
        // Get login streak
        let loginStreak = userData["loginStreak"] as? Int ?? 0
        
        // Calculate bonus amount based on streak
        let bonusAmount = DailyBonus.bonusForDay(loginStreak)
        
        // Get leaderboard entry
        let leaderboardQuery = try await db.collection("leaderboard")
            .whereField("tournamentId", isEqualTo: tournamentId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        guard let leaderboardDoc = leaderboardQuery.documents.first else {
            throw TournamentError.leaderboardEntryNotFound
        }
        
        // Update coins remaining
        try await db.collection("leaderboard").document(leaderboardDoc.documentID).updateData([
            "coinsRemaining": FieldValue.increment(Int64(bonusAmount))
        ])
        
        // Create bonus record
        try await db.collection("bonuses").addDocument(data: [
            "userId": userId,
            "tournamentId": tournamentId,
            "amount": bonusAmount,
            "streak": loginStreak,
            "type": "daily",
            "createdAt": Timestamp(date: Date())
        ])
        
        return bonusAmount
    }
    
    // MARK: - Error Handling
    enum TournamentError: Error, LocalizedError {
        case tournamentNotFound
        case tournamentInactive
        case userNotFound
        case leaderboardEntryNotFound
        case invalidLeaderboardData
        case subscriptionRequired
        case alreadyRegistered
        
        var errorDescription: String? {
            switch self {
            case .tournamentNotFound:
                return "Tournament not found"
            case .tournamentInactive:
                return "Tournament is not active"
            case .userNotFound:
                return "User not found"
            case .leaderboardEntryNotFound:
                return "Leaderboard entry not found"
            case .invalidLeaderboardData:
                return "Invalid leaderboard data"
            case .subscriptionRequired:
                return "Subscription required to join tournament"
            case .alreadyRegistered:
                return "Already registered for this tournament"
            }
        }
    }
}
