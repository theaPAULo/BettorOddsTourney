import Foundation

actor OddsService {
    // MARK: - Properties
    static let shared = OddsService()
    private let apiKey: String
    private let baseURL = Configuration.API.oddsAPIBaseURL
    
    // MARK: - Initialization
    private init() {
        self.apiKey = Configuration.API.oddsAPIKey
    }
    
    // MARK: - API Response Models
    struct OddsResponse: Codable {
        let id: String
        let sportKey: String
        let homeTeam: String
        let awayTeam: String
        let commenceTime: Date
        let bookmakers: [Bookmaker]
        
        enum CodingKeys: String, CodingKey {
            case id
            case sportKey = "sport_key"
            case homeTeam = "home_team"
            case awayTeam = "away_team"
            case commenceTime = "commence_time"
            case bookmakers
        }
    }
    
    struct Bookmaker: Codable {
        let markets: [Market]
    }
    
    struct Market: Codable {
        let outcomes: [Outcome]
    }
    
    struct Outcome: Codable {
        let name: String
        let price: Double
        let point: Double?
    }
    
    // MARK: - Public Methods
    func fetchGames(for sport: String = "basketball_nba") async throws -> [Game] {
        let endpoint = "\(baseURL)/\(sport)/odds"
        let queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "regions", value: "us"),
            URLQueryItem(name: "markets", value: "spreads"),
            URLQueryItem(name: "oddsFormat", value: "american")
        ]
        
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw URLError(.badURL)
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        print("🌐 Fetching odds from URL: \(url)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OddsServiceError.invalidResponse
        }
        
        print("📡 API Response Status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw Response: \(responseString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let oddsResponse = try decoder.decode([OddsResponse].self, from: data)
        
        return oddsResponse.map { response in
            let spread = response.bookmakers.first?.markets.first?.outcomes
                .first(where: { $0.name == response.homeTeam })?.point ?? 0.0
            
            // Create the game with team colors
            let game = Game(
                id: response.id,
                homeTeam: response.homeTeam,
                awayTeam: response.awayTeam,
                time: response.commenceTime,
                league: "NBA", // We can enhance this later to support multiple leagues
                spread: spread,
                totalBets: 0, // This would come from your backend
                homeTeamColors: TeamColors.getTeamColors(response.homeTeam),
                awayTeamColors: TeamColors.getTeamColors(response.awayTeam)
            )
            return game
        }
    }
    
    // MARK: - Error Handling
    enum OddsServiceError: Error {
        case invalidResponse
        case apiError(String)
        case parsingError
        
        var localizedDescription: String {
            switch self {
            case .invalidResponse:
                return "Invalid response from the server"
            case .apiError(let message):
                return "API Error: \(message)"
            case .parsingError:
                return "Error parsing server response"
            }
        }
    }
}
