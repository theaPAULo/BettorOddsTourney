//
//  Tournament.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//  Version: 1.0.0 - Initial tournament model implementation
//

import Foundation
import FirebaseFirestore

struct Tournament: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let startDate: Date
    let endDate: Date
    let status: TournamentStatus
    var participantCount: Int
    var totalPrizePool: Double
    var payoutStructure: [PayoutTier]
    var name: String // Added for tournament naming
    
    // MARK: - Computed Properties
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && status == .active
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    var isEnded: Bool {
        return Date() > endDate || status == .completed
    }
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         name: String = "Weekly Tournament",
         startDate: Date,
         endDate: Date,
         status: TournamentStatus = .upcoming,
         participantCount: Int = 0,
         totalPrizePool: Double = 0.0,
         payoutStructure: [PayoutTier] = []) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.participantCount = participantCount
        self.totalPrizePool = totalPrizePool
        self.payoutStructure = payoutStructure
    }
    
    // MARK: - Firestore Conversion
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.name = data["name"] as? String ?? "Weekly Tournament"
        self.participantCount = data["participantCount"] as? Int ?? 0
        self.totalPrizePool = data["totalPrizePool"] as? Double ?? 0.0
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        self.endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
        
        if let statusString = data["status"] as? String,
           let status = TournamentStatus(rawValue: statusString) {
            self.status = status
        } else {
            self.status = .upcoming
        }
        
        if let payoutData = data["payoutStructure"] as? [[String: Any]] {
            self.payoutStructure = payoutData.compactMap { dict in
                guard let rank = dict["rank"] as? Int,
                      let percentOfPool = dict["percentOfPool"] as? Double else {
                    return nil
                }
                return PayoutTier(rank: rank, percentOfPool: percentOfPool)
            }
        } else {
            self.payoutStructure = []
        }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "status": status.rawValue,
            "participantCount": participantCount,
            "totalPrizePool": totalPrizePool,
            "payoutStructure": payoutStructure.map { tier in
                return [
                    "rank": tier.rank,
                    "percentOfPool": tier.percentOfPool
                ]
            }
        ]
    }
    
    // MARK: - Helper Methods
    
    /// Calculate potential winnings for a specific rank
    func winningsForRank(_ rank: Int) -> Double {
        guard let tier = payoutStructure.first(where: { $0.rank == rank }) else {
            return 0.0
        }
        
        return totalPrizePool * tier.percentOfPool
    }
    
    /// Determine if a rank is in the money (wins prize)
    func isPayingRank(_ rank: Int) -> Bool {
        return payoutStructure.contains(where: { $0.rank == rank })
    }
}

// MARK: - Supporting Types
enum TournamentStatus: String, Codable {
    case upcoming
    case active
    case completed
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming: return .blue
        case .active: return .green
        case .completed: return .gray
        }
    }
}

struct PayoutTier: Codable, Identifiable {
    var id: String { "\(rank)" } // Computed ID for SwiftUI list identification
    let rank: Int
    let percentOfPool: Double
    
    var formattedPercent: String {
        return String(format: "%.1f%%", percentOfPool * 100)
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let tournamentId: String
    let username: String
    var rank: Int
    var coinsRemaining: Int
    var coinsBet: Int
    var coinsWon: Int
    var betsPlaced: Int
    var betsWon: Int
    var avatarURL: String? // Optional profile picture
    
    // Performance metrics
    var winPercentage: Double {
        return betsPlaced > 0 ? Double(betsWon) / Double(betsPlaced) * 100 : 0
    }
    
    var roi: Double {
        return coinsBet > 0 ? (Double(coinsWon) / Double(coinsBet) - 1) * 100 : 0
    }
    
    // Total coins (for ranking)
    var totalCoins: Int {
        return coinsRemaining + coinsWon
    }
    
    // Format for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "tournamentId": tournamentId,
            "username": username,
            "rank": rank,
            "coinsRemaining": coinsRemaining,
            "coinsBet": coinsBet,
            "coinsWon": coinsWon,
            "betsPlaced": betsPlaced,
            "betsWon": betsWon
        ]
        
        if let avatarURL = avatarURL {
            dict["avatarURL"] = avatarURL
        }
        
        return dict
    }
}

// Add Color import at the top
import SwiftUI
