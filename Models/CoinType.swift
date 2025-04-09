// Updated version of Models/CoinType.swift
// Version: 2.0.0 - Changed to tournament-based coin system
// Updated: April 2025

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
    
    // Value is no longer relevant in tournament model
    var value: Double {
        return 0.0
    }
}

struct CoinBalance {
    let type: CoinType
    let amount: Int
    
    var formattedAmount: String {
        return "\(amount)"
    }
}
