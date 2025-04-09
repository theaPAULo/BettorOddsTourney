//
//  CoinType.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//  Version: 3.0.0 - Converted to tournament-based coin system
//

import Foundation

enum CoinType: String, Codable {
    case tournament // Single tournament coin type replacing yellow/green
    
    var displayName: String {
        return "Tournament Coins"
    }
    
    var emoji: String {
        return "🏆"
    }
    
    var isRealMoney: Bool {
        return false // Coins represent tournament entry, not direct money
    }
    
    // Value is no longer relevant in tournament model but kept for backward compatibility
    var value: Double {
        return 0.0
    }
}

// Additional models for coin balance display
struct CoinBalance {
    let type: CoinType
    let amount: Int
    
    var formattedAmount: String {
        return "\(amount)"
    }
}

// Daily bonus tracking
struct DailyBonus {
    let day: Int
    let amount: Int
    var claimed: Bool = false
    
    // Daily bonus increases with consecutive logins
    static func bonusForDay(_ day: Int) -> Int {
        switch day {
        case 1:
            return 10 // Day 1 bonus
        case 2:
            return 15 // Day 2 bonus
        case 3:
            return 20 // Day 3 bonus
        case 4:
            return 25 // Day 4 bonus
        case 5:
            return 30 // Day 5 bonus
        case 6:
            return 40 // Day 6 bonus
        case 7:
            return 60 // Day 7 (full week) bonus
        default:
            return day >= 8 ? 75 : 10 // 75 coins for 8+ day streak
        }
    }
}
