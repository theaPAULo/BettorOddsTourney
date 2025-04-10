//
//  AdminViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  AdminViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class AdminViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Tournament statistics
    @Published var activeTournaments: [Tournament] = []
    @Published var completedTournaments: [Tournament] = []
    @Published var totalUsers = 0
    @Published var activeSubscribers = 0
    @Published var totalBets = 0
    @Published var systemHealth = SystemHealth(
        status: .healthy,
        matchingLatency: 0.5,
        queueProcessingRate: 92.5,
        errorRate: 0.8,
        lastUpdate: Date()
    )
    
    // MARK: - Private Properties
    private let db = FirebaseConfig.shared.db
    private let userService = UserService()
    private let tournamentService = TournamentService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Initial data load
        Task {
            await loadUsers()
            await loadTournaments()
            await loadSystemStats()
        }
    }
    
    // MARK: - User Management
    
    /// Loads all users for admin view
    func loadUsers() async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("users")
                .order(by: "dateJoined", descending: true)
                .limit(to: 50) // Limit for performance
                .getDocuments()
            
            let loadedUsers = snapshot.documents.compactMap { User(document: $0) }
            
            await MainActor.run {
                self.users = loadedUsers
                self.totalUsers = loadedUsers.count
                self.activeSubscribers = loadedUsers.filter { $0.subscriptionStatus == .active }.count
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    /// Resets a user's tournament coins
    /// - Parameter userId: The user's ID
    func resetUserCoins(userId: String) async throws {
        let userRepository = UserRepository()
        try await userRepository.resetWeeklyCoins(userId: userId)
        
        // Refresh user list
        await loadUsers()
    }
    
    /// Adds coins to a user's account
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: Amount to add
    func addCoinsToUser(userId: String, amount: Int) async throws {
        let userRepository = UserRepository()
        try await userRepository.updateTournamentCoins(userId: userId, amount: amount)
        
        // Refresh user list
        await loadUsers()
    }
    
    /// Manages a user's subscription
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - action: Action to take (add or cancel)
    func manageSubscription(userId: String, action: SubscriptionAction) async throws {
        let userRepository = UserRepository()
        
        switch action {
        case .add:
            try await userRepository.subscribeUser(userId: userId)
        case .cancel:
            try await userRepository.cancelSubscription(userId: userId)
        }
        
        // Refresh user list
        await loadUsers()
    }
    
    // MARK: - Tournament Management
    
    /// Loads all tournaments
    func loadTournaments() async {
        do {
            // Load active tournaments
            let activeTournaments = try await tournamentService.fetchTournaments(status: .active)
            
            // Load completed tournaments
            let completedTournaments = try await tournamentService.fetchTournaments(status: .completed)
            
            await MainActor.run {
                self.activeTournaments = activeTournaments
                self.completedTournaments = completedTournaments
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    /// Creates a new tournament
    /// - Parameter tournament: The tournament to create
    func createTournament(_ tournament: Tournament) async throws {
        // Create tournament in Firestore
        try await db.collection("tournaments").document(tournament.id).setData(tournament.toDictionary())
        
        // Refresh tournaments list
        await loadTournaments()
    }
    
    /// Updates a tournament's status
    /// - Parameters:
    ///   - tournamentId: The tournament ID
    ///   - status: The new status
    func updateTournamentStatus(tournamentId: String, status: TournamentStatus) async throws {
        try await db.collection("tournaments").document(tournamentId).updateData([
            "status": status.rawValue
        ])
        
        // Refresh tournaments list
        await loadTournaments()
    }
    
    // MARK: - System Stats and Monitoring
    
    /// Loads system statistics
    func loadSystemStats() async {
        do {
            // Get total bet count
            let snapshot = try await db.collection("bets").getDocuments()
            let totalBets = snapshot.documents.count
            
            // Get system health (simulated for now)
            let systemHealth = SystemHealth(
                status: .healthy,
                matchingLatency: Double.random(in: 0.3...0.9),
                queueProcessingRate: Double.random(in: 90...99),
                errorRate: Double.random(in: 0.1...1.5),
                lastUpdate: Date()
            )
            
            await MainActor.run {
                self.totalBets = totalBets
                self.systemHealth = systemHealth
            }
        } catch {
            print("Error loading system stats: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

enum SubscriptionAction {
    case add
    case cancel
}