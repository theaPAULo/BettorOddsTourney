import Foundation
import FirebaseFirestore

// Error types for database operations
enum DatabaseError: Error {
    case documentNotFound
    case invalidData
    case parseError
    case networkError
    case permissionDenied
    case unknown
    
    var description: String {
        switch self {
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .parseError:
            return "Failed to parse document"
        case .networkError:
            return "Network error occurred"
        case .permissionDenied:
            return "Permission denied"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

actor GameService {
    private let db = FirebaseConfig.shared.db
    
    /// Fetches a specific game
    func fetchGame(gameId: String) async throws -> Game {
        let document = try await db.collection("games").document(gameId).getDocument()
        
        guard document.exists else {
            throw DatabaseError.documentNotFound
        }
        
        let data = document.data() ?? [:]
        
        guard let id = data["id"] as? String,
              let homeTeam = data["homeTeam"] as? String,
              let awayTeam = data["awayTeam"] as? String,
              let time = (data["time"] as? Timestamp)?.dateValue(),
              let league = data["league"] as? String,
              let spread = data["spread"] as? Double,
              let totalBets = data["totalBets"] as? Int else {
            throw DatabaseError.documentNotFound
        }
        
        // Create game object with optional score
        var game = Game(
            id: id,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            time: time,
            league: league,
            spread: spread,
            totalBets: totalBets,
            homeTeamColors: TeamColors.getTeamColors(homeTeam),
            awayTeamColors: TeamColors.getTeamColors(awayTeam)
        )
        
        // Try to get score if it exists
        if let scoreData = try? await db.collection("scores").document(id).getDocument(),
           let score = GameScore.from(scoreData) {
            game.score = score
        }
        
        return game
    }
    
    /// Fetches games for a specific league
    func fetchGames(league: String) async throws -> [Game] {
        let snapshot = try await db.collection("games")
            .whereField("league", isEqualTo: league)
            .order(by: "time")
            .getDocuments()
        
        return try await withThrowingTaskGroup(of: Game.self) { group in
            var games: [Game] = []
            
            for document in snapshot.documents {
                group.addTask {
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let homeTeam = data["homeTeam"] as? String,
                          let awayTeam = data["awayTeam"] as? String,
                          let time = (data["time"] as? Timestamp)?.dateValue(),
                          let league = data["league"] as? String,
                          let spread = data["spread"] as? Double,
                          let totalBets = data["totalBets"] as? Int else {
                        throw DatabaseError.documentNotFound
                    }
                    
                    var game = Game(
                        id: id,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        time: time,
                        league: league,
                        spread: spread,
                        totalBets: totalBets,
                        homeTeamColors: TeamColors.getTeamColors(homeTeam),
                        awayTeamColors: TeamColors.getTeamColors(awayTeam)
                    )
                    
                    // Try to get score
                    if let scoreData = try? await self.db.collection("scores").document(id).getDocument(),
                       let score = GameScore.from(scoreData) {
                        game.score = score
                    }
                    
                    return game
                }
            }
            
            // Collect results
            for try await game in group {
                games.append(game)
            }
            
            return games.sorted { $0.time < $1.time }
        }
    }
    
    /// Fetches scores for completed games
    func fetchScores(for sport: String) async throws {
        print("🎯 Starting score fetch for \(sport)")
        
        // First fetch scores from The Odds API
        let scoreService = ScoreService.shared
        try await scoreService.fetchScores(sport: sport)
        
        // Now fetch games that need score resolution
        let games = try await fetchGames(league: sport)
        print("📊 Found \(games.count) games to check for scores")
        
        for game in games {
            if let score = try? await db.collection("scores").document(game.id).getDocument(),
               let gameScore = GameScore.from(score) {
                print("✅ Found score for game \(game.id): \(gameScore.homeScore)-\(gameScore.awayScore)")
                
                // Update game with score
                var updatedGame = game
                updatedGame.score = gameScore
                try await saveGame(updatedGame)
            }
        }
        
        print("✅ Completed score update cycle")
    }
    
    /// Saves a game to the database
    func saveGame(_ game: Game) async throws {
        var gameData: [String: Any] = [
            "id": game.id,
            "homeTeam": game.homeTeam,
            "awayTeam": game.awayTeam,
            "time": game.time,
            "league": game.league,
            "spread": game.spread,
            "totalBets": game.totalBets
        ]
        
        // Include score if available
        if let score = game.score {
            gameData["score"] = score.toDictionary()
        }
        
        try await db.collection("games").document(game.id).setData(gameData, merge: true)
    }
    
    /// Sets up a real-time listener for game updates
    func listenToGameUpdates(
        gameId: String,
        handler: @escaping (Game?) -> Void
    ) -> ListenerRegistration {
        let ref = db.collection("games").document(gameId)
        
        return ref.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  document.exists else {
                handler(nil)
                return
            }
            
            Task {
                do {
                    let game = try await self.fetchGame(gameId: gameId)
                    handler(game)
                } catch {
                    handler(nil)
                }
            }
        }
    }
}
