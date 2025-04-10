//
//  BetsManager.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import Foundation
import FirebaseFirestore
import FirebaseAuth


class BetsManager: ObservableObject {
    // MARK: - Properties
    @Published var myBets: [Bet] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentTournament: Tournament?
    
    private let db = FirebaseConfig.shared.db
    private let betRepository: BetRepository
    private let tournamentService = TournamentService.shared
    
    // MARK: - Shared Instance
    static let shared = BetsManager()
    
    // MARK: - Initialization
    init() {
        // Initialize bet repository
        do {
            self.betRepository = try BetRepository()
        } catch {
            fatalError("Failed to initialize BetRepository: \(error)")
        }
        
        // Load bets
        loadMyBets()
    }
    // MARK: - Public Methods
    
    /// Loads the current user's bets
    func loadMyBets() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // First load tournament info to filter by current tournament
                await loadCurrentTournament()
                
                // Fetch bets filtered by current tournament
                let tournamentId = currentTournament?.id
                
                // Load bets
                let bets = try await betRepository.fetchUserBets(
                    userId: userId,
                    tournamentId: tournamentId
                )
                
                // Update on main thread
                await MainActor.run {
                    self.myBets = bets
                    self.isLoading = false
                    self.error = nil
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Loads the current active tournament
    @MainActor
    func loadCurrentTournament() async {
        do {
            if let tournament = try await tournamentService.fetchActiveTournament() {
                self.currentTournament = tournament
            } else {
                self.currentTournament = nil
            }
        } catch {
            self.error = error
            self.currentTournament = nil
        }
    }
    
    /// Cancels a pending bet
    /// - Parameter bet: The bet to cancel
    func cancelBet(_ bet: Bet) {
        guard bet.status == .pending else {
            // Can only cancel pending bets
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Cancel bet
                try await betRepository.remove(id: bet.id)
                
                // Update bets list
                if let index = myBets.firstIndex(where: { $0.id == bet.id }) {
                    await MainActor.run {
                        myBets.remove(at: index)
                    }
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.error = nil
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Gets tournament betting statistics
    /// - Returns: Stats summary
    func getTournamentStats() async throws -> TournamentBetStats {
        guard let userId = Auth.auth().currentUser?.uid,
              let tournamentId = currentTournament?.id else {
            return TournamentBetStats()
        }
        
        return try await betRepository.fetchTournamentStats(
            userId: userId,
            tournamentId: tournamentId
        )
    }
}
