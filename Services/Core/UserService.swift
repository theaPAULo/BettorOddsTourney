//
//  UserService.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class UserService {
    // MARK: - Properties
    private let db = FirebaseConfig.shared.db
    private let tournamentService = TournamentService.shared
    
    // MARK: - User CRUD
    
    /// Fetches a user by ID
    /// - Parameter userId: The user's ID
    /// - Returns: The user if found
    func fetchUser(userId: String) async throws -> User {
        // Fetch user document
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let user = User(document: document) else {
            throw DatabaseError.documentNotFound
        }
        
        return user
    }
    
    /// Creates a new user
    /// - Parameter user: The user to create
    /// - Returns: The created user
    func createUser(_ user: User) async throws -> User {
        try await db.collection("users").document(user.id).setData(user.toDictionary())
        return user
    }
    
    /// Updates a user
    /// - Parameter user: The user to update
    /// - Returns: The updated user
    func updateUser(_ user: User) async throws -> User {
        try await db.collection("users").document(user.id).updateData(user.toDictionary())
        return user
    }
    
    /// Deletes a user
    /// - Parameter userId: The user's ID
    func deleteUser(userId: String) async throws {
        try await db.collection("users").document(userId).delete()
    }
    
    // MARK: - Tournament Methods
    
    /// Adds free tournament coins to a user
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: The amount to add
    /// - Returns: The new coin balance
    func addTournamentCoins(userId: String, amount: Int) async throws -> Int {
        // Get the user
        let document = try await db.collection("users").document(userId).getDocument()
        guard let user = User(document: document) else {
            throw DatabaseError.documentNotFound
        }
        
        // Calculate new balance
        let newBalance = user.weeklyCoins + amount
        
        // Update user document
        try await db.collection("users").document(userId).updateData([
            "weeklyCoins": newBalance
        ])
        
        // If user is in a tournament, also update leaderboard entry
        if let tournamentId = user.currentTournamentId {
            // Find leaderboard entry
            let querySnapshot = try await db.collection("leaderboard")
                .whereField("userId", isEqualTo: userId)
                .whereField("tournamentId", isEqualTo: tournamentId)
                .limit(to: 1)
                .getDocuments()
            
            if let document = querySnapshot.documents.first {
                // Update coins remaining
                try await db.collection("leaderboard").document(document.documentID).updateData([
                    "coinsRemaining": FieldValue.increment(Int64(amount))
                ])
            }
        }
        
        return newBalance
    }
    
    /// Resets the user's weekly tournament coins
    /// - Parameter userId: The user's ID
    /// - Returns: The new coin balance
    func resetWeeklyCoins(userId: String) async throws -> Int {
        // Default weekly coins amount
        let weeklyAmount = 1000
        
        // Set the next reset date (Sunday)
        let nextReset = Date().nextSunday()
        
        // Update user document
        try await db.collection("users").document(userId).updateData([
            "weeklyCoins": weeklyAmount,
            "weeklyCoinsReset": Timestamp(date: nextReset)
        ])
        
        // If user is in a tournament, also update leaderboard entry
        let user = try await fetchUser(userId: userId)
        if let tournamentId = user.currentTournamentId {
            // Find leaderboard entry
            let querySnapshot = try await db.collection("leaderboard")
                .whereField("userId", isEqualTo: userId)
                .whereField("tournamentId", isEqualTo: tournamentId)
                .limit(to: 1)
                .getDocuments()
            
            if let document = querySnapshot.documents.first {
                // Reset tournament coins
                try await db.collection("leaderboard").document(document.documentID).updateData([
                    "coinsRemaining": weeklyAmount
                ])
            }
        }
        
        return weeklyAmount
    }
    
    /// Subscribes a user to the tournament system
    /// - Parameter userId: The user's ID
    /// - Returns: Updated subscription status
    func subscribeUser(userId: String) async throws -> SubscriptionStatus {
        // Set expiry to one month from now
        let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        // Update user subscription status
        try await db.collection("users").document(userId).updateData([
            "subscriptionStatus": SubscriptionStatus.active.rawValue,
            "subscriptionExpiryDate": Timestamp(date: expiryDate),
            "subscriptionStartDate": Timestamp(date: Date())
        ])
        
        // Try to register for active tournament
        do {
            if let tournament = try await tournamentService.fetchActiveTournament() {
                try await tournamentService.registerForTournament(
                    userId: userId,
                    tournamentId: tournament.id
                )
            }
        } catch {
            print("Failed to register for tournament: \(error.localizedDescription)")
            // Don't fail the subscription process if tournament registration fails
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
    
    // MARK: - Daily Login Bonus
    
    /// Claims a daily login bonus
    /// - Parameter userId: The user's ID
    /// - Returns: Bonus amount
    func claimDailyLoginBonus(userId: String) async throws -> Int {
        // Get user
        let user = try await fetchUser(userId: userId)
        
        // Calculate login streak
        let streak = calculateLoginStreak(user: user)
        
        // Calculate bonus amount
        let bonusAmount = DailyBonus.bonusForDay(streak)
        
        // Update user
        try await db.collection("users").document(userId).updateData([
            "loginStreak": streak,
            "lastLoginDate": Timestamp(date: Date()),
            "weeklyCoins": user.weeklyCoins + bonusAmount
        ])
        
        // If user is in a tournament, update leaderboard
        if let tournamentId = user.currentTournamentId {
            try await tournamentService.claimDailyBonus(
                userId: userId,
                tournamentId: tournamentId
            )
        }
        
        return bonusAmount
    }
    
    /// Calculates login streak based on last login date
    private func calculateLoginStreak(user: User) -> Int {
        guard let lastLoginDate = user.lastLoginDate else {
            return 1 // First login
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check if last login was yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        if calendar.isDate(lastLoginDate, inSameDayAs: yesterday) {
            // Consecutive login
            return user.loginStreak + 1
        }
        
        // Check if login was today already
        if calendar.isDate(lastLoginDate, inSameDayAs: now) {
            // Maintain current streak
            return user.loginStreak
        }
        
        // Streak broken
        return 1
    }
    
    // MARK: - User Stats
    
    /// Gets user wallet summary with tournament coins
    /// - Parameter userId: The user's ID
    /// - Returns: Wallet summary
    func getWalletSummary(userId: String) async throws -> WalletSummary {
        // Get user
        let user = try await fetchUser(userId: userId)
        
        // Get tournament details if user is in tournament
        var tournament: Tournament?
        var leaderboardEntry: LeaderboardEntry?
        
        if let tournamentId = user.currentTournamentId {
            do {
                tournament = try await tournamentService.fetchTournament(tournamentId: tournamentId)
                leaderboardEntry = try await tournamentService.fetchUserLeaderboardEntry(
                    userId: userId,
                    tournamentId: tournamentId
                )
            } catch {
                // Tournament might be expired or user not registered
                print("Failed to fetch tournament details: \(error.localizedDescription)")
            }
        }
        
        // Build summary
        let summary = WalletSummary(
            tournamentCoins: user.weeklyCoins,
            nextReset: user.weeklyCoinsReset,
            tournament: tournament,
            leaderboardPosition: leaderboardEntry?.rank ?? 0,
            subscriptionStatus: user.subscriptionStatus,
            subscriptionExpiry: user.subscriptionExpiryDate
        )
        
        return summary
    }
}

// MARK: - Wallet Summary
struct WalletSummary {
    let tournamentCoins: Int
    let nextReset: Date
    let tournament: Tournament?
    let leaderboardPosition: Int
    let subscriptionStatus: SubscriptionStatus
    let subscriptionExpiry: Date?
    
    var isInTournament: Bool {
        return tournament != nil
    }
    
    var formattedNextReset: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: nextReset)
    }
    
    var formattedExpiry: String {
        guard let date = subscriptionExpiry else {
            return "N/A"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Database Error
enum DatabaseError: Error, LocalizedError {
    case documentNotFound
    case invalidData
    case writeFailed
    case permissionDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid document data"
        case .writeFailed:
            return "Failed to write to database"
        case .permissionDenied:
            return "Permission denied"
        case .unknown:
            return "Unknown database error"
        }
    }
}
