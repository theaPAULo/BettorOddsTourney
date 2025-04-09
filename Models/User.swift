//
//  User.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25.
//  Version: 3.0.0 - Added subscription and tournament support
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let email: String
    let dateJoined: Date
    var phoneNumber: String?
    
    // Authentication related
    var isEmailVerified: Bool
    var adminRole: AdminRole
    
    // Tournament related properties
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiryDate: Date?
    var weeklyCoins: Int // Tournament coins
    var weeklyCoinsReset: Date // When coins will reset
    var currentTournamentId: String?
    var tournamentStats: TournamentStats
    var loginStreak: Int
    var lastLoginDate: Date?
    var preferences: UserPreferences
    
    // MARK: - Enums
    enum AdminRole: String, Codable {
        case none
        case admin
        case moderator
    }
    
    // MARK: - Computed Properties
    
    // Check if tournament is active
    var isInActiveTournament: Bool {
        return currentTournamentId != nil && subscriptionStatus == .active
    }
    
    // Remaining time until coin reset
    var timeUntilCoinReset: TimeInterval {
        return weeklyCoinsReset.timeIntervalSince(Date())
    }
    
    // Format remaining time
    var formattedTimeUntilReset: String {
        let seconds = Int(timeUntilCoinReset)
        if seconds <= 0 {
            return "Reset pending"
        }
        
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            let minutes = (seconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, email, dateJoined, phoneNumber
        case isEmailVerified, adminRole
        case subscriptionStatus, subscriptionExpiryDate
        case weeklyCoins, weeklyCoinsReset
        case currentTournamentId, tournamentStats
        case loginStreak, lastLoginDate
        case preferences
    }
    
    // MARK: - Initialization
    init(id: String,
         email: String,
         phoneNumber: String? = nil) {
        self.id = id
        self.email = email
        self.phoneNumber = phoneNumber
        self.dateJoined = Date()
        self.isEmailVerified = false
        self.adminRole = .none
        self.weeklyCoins = 1000  // Starting tournament coins
        self.weeklyCoinsReset = Date().nextSunday()
        self.subscriptionStatus = .none
        self.subscriptionExpiryDate = nil
        self.tournamentStats = TournamentStats()
        self.loginStreak = 0
        self.lastLoginDate = Date()
        self.preferences = UserPreferences()
    }
    
    // MARK: - Firestore Initialization
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        // Required fields
        self.id = document.documentID
        self.email = data["email"] as? String ?? ""
        self.dateJoined = (data["dateJoined"] as? Timestamp)?.dateValue() ?? Date()
        
        // Optional fields
        self.phoneNumber = data["phoneNumber"] as? String
        
        // Auth fields
        self.isEmailVerified = data["isEmailVerified"] as? Bool ?? false
        
        if let adminRoleString = data["adminRole"] as? String,
           let adminRole = AdminRole(rawValue: adminRoleString) {
            self.adminRole = adminRole
        } else {
            self.adminRole = .none
        }
        
        // Subscription fields
        if let subscriptionStatusString = data["subscriptionStatus"] as? String,
           let subscriptionStatus = SubscriptionStatus(rawValue: subscriptionStatusString) {
            self.subscriptionStatus = subscriptionStatus
        } else {
            self.subscriptionStatus = .none
        }
        
        self.subscriptionExpiryDate = (data["subscriptionExpiryDate"] as? Timestamp)?.dateValue()
        
        // Tournament fields
        self.weeklyCoins = data["weeklyCoins"] as? Int ?? 1000
        self.weeklyCoinsReset = (data["weeklyCoinsReset"] as? Timestamp)?.dateValue() ?? Date().nextSunday()
        self.currentTournamentId = data["currentTournamentId"] as? String
        
        if let tournamentStatsData = data["tournamentStats"] as? [String: Any] {
            self.tournamentStats = TournamentStats(dictionary: tournamentStatsData)
        } else {
            self.tournamentStats = TournamentStats()
        }
        
        self.loginStreak = data["loginStreak"] as? Int ?? 0
        self.lastLoginDate = (data["lastLoginDate"] as? Timestamp)?.dateValue()
        
        // User preferences
        if let preferencesData = data["preferences"] as? [String: Any] {
            self.preferences = UserPreferences(dictionary: preferencesData)
        } else {
            self.preferences = UserPreferences()
        }
    }
    
    // MARK: - To Dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "dateJoined": Timestamp(date: dateJoined),
            "isEmailVerified": isEmailVerified,
            "adminRole": adminRole.rawValue,
            "subscriptionStatus": subscriptionStatus.rawValue,
            "weeklyCoins": weeklyCoins,
            "weeklyCoinsReset": Timestamp(date: weeklyCoinsReset),
            "loginStreak": loginStreak,
            "tournamentStats": tournamentStats.toDictionary(),
            "preferences": preferences.toDictionary()
        ]
        
        // Optional fields
        if let phoneNumber = phoneNumber {
            dict["phoneNumber"] = phoneNumber
        }
        
        if let subscriptionExpiryDate = subscriptionExpiryDate {
            dict["subscriptionExpiryDate"] = Timestamp(date: subscriptionExpiryDate)
        }
        
        if let currentTournamentId = currentTournamentId {
            dict["currentTournamentId"] = currentTournamentId
        }
        
        if let lastLoginDate = lastLoginDate {
            dict["lastLoginDate"] = Timestamp(date: lastLoginDate)
        }
        
        return dict
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var useBiometrics: Bool = false
    var darkMode: Bool = false
    var notificationsEnabled: Bool = true
    var requireBiometricsForGreenCoins: Bool = true
    var saveCredentials: Bool = true
    var rememberMe: Bool = false
    
    // Initialize from Firestore dictionary
    init(dictionary: [String: Any] = [:]) {
        self.useBiometrics = dictionary["useBiometrics"] as? Bool ?? false
        self.darkMode = dictionary["darkMode"] as? Bool ?? false
        self.notificationsEnabled = dictionary["notificationsEnabled"] as? Bool ?? true
        self.requireBiometricsForGreenCoins = dictionary["requireBiometricsForGreenCoins"] as? Bool ?? true
        self.saveCredentials = dictionary["saveCredentials"] as? Bool ?? true
        self.rememberMe = dictionary["rememberMe"] as? Bool ?? false
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "useBiometrics": useBiometrics,
            "darkMode": darkMode,
            "notificationsEnabled": notificationsEnabled,
            "requireBiometricsForGreenCoins": requireBiometricsForGreenCoins,
            "saveCredentials": saveCredentials,
            "rememberMe": rememberMe
        ]
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: String, Codable {
    case none
    case active
    case expired
    case cancelled
    
    var isSubscribed: Bool {
        return self == .active
    }
}

// MARK: - Tournament Stats
struct TournamentStats: Codable {
    var tournamentsEntered: Int = 0
    var bestFinish: Int = 0
    var totalWinnings: Double = 0.0
    var lifetimeBets: Int = 0
    var lifetimeWins: Int = 0
    
    init() {
        self.tournamentsEntered = 0
        self.bestFinish = 0
        self.totalWinnings = 0.0
        self.lifetimeBets = 0
        self.lifetimeWins = 0
    }
    
    // Initialize from Firestore dictionary
    init(dictionary: [String: Any]) {
        self.tournamentsEntered = dictionary["tournamentsEntered"] as? Int ?? 0
        self.bestFinish = dictionary["bestFinish"] as? Int ?? 0
        self.totalWinnings = dictionary["totalWinnings"] as? Double ?? 0.0
        self.lifetimeBets = dictionary["lifetimeBets"] as? Int ?? 0
        self.lifetimeWins = dictionary["lifetimeWins"] as? Int ?? 0
    }
    
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
