//
//  Game.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 2.0.0
//

import SwiftUI
import FirebaseFirestore

struct Game: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let homeTeam: String
    let awayTeam: String
    let time: Date
    let league: String
    let spread: Double
    let totalBets: Int
    let homeTeamColors: TeamColors
    let awayTeamColors: TeamColors
    var isFeatured: Bool
    var isVisible: Bool
    var isLocked: Bool
    var lastUpdatedBy: String?
    var lastUpdatedAt: Date?
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, homeTeam, awayTeam, time, league, spread, totalBets
        case homeTeamColors, awayTeamColors, isFeatured, isVisible, isLocked
        case lastUpdatedBy, lastUpdatedAt
    }
    
    // MARK: - Computed Properties
    var sortPriority: Int {
        if isFinished { return 2 }  // Put finished games last
        if isLocked { return 1 }    // Put locked games second
        return 0                    // Put active games first
    }
    
    var isFinished: Bool {
        return time < Date()
    }
    
    var homeSpread: String {
        let value = spread
        return value >= 0 ? "+\(String(format: "%.1f", value))" : String(format: "%.1f", value)
    }
    
    var awaySpread: String {
        let value = -spread
        return value >= 0 ? "+\(String(format: "%.1f", value))" : String(format: "%.1f", value)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    // MARK: - Initialization
    init(id: String,
         homeTeam: String,
         awayTeam: String,
         time: Date,
         league: String,
         spread: Double,
         totalBets: Int,
         homeTeamColors: TeamColors,
         awayTeamColors: TeamColors,
         isFeatured: Bool = false,
         isVisible: Bool = true,
         isLocked: Bool = false,
         lastUpdatedBy: String? = nil,
         lastUpdatedAt: Date? = nil) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.time = time
        self.league = league
        self.spread = spread
        self.totalBets = totalBets
        self.homeTeamColors = homeTeamColors
        self.awayTeamColors = awayTeamColors
        self.isFeatured = isFeatured
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.lastUpdatedBy = lastUpdatedBy
        self.lastUpdatedAt = lastUpdatedAt
    }
    
    // MARK: - Sample Data
    static var sampleGames: [Game] = [
        Game(
            id: "1",
            homeTeam: "Orlando Magic",
            awayTeam: "Portland Trail Blazers",
            time: Calendar.current.date(bySettingHour: 18, minute: 10, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: 6.5,  // Magic favored by 6.5
            totalBets: 1500,
            homeTeamColors: TeamColors.getTeamColors("Magic"),
            awayTeamColors: TeamColors.getTeamColors("Trail Blazers")
        ),
        Game(
            id: "2",
            homeTeam: "Atlanta Hawks",
            awayTeam: "Toronto Raptors",
            time: Calendar.current.date(bySettingHour: 18, minute: 40, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: 5.0,  // Hawks favored by 5
            totalBets: 2000,
            homeTeamColors: TeamColors.getTeamColors("Hawks"),
            awayTeamColors: TeamColors.getTeamColors("Raptors")
        )
    ]
    
    // MARK: - Firestore Conversion
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.homeTeam = data["homeTeam"] as? String ?? ""
        self.awayTeam = data["awayTeam"] as? String ?? ""
        self.time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
        self.league = data["league"] as? String ?? ""
        self.spread = data["spread"] as? Double ?? 0.0
        self.totalBets = data["totalBets"] as? Int ?? 0
        self.isFeatured = data["isFeatured"] as? Bool ?? false
        self.isVisible = data["isVisible"] as? Bool ?? true
        self.isLocked = data["isLocked"] as? Bool ?? false
        self.lastUpdatedBy = data["lastUpdatedBy"] as? String
        self.lastUpdatedAt = (data["lastUpdatedAt"] as? Timestamp)?.dateValue()
        
        // Parse team colors
        if let homeColors = data["homeTeamColors"] as? [String: Any] {
            self.homeTeamColors = TeamColors.getTeamColors(self.homeTeam)
        } else {
            self.homeTeamColors = TeamColors.getTeamColors(self.homeTeam)
        }
        
        if let awayColors = data["awayTeamColors"] as? [String: Any] {
            self.awayTeamColors = TeamColors.getTeamColors(self.awayTeam)
        } else {
            self.awayTeamColors = TeamColors.getTeamColors(self.awayTeam)
        }
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "homeTeam": homeTeam,
            "awayTeam": awayTeam,
            "time": Timestamp(date: time),
            "league": league,
            "spread": spread,
            "totalBets": totalBets,
            "isFeatured": isFeatured,
            "isVisible": isVisible,
            "isLocked": isLocked
        ]
        
        if let lastUpdatedBy = lastUpdatedBy {
            dict["lastUpdatedBy"] = lastUpdatedBy
        }
        
        if let lastUpdatedAt = lastUpdatedAt {
            dict["lastUpdatedAt"] = Timestamp(date: lastUpdatedAt)
        }
        
        return dict
    }
}

// MARK: - Game Sorting
extension Array where Element == Game {
    func sortedByPriority() -> [Game] {
        self.sorted { game1, game2 in
            if game1.sortPriority != game2.sortPriority {
                return game1.sortPriority < game2.sortPriority
            }
            return game1.time < game2.time
        }
    }
}
