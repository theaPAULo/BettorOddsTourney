//
//  BetRepository.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Updated on 4/9/25 for tournament system
//  Version: 3.0.0 - Converted to tournament-based betting
//

import Foundation
import FirebaseFirestore

class BetRepository: Repository {
    // MARK: - Properties
    typealias T = Bet
    
    let cacheFilename = "bets.cache"
    let cacheExpiryTime: TimeInterval = 1800 // 30 minutes
    private let tournamentBetService: TournamentBetService
    private var cachedBets: [String: Bet] = [:]
    
    // MARK: - Initialization
    init() throws {
        self.tournamentBetService = TournamentBetService.shared
        loadCachedBets()
    }
    
    // MARK: - Repository Methods
    
    /// Fetches a bet by ID
    /// - Parameter id: The bet's ID
    /// - Returns: The bet if found, nil otherwise
    func fetch(id: String) async throws -> Bet? {
        // Try cache first
        if let cachedBet = cachedBets[id], isCacheValid() {
            return cachedBet
        }
        
        // If not in cache or cache invalid, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        do {
            // Fetch bet from Firestore directly
            let document = try await FirebaseConfig.shared.db.collection("bets")
                .document(id).getDocument()
            
            guard let bet = Bet(document: document) else {
                throw RepositoryError.itemNotFound
            }
            
            // Save to cache
            cachedBets[id] = bet
            try saveCachedBets()
            
            return bet
        } catch {
            // If the error is "not found", return nil instead of throwing
            if case RepositoryError.itemNotFound = error {
                return nil
            }
            throw error
        }
    }
    
    /// Places a new tournament bet
    /// - Parameter bet: The bet to place
    func save(_ bet: Bet) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Place bet using TournamentBetService
        let savedBet = try await tournamentBetService.placeBet(bet)
        
        // Update cache
        cachedBets[savedBet.id] = savedBet
        try saveCachedBets()
    }
    
    /// Cancels a bet
    /// - Parameter id: The bet's ID
    func remove(id: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Cancel bet using TournamentBetService
        try await tournamentBetService.cancelBet(id)
        
        // Remove from cache
        cachedBets.removeValue(forKey: id)
        try saveCachedBets()
    }
    
    /// Clears the bet cache
    func clearCache() throws {
        cachedBets.removeAll()
        try saveCachedBets()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedBets() {
        do {
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<Bet>.self, from: data)
            cachedBets = container.items
        } catch {
            cachedBets = [:]
        }
    }
    
    private func saveCachedBets() throws {
        let container = CacheContainer(items: cachedBets)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
    }
    
    // MARK: - Additional Methods
    
    /// Fetches all bets for a user in a specific tournament
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - tournamentId: Optional tournament ID filter
    /// - Returns: Array of bets
    func fetchUserBets(
        userId: String,
        tournamentId: String? = nil,
        status: BetStatus? = nil
    ) async throws -> [Bet] {
        guard NetworkMonitor.shared.isConnected else {
            // Return cached bets if offline
            var filteredBets = cachedBets.values.filter { $0.userId == userId }
            
            if let tournamentId = tournamentId {
                filteredBets = filteredBets.filter { $0.tournamentId == tournamentId }
            }
            
            if let status = status {
                filteredBets = filteredBets.filter { $0.status == status }
            }
            
            return filteredBets.sorted { $0.createdAt > $1.createdAt }
        }
        
        // Start with base query
        var query: Query = FirebaseConfig.shared.db.collection("bets")
            .whereField("userId", isEqualTo: userId)
        
        // Add tournament filter if provided
        if let tournamentId = tournamentId {
            query = query.whereField("tournamentId", isEqualTo: tournamentId)
        }
        
        // Add status filter if provided
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        // Execute query with sorting
        let snapshot = try await query
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        // Process results
        let bets = snapshot.documents.compactMap { Bet(document: $0) }
        
        // Cache each bet
        for bet in bets {
            cachedBets[bet.id] = bet
        }
        try saveCachedBets()
        
        return bets
    }
    
    /// Fetches user's stats for a tournament
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - tournamentId: The tournament ID
    /// - Returns: Betting statistics
    func fetchTournamentStats(userId: String, tournamentId: String) async throws -> TournamentBetStats {
        let bets = try await fetchUserBets(userId: userId, tournamentId: tournamentId)
        
        var stats = TournamentBetStats()
        stats.totalBets = bets.count
        stats.totalCoinsWagered = bets.reduce(0) { $0 + $1.amount }
        stats.totalWonBets = bets.filter { $0.status == .won }.count
        stats.totalWonCoins = bets.filter { $0.status == .won }.reduce(0) { $0 + $1.potentialWinnings }
        
        // Calculate metrics
        if stats.totalBets > 0 {
            stats.winPercentage = Double(stats.totalWonBets) / Double(stats.totalBets) * 100
        }
        
        if stats.totalCoinsWagered > 0 {
            stats.roi = (Double(stats.totalWonCoins - stats.totalCoinsWagered) / Double(stats.totalCoinsWagered)) * 100
        }
        
        return stats
    }
}

// MARK: - Tournament Bet Stats
struct TournamentBetStats {
    var totalBets: Int = 0
    var totalCoinsWagered: Int = 0
    var totalWonBets: Int = 0
    var totalWonCoins: Int = 0
    var winPercentage: Double = 0.0
    var roi: Double = 0.0
    
    var formattedWinPercentage: String {
        return String(format: "%.1f%%", winPercentage)
    }
    
    var formattedROI: String {
        return String(format: "%.1f%%", roi)
    }
}
