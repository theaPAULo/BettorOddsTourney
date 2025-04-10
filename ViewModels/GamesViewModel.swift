//
//  GamesViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Shared games view model
//

import SwiftUI
import FirebaseFirestore

class GamesViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var featuredGames: [Game] = []
    @Published var selectedGameType: GameType = .all
    @Published var isLoading = false
    @Published var currentTournament: Tournament?
    
    // Game filtering
    var filteredGames: [Game] {
        switch selectedGameType {
        case .all:
            return games
        case .basketball:
            return games.filter { $0.league == "NBA" }
        case .football:
            return games.filter { $0.league == "NFL" }
        case .baseball:
            return games.filter { $0.league == "MLB" }
        case .soccer:
            return games.filter { $0.league == "Soccer" }
        }
    }
    
    // MARK: - Load Games
    @MainActor
    func loadGames() async {
        isLoading = true
        
        do {
            // Load tournament info first
            await loadCurrentTournament()
            
            // Game repository
            let gameRepository = GameRepository()
            
            // Load featured games
            self.featuredGames = try await gameRepository.fetchMultiple(
                limit: 5,
                filterFeatured: true
            )
            
            // Load regular games
            self.games = try await gameRepository.fetchMultiple(limit: 20)
            
            // Remove duplicates from regular games (if also featured)
            let featuredIds = Set(self.featuredGames.map { $0.id })
            self.games = self.games.filter { !featuredIds.contains($0.id) }
            
            self.isLoading = false
        } catch {
            print("Error loading games: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
    
    @MainActor
    func loadCurrentTournament() async {
        do {
            // Load active tournament if possible
            let tournamentService = TournamentService.shared
            if let tournament = try await tournamentService.fetchActiveTournament() {
                self.currentTournament = tournament
            }
        } catch {
            print("Error loading tournament: \(error.localizedDescription)")
        }
    }
}
