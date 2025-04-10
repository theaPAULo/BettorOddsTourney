//
//  GameRepository.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import Foundation
import FirebaseFirestore

class GameRepository: Repository {
    // MARK: - Properties
    typealias T = Game
    
    let cacheFilename = "games.cache"
    let cacheExpiryTime: TimeInterval = 300 // 5 minutes
    private var cachedGames: [String: Game] = [:]
    
    // MARK: - Initialization
    init() {
        loadCachedGames()
    }
    
    // MARK: - Repository Protocol Methods
    
    func fetch(id: String) async throws -> Game? {
        // Try cache first
        if let cachedGame = cachedGames[id], isCacheValid() {
            return cachedGame
        }
        
        // If not in cache or cache invalid, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        do {
            let document = try await FirebaseConfig.shared.db.collection("games").document(id).getDocument()
            
            guard let game = Game(from: document) else {
                throw RepositoryError.itemNotFound
            }
            
            // Save to cache
            cachedGames[id] = game
            try saveCachedGames()
            
            return game
        } catch {
            if case RepositoryError.itemNotFound = error {
                return nil
            }
            throw error
        }
    }
    
    func save(_ game: Game) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await FirebaseConfig.shared.db.collection("games").document(game.id).setData(game.toDictionary())
        
        // Update cache
        cachedGames[game.id] = game
        try saveCachedGames()
    }
    
    func remove(id: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await FirebaseConfig.shared.db.collection("games").document(id).delete()
        
        // Remove from cache
        cachedGames.removeValue(forKey: id)
        try saveCachedGames()
    }
    
    func clearCache() throws {
        cachedGames.removeAll()
        try saveCachedGames()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedGames() {
        do {
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<Game>.self, from: data)
            cachedGames = container.items
        } catch {
            cachedGames = [:]
        }
    }
    
    private func saveCachedGames() throws {
        let container = CacheContainer(items: cachedGames)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
    }
    
    // MARK: - Additional Methods
    
    /// Fetches multiple games
    /// - Parameters:
    ///   - limit: Maximum number of games to fetch
    ///   - filterFeatured: Whether to filter for featured games only
    /// - Returns: Array of games
    func fetchMultiple(
        limit: Int = 30,
        filterFeatured: Bool = false,
        isVisible: Bool = true
    ) async throws -> [Game] {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            // If offline, return cached games
            let filteredGames = cachedGames.values.filter { game in
                if !isVisible && !game.isVisible {
                    return false
                }
                if filterFeatured && !game.isFeatured {
                    return false
                }
                return true
            }
            return Array(filteredGames.prefix(limit))
        }
        
        // Start with base query
        var query: Query = FirebaseConfig.shared.db.collection("games")
            .whereField("isVisible", isEqualTo: isVisible)
        
        // Add featured filter if requested
        if filterFeatured {
            query = query.whereField("isFeatured", isEqualTo: true)
        }
        
        // Sort by time (ascending)
        query = query.order(by: "time", descending: false)
        
        // Apply limit
        query = query.limit(to: limit)
        
        // Execute query
        let snapshot = try await query.getDocuments()
        
        // Process results
        let games = snapshot.documents.compactMap { Game(from: $0) }
        
        // Cache each game
        for game in games {
            cachedGames[game.id] = game
        }
        try saveCachedGames()
        
        return games
    }
    
    /// Updates a game's score
    /// - Parameters:
    ///   - gameId: The game's ID
    ///   - score: The game score
    func updateScore(gameId: String, score: GameScore) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Update Firestore
        try await FirebaseConfig.shared.db.collection("games").document(gameId).updateData([
            "score": score.toDictionary(),
            "isLocked": true
        ])
        
        // Update local cache if game exists
        if var game = cachedGames[gameId] {
            game.score = score
            game.isLocked = true
            cachedGames[gameId] = game
            try saveCachedGames()
        }
    }
    
    /// Updates a game's featured status
    /// - Parameters:
    ///   - gameId: The game's ID
    ///   - isFeatured: Whether the game should be featured
    func updateFeaturedStatus(
        gameId: String,
        isFeatured: Bool,
        manuallyFeatured: Bool
    ) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Update Firestore
        try await FirebaseConfig.shared.db.collection("games").document(gameId).updateData([
            "isFeatured": isFeatured,
            "manuallyFeatured": manuallyFeatured
        ])
        
        // Update local cache if game exists
        if var game = cachedGames[gameId] {
            game.isFeatured = isFeatured
            game.manuallyFeatured = manuallyFeatured
            cachedGames[gameId] = game
            try saveCachedGames()
        }
    }
    
    /// Updates a game's locked status
    /// - Parameters:
    ///   - gameId: The game's ID
    ///   - isLocked: Whether betting should be locked
    func updateLockStatus(gameId: String, isLocked: Bool) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Update Firestore
        try await FirebaseConfig.shared.db.collection("games").document(gameId).updateData([
            "isLocked": isLocked
        ])
        
        // Update local cache if game exists
        if var game = cachedGames[gameId] {
            game.isLocked = isLocked
            cachedGames[gameId] = game
            try saveCachedGames()
        }
    }
    
    /// Updates a game's visibility status
    /// - Parameters:
    ///   - gameId: The game's ID
    ///   - isVisible: Whether the game should be visible
    func updateVisibility(gameId: String, isVisible: Bool) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Update Firestore
        try await FirebaseConfig.shared.db.collection("games").document(gameId).updateData([
            "isVisible": isVisible
        ])
        
        // Update local cache if game exists
        if var game = cachedGames[gameId] {
            game.isVisible = isVisible
            cachedGames[gameId] = game
            try saveCachedGames()
        }
    }
}
