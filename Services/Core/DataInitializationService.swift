//
//  DataInitializationService.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/10/25.
//


// Services/Core/DataInitializationService.swift
// Version: 1.0.0
// Created: April 10, 2025
// Description: Service to handle data initialization and maintenance

import Foundation
import Firebase
import FirebaseFirestore

class DataInitializationService {
    // MARK: - Singleton
    static let shared = DataInitializationService()
    
    // MARK: - Properties
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Initialization Methods
    
    /// Initializes app settings if they don't exist
    func initializeSettings() async throws {
        let settingsRef = FirebaseConfig.shared.settingsCollection.document("global")
        let snapshot = try await settingsRef.getDocument()
        
        if !snapshot.exists {
            // Create default settings
            try await settingsRef.setData([
                "activeTournamentId": "", // No active tournament by default
                "tournamentStartDate": nil,
                "tournamentEndDate": nil,
                "appVersion": "1.0.0",
                "maintenanceMode": false,
                "minRequiredVersion": "1.0.0",
                "notificationsEnabled": true,
                "lastUpdated": Timestamp(date: Date())
            ])
            
            print("✅ Initialized default settings")
        }
    }
    
    /// Checks if user's weekly coins need to be reset
    func checkWeeklyCoinReset(for user: User) async throws {
        let now = Date()
        
        if now > user.weeklyCoinsReset {
            // Time to reset coins
            try await UserService.shared.resetWeeklyCoins(for: user.id)
            print("✅ Reset weekly coins for user \(user.id)")
        }
    }
    
    /// Checks if user's subscription has expired
    func checkSubscriptionStatus(for user: User) async throws {
        guard user.subscriptionStatus == .active,
              let expiryDate = user.subscriptionExpiryDate else {
            return
        }
        
        let now = Date()
        
        if now > expiryDate {
            // Subscription expired
            try await UserService.shared.updateSubscription(
                for: user.id,
                status: .expired,
                expiryDate: nil
            )
            print("⚠️ User \(user.id) subscription expired")
        }
    }
}