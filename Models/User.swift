// Updated portions of Models/User.swift
// Version: 3.0.0 - Added subscription and tournament support
// Updated: April 2025

// Add these properties to the User struct
struct User: Codable, Identifiable {
    // Existing properties...
    
    // New properties for tournament system
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiryDate: Date?
    var weeklyCoins: Int
    var weeklyCoinsReset: Date
    var currentTournamentId: String?
    var tournamentStats: TournamentStats
    var loginStreak: Int
    var lastLoginDate: Date?
    
    // Add to CodingKeys enum...
    private enum CodingKeys: String, CodingKey {
        // Existing keys...
        case subscriptionStatus, subscriptionExpiryDate
        case weeklyCoins, weeklyCoinsReset
        case currentTournamentId, tournamentStats
        case loginStreak, lastLoginDate
    }
    
    // Update initialization...
    init(id: String, email: String, phoneNumber: String? = nil) {
        self.id = id
        self.email = email
        self.dateJoined = Date()
        self.weeklyCoins = 1000  // Starting tournament coins
        self.weeklyCoinsReset = Date().nextSunday()
        self.subscriptionStatus = .none
        self.subscriptionExpiryDate = nil
        self.tournamentStats = TournamentStats()
        self.loginStreak = 0
        self.lastLoginDate = Date()
        // Keep other existing properties...
    }
    
    // Add to toDictionary() method...
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            // Existing fields...
            "subscriptionStatus": subscriptionStatus.rawValue,
            "weeklyCoins": weeklyCoins,
            "weeklyCoinsReset": Timestamp(date: weeklyCoinsReset),
            "loginStreak": loginStreak
        ]
        
        if let subscriptionExpiryDate = subscriptionExpiryDate {
            dict["subscriptionExpiryDate"] = Timestamp(date: subscriptionExpiryDate)
        }
        
        if let lastLoginDate = lastLoginDate {
            dict["lastLoginDate"] = Timestamp(date: lastLoginDate)
        }
        
        if let currentTournamentId = currentTournamentId {
            dict["currentTournamentId"] = currentTournamentId
        }
        
        dict["tournamentStats"] = tournamentStats.toDictionary()
        
        return dict
    }
}

// New enums and structs for subscription
enum SubscriptionStatus: String, Codable {
    case none
    case active
    case expired
    case cancelled
}

struct TournamentStats: Codable {
    var tournamentsEntered: Int = 0
    var bestFinish: Int = 0
    var totalWinnings: Double = 0.0
    var lifetimeBets: Int = 0
    var lifetimeWins: Int = 0
    
    func toDictionary() -> [String: Any] {
        return [
            "tournamentsEntered": tournamentsEntered,
            "bestFinish": bestFinish,
            "totalWinnings": totalWinnings,
            "lifetimeBets": lifetimeBets,
            "lifetimeWins": lifetimeWins
        ]
    }
}

// Extension for Date to help with weekly resets
extension Date {
    func nextSunday() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        components.weekOfYear! += 1
        components.weekday = 1 // Sunday
        return calendar.date(from: components) ?? self.addingTimeInterval(7*24*60*60)
    }
}
