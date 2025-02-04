import Foundation
import FirebaseFirestore

class GameRepository: Repository {
    // MARK: - Properties
    typealias T = Game
    
    let cacheFilename = "games.cache"
    let cacheExpiryTime: TimeInterval = 300 // 5 minutes
    
    private let gameService: GameService
    private var listeners: [String: ListenerRegistration] = [:]
    private var cachedGames: [String: Game] = [:]
    
    // MARK: - Initialization
    init() {
        self.gameService = GameService()
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
            let game = try await gameService.fetchGame(gameId: id)
            cachedGames[id] = game
            try saveCachedGames()
            return game
        } catch {
            // If not found, return nil instead of throwing
            if case RepositoryError.itemNotFound = error {
                return nil
            }
            throw error
        }
    }
    
    func save(_ game: Game) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw DatabaseError.networkError
        }
        
        try await gameService.saveGame(game)
        cachedGames[game.id] = game
        try saveCachedGames()
    }
    
    func remove(id: String) async throws {
        // Remove from cache
        cachedGames.removeValue(forKey: id)
        try saveCachedGames()
        
        // Note: In this implementation, we don't actually delete games from the server
        // as they're managed by the odds service. This is just for cache management.
    }
    
    func clearCache() throws {
        cachedGames.removeAll()
        try saveCachedGames()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedGames() {
        do {
            print("📂 Attempting to load games from cache...")
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<Game>.self, from: data)
            cachedGames = container.items
            print("✅ Successfully loaded \(cachedGames.count) games from cache")
        } catch {
            if (error as NSError).domain == NSCocoaErrorDomain &&
               (error as NSError).code == 260 {
                print("ℹ️ No cache file found - this is normal on first run")
            } else {
                print("⚠️ Failed to load games cache: \(error)")
            }
            cachedGames = [:]
        }
    }

    private func saveCachedGames() throws {
        print("💾 Saving games to cache...")
        let container = CacheContainer(items: cachedGames)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
        print("✅ Successfully saved \(cachedGames.count) games to cache")
    }
    
    // MARK: - Additional Methods
    
    /// Fetches games for a specific league
    /// - Parameter league: The league to fetch games for
    /// - Returns: Array of games
    func fetchGames(league: String) async throws -> [Game] {
        guard NetworkMonitor.shared.isConnected else {
            return cachedGames.values
                .filter { $0.league == league }
                .sorted { $0.time < $1.time }
        }
        
        let games = try await gameService.fetchGames(league: league)
        
        // Update cache
        for game in games {
            cachedGames[game.id] = game
        }
        try saveCachedGames()
        
        return games
    }
    
    // Add this method to GameRepository.swift

    // Add this method to GameRepository class in GameRepository.swift

    // Add this method to GameRepository class in GameRepository.swift

    /// Syncs games from The Odds API to Firestore
    /// - Parameter games: Array of games to sync
    // Add this method to GameRepository class

    /// Syncs games from The Odds API to Firestore and removes expired games
    /// - Parameter games: Array of games to sync
    func syncGames(_ games: [Game]) async throws {
        print("🔄 Starting game sync to Firestore with \(games.count) games")
        let firestore = FirebaseConfig.shared.db
        let batch = firestore.batch()
        
        // Get all existing games
        let snapshot = try await firestore.collection("games").getDocuments()
        print("📚 Found \(snapshot.documents.count) existing games in Firestore")
        
        // Create set of game IDs from The Odds API (these are the active games)
        let activeGameIds = Set(games.map { $0.id })
        print("🎮 Active game IDs from The Odds API: \(activeGameIds.count)")
        
        // Track games to remove
        var removedGameCount = 0
        
        // First, process existing games
        for document in snapshot.documents {
            let gameId = document.documentID
            
            // If game is no longer in The Odds API, remove it
            if !activeGameIds.contains(gameId) {
                print("🗑️ Removing finished game: \(gameId) (no longer in The Odds API)")
                let gameRef = firestore.collection("games").document(gameId)
                batch.deleteDocument(gameRef)
                removedGameCount += 1
            }
        }
        
        // Now process current games from The Odds API
        for game in games {
            print("""
                📥 Processing game from API:
                - ID: \(game.id)
                - Teams: \(game.homeTeam) vs \(game.awayTeam)
                - Start Time: \(game.time)
                - Should be locked: \(game.shouldBeLocked)
                """)
            
            let gameRef = firestore.collection("games").document(game.id)
            var gameData = game.toDictionary()
            
            // If game exists, preserve admin settings
            if let existingDoc = snapshot.documents.first(where: { $0.documentID == game.id }) {
                let existingData = existingDoc.data()
                
                // Preserve manual settings
                if let manuallyFeatured = existingData["manuallyFeatured"] as? Bool {
                    gameData["manuallyFeatured"] = manuallyFeatured
                }
                if let isFeatured = existingData["isFeatured"] as? Bool {
                    gameData["isFeatured"] = isFeatured
                }
                if let isVisible = existingData["isVisible"] as? Bool {
                    gameData["isVisible"] = isVisible
                }
                if let lastUpdatedBy = existingData["lastUpdatedBy"] as? String {
                    gameData["lastUpdatedBy"] = lastUpdatedBy
                }
                if let lastUpdatedAt = existingData["lastUpdatedAt"] {
                    gameData["lastUpdatedAt"] = lastUpdatedAt
                }
            }
            
            // Add to batch
            batch.setData(gameData, forDocument: gameRef, merge: true)
        }
        
        // Commit the batch
        try await batch.commit()
        print("""
            ✅ Sync completed:
            - Active games synced: \(games.count)
            - Finished games removed: \(removedGameCount)
            """)
    }
    
    // MARK: - Real-time Updates
    
    /// Sets up a real-time listener for game updates
    /// - Parameters:
    ///   - gameId: The ID of the game to listen to
    ///   - handler: Closure to handle game updates
    /// - Returns: Listener registration that can be used to remove the listener
    func listenToGameUpdates(gameId: String, handler: @escaping (Game?) -> Void) {
        Task {
            let listener = await gameService.listenToGameUpdates(gameId: gameId) { game in
                handler(game)
                
                // Update cache if game exists
                if let game = game {
                    self.cachedGames[game.id] = game
                    try? self.saveCachedGames()
                }
            }
            
            listeners[gameId] = listener
        }
    }
    
    // Update these methods in the Repository protocol extension

    /// Saves data to cache
    func saveToCache(_ data: Data) throws {
        // Ensure cache directory exists
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Save the data
        try data.write(to: cacheURL)
    }

    /// Loads data from cache
    func loadFromCache() throws -> Data {
        // Check if cache file exists
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: 260,
                userInfo: [
                    NSFilePathErrorKey: cacheURL.path,
                    NSLocalizedDescriptionKey: "Cache file does not exist"
                ]
            )
        }
        
        return try Data(contentsOf: cacheURL)
    }
    
    /// Removes a specific game listener
    /// - Parameter gameId: The ID of the game to stop listening to
    func removeListener(for gameId: String) {
        listeners[gameId]?.remove()
        listeners.removeValue(forKey: gameId)
    }
    
    /// Removes all game listeners
    func removeAllListeners() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Cleanup
    deinit {
        removeAllListeners()
    }
}
