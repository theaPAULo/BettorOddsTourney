//
//  LeaderboardViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  LeaderboardViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class LeaderboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var currentTournament: Tournament?
    @Published var userEntry: LeaderboardEntry?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Pagination
    @Published var hasMoreEntries = false
    private var lastVisibleEntry: DocumentSnapshot?
    private let pageSize = 20
    
    // MARK: - Private Properties
    private let tournamentService = TournamentService.shared
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Initialization
    init() {
        // Initial load will be triggered by onAppear in LeaderboardView
    }
    
    // MARK: - Public Methods
    
    /// Refreshes the leaderboard data
    func refreshLeaderboard() async {
        isLoading = true
        
        do {
            // Reset pagination
            lastVisibleEntry = nil
            hasMoreEntries = false
            
            // 1. Fetch active tournament
            let activeTournament = try await tournamentService.fetchActiveTournament()
            
            guard let tournament = activeTournament else {
                errorMessage = "No active tournament found"
                showError = true
                isLoading = false
                return
            }
            
            // 2. Set current tournament
            await MainActor.run {
                self.currentTournament = tournament
            }
            
            // 3. Fetch user's leaderboard entry
            if let userId = Auth.auth().currentUser?.uid {
                if let userEntry = try await tournamentService.fetchUserLeaderboardEntry(
                    userId: userId,
                    tournamentId: tournament.id
                ) {
                    await MainActor.run {
                        self.userEntry = userEntry
                    }
                }
            }
            
            // 4. Fetch leaderboard entries
            await loadLeaderboardEntries(tournamentId: tournament.id)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    /// Loads more leaderboard entries when scrolling
    func loadMoreEntries() async {
        guard hasMoreEntries, 
              !isLoading, 
              let tournamentId = currentTournament?.id, 
              let lastEntry = lastVisibleEntry else {
            return
        }
        
        isLoading = true
        
        do {
            // Create query with pagination
            let query = db.collection("leaderboard")
                .whereField("tournamentId", isEqualTo: tournamentId)
                .order(by: "rank", descending: false)
                .startAfter(lastEntry)
                .limit(to: pageSize)
            
            let snapshot = try await query.getDocuments()
            
            // Parse entries
            var newEntries: [LeaderboardEntry] = []
            
            for document in snapshot.documents {
                if let entry = parseLeaderboardEntry(document: document) {
                    newEntries.append(entry)
                }
            }
            
            // Update UI
            await MainActor.run {
                self.leaderboardEntries.append(contentsOf: newEntries)
                self.lastVisibleEntry = snapshot.documents.last
                self.hasMoreEntries = snapshot.documents.count == self.pageSize
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// Loads initial set of leaderboard entries
    private func loadLeaderboardEntries(tournamentId: String) async {
        do {
            // Create initial query
            let query = db.collection("leaderboard")
                .whereField("tournamentId", isEqualTo: tournamentId)
                .order(by: "rank", descending: false)
                .limit(to: pageSize)
            
            let snapshot = try await query.getDocuments()
            
            // Parse entries
            var entries: [LeaderboardEntry] = []
            
            for document in snapshot.documents {
                if let entry = parseLeaderboardEntry(document: document) {
                    entries.append(entry)
                }
            }
            
            // Update UI
            await MainActor.run {
                self.leaderboardEntries = entries
                self.lastVisibleEntry = snapshot.documents.last
                self.hasMoreEntries = snapshot.documents.count == self.pageSize
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Parses a leaderboard entry from a document snapshot
    private func parseLeaderboardEntry(document: DocumentSnapshot) -> LeaderboardEntry? {
        let data = document.data() ?? [:]
        guard let userId = data["userId"] as? String,
              let tournamentId = data["tournamentId"] as? String,
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
    
    /// Formats a dollar amount as a string
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}