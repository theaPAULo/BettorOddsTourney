//
//  Configuration.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//


//
//  Configuration.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import Foundation

/// Configuration management for the app
enum Configuration {
    /// API Keys and Endpoints
    enum API {
        static let oddsAPIKey = "aec5b19b654411a05206d9d67dfb7764"  // Replace with your actual API key
        static let oddsAPIBaseURL = "https://api.the-odds-api.com/v4/sports"
    }
    
    /// Feature Flags
    enum Features {
        static let useRealOdds = true
        static let enableBiometrics = true
        static let autoRefreshInterval: TimeInterval = 300 // 5 minutes
    }
    
    /// App Settings
    enum Settings {
        static let maxDailyBetAmount = 100.0
        static let warningThreshold = 0.8 // 80% of daily limit
        static let autoLogoutInterval: TimeInterval = 1800 // 30 minutes
    }
}
