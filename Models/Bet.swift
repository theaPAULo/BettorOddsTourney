// Updated version of Models/Bet.swift
// Version: 3.0.0 - Modified for tournament system
// Updated: April 2025

import SwiftUI
import FirebaseFirestore

// MARK: - Bet Status Enum
enum BetStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case partiallyMatched = "Partially Matched" // Keep for backward compatibility
    case fullyMatched = "Matched"      // Keep for backward compatibility
    case active = "Active"             // Game in progress
    case cancelled = "Cancelled"
    case won = "Won"
    case lost = "Lost"
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .partiallyMatched:
            return .yellow
        case .fullyMatched, .active:
            return .blue
        case .cancelled:
            return .gray
        case .won:
            return .green
        case .lost:
            return .red
        }
    }
}

// MARK: - Bet Model
struct Bet: Identifiable, Codable {
    let id: String
    let userId: String
    let gameId: String
    let tournamentId: String      // New field to track tournament
    let amount: Int
    let initialSpread: Double
    let currentSpread: Double
    var status: BetStatus
    let createdAt: Date
    var updatedAt: Date
    let team: String
    let isHomeTeam: Bool
    
    // Add tournament ranking impact
    var rankingImpact: Int?       // How this bet affected user's ranking
    
    // MARK: - Computed Properties
    
    /// Emoji for the tournament coins
    var coinEmoji: String {
        return "🏆"
    }
    
    /// Calculates potential winnings based on bet amount
    var potentialWinnings: Int {
        // Even odds: Bet 100 to win 100
        return amount
    }
    
    /// Checks if spread has changed enough to trigger warning
    var spreadHasChangedSignificantly: Bool {
        return abs(currentSpread - initialSpread) >= 1.0
    }
    
    /// Checks if bet can be cancelled (only pending or partially matched bets)
    var canBeCancelled: Bool {
        return status == .pending || status == .partiallyMatched
    }
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         userId: String,
         gameId: String,
         tournamentId: String,
         amount: Int,
         initialSpread: Double,
         team: String,
         isHomeTeam: Bool) {
        self.id = id
        self.userId = userId
        self.gameId = gameId
        self.tournamentId = tournamentId
        self.amount = amount
        self.initialSpread = initialSpread
        self.currentSpread = initialSpread
        self.status = .pending
        self.createdAt = Date()
        self.updatedAt = Date()
        self.team = team
        self.isHomeTeam = isHomeTeam
        self.rankingImpact = nil
    }
    
    // MARK: - Firestore Conversion
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.userId = data["userId"] as? String ?? ""
        self.gameId = data["gameId"] as? String ?? ""
        self.tournamentId = data["tournamentId"] as? String ?? ""
        self.amount = data["amount"] as? Int ?? 0
        self.initialSpread = data["initialSpread"] as? Double ?? 0.0
        self.currentSpread = data["currentSpread"] as? Double ?? 0.0
        self.team = data["team"] as? String ?? ""
        self.isHomeTeam = data["isHomeTeam"] as? Bool ?? false
        self.rankingImpact = data["rankingImpact"] as? Int
        
        if let statusString = data["status"] as? String,
           let status = BetStatus(rawValue: statusString) {
            self.status = status
        } else {
            self.status = .pending
        }
        
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "gameId": gameId,
            "tournamentId": tournamentId,
            "amount": amount,
            "initialSpread": initialSpread,
            "currentSpread": currentSpread,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "team": team,
            "isHomeTeam": isHomeTeam
        ]
        
        if let rankingImpact = rankingImpact {
            dict["rankingImpact"] = rankingImpact
        }
        
        return dict
    }
}
