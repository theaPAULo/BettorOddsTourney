//
//  BetModalViewModel.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class BetModalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var betAmount: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var coinsRemaining: Int = 0
    @Published var currentTournament: Tournament?
    @Published var leaderboardEntry: LeaderboardEntry?
    @Published var selectedBetType: BetType = .spread
    
    // MARK: - Private Properties
    private let game: Game
    private let user: User
    private let db = FirebaseConfig.shared.db
    private var betRepository: BetRepository?
    private let tournamentService = TournamentService.shared
    
    // MARK: - Computed Properties
    var canPlaceBet: Bool {
        guard let amount = Int(betAmount), amount > 0 else {
            return false
        }
            
        // Check if game is locked
        if game.isLocked || game.shouldBeLocked {
            return false
        }
        
        // Only allow bet if there's an active tournament and user is subscribed
        if currentTournament == nil || user.subscriptionStatus != .active {
            return false
        }
            
        // Check if user has enough tournament coins
        return amount <= coinsRemaining
    }
    
    var potentialWinnings: String {
        guard let amount = Int(betAmount) else { return "0" }
        
        // Different calculations based on bet type
        switch selectedBetType {
        case .spread:
            return String(format: "%d", amount) // Even money
        case .moneyline:
            return String(format: "%d", Int(Double(amount) * 0.9))
        case .overUnder:
            return String(format: "%d", amount) // Even money
        }
    }
    
    // MARK: - Initialization
    init(game: Game, user: User) {
        self.game = game
        self.user = user
        
        // Initialize repository
        do {
            self.betRepository = try BetRepository()
        } catch {
            print("Failed to initialize BetRepository: \(error)")
        }
        
        // Load tournament data on init
        Task {
            await loadTournamentData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads tournament data and user's leaderboard entry
    func loadTournamentData() async {
        isProcessing = true
        
        do {
            // 1. Clear any existing error
            errorMessage = nil
            
            // 2. Check for active tournament
            if let tournamentId = user.currentTournamentId {
                let tournament = try await tournamentService.fetchTournament(tournamentId: tournamentId)
                
                // Only proceed if tournament is active
                if tournament.status == .active {
                    // 3. Fetch user's leaderboard entry
                    if let entry = try await tournamentService.fetchUserLeaderboardEntry(
                        userId: user.id,
                        tournamentId: tournamentId
                    ) {
                        await MainActor.run {
                            self.currentTournament = tournament
                            self.leaderboardEntry = entry
                            self.coinsRemaining = entry.coinsRemaining
                        }
                    } else {
                        errorMessage = "Unable to find your tournament entry"
                    }
                } else {
                    errorMessage = "No active tournament found"
                }
            } else {
                // Try to find any active tournament
                if let activeTournament = try await tournamentService.fetchActiveTournament() {
                    // Check if user has active subscription
                    if user.subscriptionStatus == .active {
                        // Register for tournament
                        try await tournamentService.registerForTournament(
                            userId: user.id,
                            tournamentId: activeTournament.id
                        )
                        
                        // Refresh data after registration
                        await loadTournamentData()
                    } else {
                        errorMessage = "Subscription required to join tournament"
                    }
                } else {
                    errorMessage = "No active tournament found"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    /// Places a bet
    /// - Parameters:
    ///   - team: The team being bet on
    ///   - isHomeTeam: Whether the bet is on the home team
    func placeBet(team: String, isHomeTeam: Bool) async throws -> Bool {
        guard !isProcessing else { return false }
        guard let amount = Int(betAmount), amount > 0 else {
            errorMessage = "Invalid bet amount"
            return false
        }
        
        // Check tournament validity
        guard let tournament = currentTournament, tournament.status == .active else {
            errorMessage = "No active tournament available"
            return false
        }
        
        // Check if coins are available
        if amount > coinsRemaining {
            errorMessage = "Insufficient tournament coins"
            return false
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            // Create bet
            let bet = Bet(
                userId: user.id,
                gameId: game.id,
                tournamentId: tournament.id,
                amount: amount,
                initialSpread: isHomeTeam ? game.spread : -game.spread,
                team: team,
                isHomeTeam: isHomeTeam,
                betType: selectedBetType
            )
            
            // Place bet using repository
            try await betRepository?.save(bet)
            
            // Update local coins remaining counter
            coinsRemaining -= amount
            
            // Update leaderboard entry if available
            if var updatedEntry = leaderboardEntry {
                updatedEntry.coinsRemaining -= amount
                updatedEntry.coinsBet += amount
                updatedEntry.betsPlaced += 1
                leaderboardEntry = updatedEntry
            }
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        } finally {
            isProcessing = false
        }
    }
}
