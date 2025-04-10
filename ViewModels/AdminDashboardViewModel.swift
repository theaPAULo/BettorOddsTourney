//
//  AdminDashboardViewModel.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

// Explicitly import transaction types
import struct BettorOdds.Transaction
import enum BettorOdds.TransactionType
import enum BettorOdds.TransactionStatus

class AdminDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var users: [User] = []
    @Published var tournaments: [Tournament] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var bets: [Bet] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // Stats
    @Published var userCount = 0
    @Published var activeSubscriberCount = 0
    @Published var totalRevenue = 0.0
    @Published var betCount = 0
    
    // MARK: - Private Properties
    private let db = FirebaseConfig.shared.db
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        Task {
            await loadDashboardData()
        }
    }
    
    // MARK: - Data Loading
    
    /// Loads all dashboard data
    @MainActor
    func loadDashboardData() async {
        isLoading = true
        
        do {
            // Load users
            await loadUsers()
            
            // Load tournaments
            await loadTournaments()
            
            // Load recent transactions
            await loadRecentTransactions()
            
            // Load recent bets
            await loadRecentBets()
            
            error = nil
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Individual Data Loading
    
    /// Loads users for admin dashboard
    @MainActor
    private func loadUsers() async {
        do {
            let snapshot = try await db.collection("users")
                .order(by: "dateJoined", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            let loadedUsers = snapshot.documents.compactMap { User(document: $0) }
            
            // Calculate stats
            let userCountSnapshot = try await db.collection("users").count.getAggregation(source: .server)
            let activeSubscribersSnapshot = try await db.collection("users")
                .whereField("subscriptionStatus", isEqualTo: SubscriptionStatus.active.rawValue)
                .count.getAggregation(source: .server)
            
            // Extract count values
            let userCount = userCountSnapshot.count
            let activeSubscribers = activeSubscribersSnapshot.count
            
            self.users = loadedUsers
            self.userCount = Int(userCount)
            self.activeSubscriberCount = Int(activeSubscribers)
        } catch {
            print("Error loading users: \(error.localizedDescription)")
        }
    }
    
    /// Loads tournaments for admin dashboard
    @MainActor
    private func loadTournaments() async {
        do {
            let snapshot = try await db.collection("tournaments")
                .order(by: "startDate", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            let loadedTournaments = snapshot.documents.compactMap { Tournament(document: $0) }
            
            self.tournaments = loadedTournaments
        } catch {
            print("Error loading tournaments: \(error.localizedDescription)")
        }
    }
    
    /// Loads recent transactions for admin dashboard
    @MainActor
    private func loadRecentTransactions() async {
        do {
            let snapshot = try await db.collection("transactions")
                .order(by: "timestamp", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            let loadedTransactions = snapshot.documents.compactMap { Transaction(document: $0) }
            
            // Calculate total revenue
            let subQuery = db.collection("transactions")
                .whereField("type", isEqualTo: TransactionType.subscription.rawValue)
            
            let subSnapshot = try await subQuery.getDocuments()
            let totalRevenue = subSnapshot.documents.compactMap { Transaction(document: $0) }
                .reduce(0.0) { $0 + $1.amount }
            
            self.recentTransactions = loadedTransactions
            self.totalRevenue = totalRevenue
        } catch {
            print("Error loading transactions: \(error.localizedDescription)")
        }
    }
    
    /// Loads recent bets for admin dashboard
    @MainActor
    private func loadRecentBets() async {
        do {
            let snapshot = try await db.collection("bets")
                .order(by: "createdAt", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            let loadedBets = snapshot.documents.compactMap { Bet(document: $0) }
            
            // Calculate total bet count
            let betCountSnapshot = try await db.collection("bets").count.getAggregation(source: .server)
            
            self.bets = loadedBets
            self.betCount = Int(betCountSnapshot.count)
        } catch {
            print("Error loading bets: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Admin Actions
    
    /// Creates a new tournament
    /// - Parameter tournament: The tournament to create
    @MainActor
    func createTournament(_ tournament: Tournament) async throws {
        try await db.collection("tournaments").document(tournament.id).setData(tournament.toDictionary())
        
        // Refresh tournaments list
        await loadTournaments()
    }
    
    /// Updates a tournament's status
    /// - Parameters:
    ///   - tournamentId: The tournament ID
    ///   - status: The new status
    @MainActor
    func updateTournamentStatus(tournamentId: String, status: TournamentStatus) async throws {
        try await db.collection("tournaments").document(tournamentId).updateData([
            "status": status.rawValue
        ])
        
        // Refresh tournaments list
        await loadTournaments()
    }
    
    /// Resets a user's tournament coins
    /// - Parameter userId: The user's ID
    @MainActor
    func resetUserCoins(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "weeklyCoins": 1000,
            "weeklyCoinsReset": Timestamp(date: Date().nextSunday())
        ])
        
        // If user is in a tournament, update leaderboard entry
        let user = self.users.first { $0.id == userId }
        if let tournamentId = user?.currentTournamentId {
            let leaderboardSnapshot = try await db.collection("leaderboard")
                .whereField("userId", isEqualTo: userId)
                .whereField("tournamentId", isEqualTo: tournamentId)
                .limit(to: 1)
                .getDocuments()
            
            if let document = leaderboardSnapshot.documents.first {
                try await db.collection("leaderboard").document(document.documentID).updateData([
                    "coinsRemaining": 1000
                ])
            }
        }
        
        // Refresh users
        await loadUsers()
    }
    
    /// Manages a user's subscription
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - active: Whether to activate or deactivate
    @MainActor
    func manageSubscription(userId: String, active: Bool) async throws {
        if active {
            // Activate subscription
            let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            
            try await db.collection("users").document(userId).updateData([
                "subscriptionStatus": SubscriptionStatus.active.rawValue,
                "subscriptionExpiryDate": Timestamp(date: expiryDate)
            ])
            
            // Record transaction
            let transaction = Transaction(
                userId: userId,
                amount: 19.99,
                type: .subscription,
                notes: "Monthly subscription (admin)"
            )
            
            try await db.collection("transactions").document(transaction.id).setData(transaction.toDictionary())
        } else {
            // Cancel subscription
            try await db.collection("users").document(userId).updateData([
                "subscriptionStatus": SubscriptionStatus.cancelled.rawValue
            ])
        }
        
        // Refresh data
        await loadUsers()
        await loadRecentTransactions()
    }
}
