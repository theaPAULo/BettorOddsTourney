//
//  Tournament.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/8/25.
//


// New file: Models/Tournament.swift
// Version: 1.0.0
// Created: April 2025

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
    
    // MARK: - Computed Properties
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         startDate: Date,
         endDate: Date,
         status: TournamentStatus = .upcoming,
         participantCount: Int = 0,
         totalPrizePool: Double = 0.0,
         payoutStructure: [PayoutTier] = []) {
        self.id = id
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
}

struct PayoutTier: Codable {
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
    let rank: Int
    let coinsRemaining: Int
    let coinsBet: Int
    let coinsWon: Int
    let betsPlaced: Int
    let betsWon: Int
    
    // Performance metrics
    var winPercentage: Double {
        return betsPlaced > 0 ? Double(betsWon) / Double(betsPlaced) * 100 : 0
    }
    
    var roi: Double {
        return coinsBet > 0 ? (Double(coinsWon) / Double(coinsBet) - 1) * 100 : 0
    }
}