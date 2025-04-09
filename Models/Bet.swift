//
//  Bet.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import SwiftUI
import FirebaseFirestore

// MARK: - Bet Status Enum
enum BetStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case active = "Active"             // Game in progress
    case cancelled = "Cancelled"
    case won = "Won"
    case lost = "Lost"
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .active:
            return .blue
        case .cancelled:
            return .gray
        case .won:
            return .green
        case .lost:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .active:
            return "play.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .won:
            return "checkmark.circle.fill"
        case .lost:
            return "multiply.circle.fill"
        }
    }
}

// MARK: - Bet Model
struct Bet: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let userId: String
    let gameId: String
    let tournamentId: String      // Tournament this bet belongs to
    let amount: Int
    let initialSpread: Double
    let currentSpread: Double
    var status: BetStatus
    let createdAt: Date
    var updatedAt: Date
    let team: String
    let isHomeTeam: Bool
    
    // Tournament impact and stats tracking
    var rankingImpact: Int?       // How this bet affected user's ranking
    var betType: BetType          // Type of bet placed
    
    // MARK: - Computed Properties
    
    /// Emoji for the tournament coins
    var coinEmoji: String {
        return "🏆"
    }
    
    /// Calculates potential winnings based on bet amount and type
    var potentialWinnings: Int {
        switch betType {
        case .spread:
            return amount // Even money for spread bets
        case .moneyline:
            // This would calculate based on odds but simplified for now
            return Int(Double(amount) * 0.9)
        case .overUnder:
            return amount // Even money for over/under
        }
    }
    
    /// Checks if spread has changed enough to trigger warning
    var spreadHasChangedSignificantly: Bool {
        return abs(currentSpread - initialSpread) >= 1.0
    }
    
    /// Checks if bet can be cancelled (only pending bets)
    var canBeCancelled: Bool {
        return status == .pending
    }
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         userId: String,
         gameId: String,
         tournamentId: String,
         amount: Int,
         initialSpread: Double,
         team: String,
         isHomeTeam: Bool,
         betType: BetType = .spread) {
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
        self.betType = betType
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
        
        if let betTypeString = data["betType"] as? String,
           let betType = BetType(rawValue: betTypeString) {
            self.betType = betType
        } else {
            self.betType = .spread
        }
        
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
            "isHomeTeam": isHomeTeam,
            "betType": betType.rawValue
        ]
        
        if let rankingImpact = rankingImpact {
            dict["rankingImpact"] = rankingImpact
        }
        
        return dict
    }
}

// MARK: - Bet Type Enum
enum BetType: String, Codable {
    case spread = "Spread"           // Point spread betting
    case moneyline = "Moneyline"     // Straight-up win/lose
    case overUnder = "Over/Under"    // Total points over/under
    
    var description: String {
        switch self {
        case .spread:
            return "Point Spread"
        case .moneyline:
            return "Moneyline"
        case .overUnder:
            return "Over/Under"
        }
    }
}
