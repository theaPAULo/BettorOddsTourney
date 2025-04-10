// Services/Core/UserService.swift
// Version: 1.0.0
// Created: April 10, 2025
// Description: Service to handle user data operations with Firestore

import Foundation
import Firebase
import FirebaseFirestore

class UserService {
    // MARK: - Singleton
    static let shared = UserService()
    
    // MARK: - Properties
    private let db = FirebaseConfig.shared.db
    private let usersCollection = FirebaseConfig.shared.usersCollection
    
    // MARK: - CRUD Operations
    
    /// Fetches a user by ID
    func fetchUser(id: String) async throws -> User? {
        let snapshot = try await usersCollection.document(id).getDocument()
        return User(document: snapshot)
    }
    
    /// Saves a user to Firestore
    func saveUser(_ user: User) async throws {
        try await usersCollection.document(user.id).setData(user.toDictionary())
    }
    
    /// Updates specific fields for a user
    func updateUser(id: String, fields: [String: Any]) async throws {
        try await usersCollection.document(id).updateData(fields)
    }
    
    /// Processes login streak update
    func updateLoginStreak(for user: User) async throws {
        guard let lastLoginDate = user.lastLoginDate else {
            // First login, set streak to 1
            try await updateUser(id: user.id, fields: [
                "loginStreak": 1,
                "lastLoginDate": Timestamp(date: Date())
            ])
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check if last login was yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
            let lastLoginDay = calendar.startOfDay(for: lastLoginDate)
            let yesterdayDay = calendar.startOfDay(for: yesterday)
            
            if calendar.isDate(lastLoginDay, inSameDayAs: yesterdayDay) {
                // Increment streak
                try await updateUser(id: user.id, fields: [
                    "loginStreak": user.loginStreak + 1,
                    "lastLoginDate": Timestamp(date: Date())
                ])
            } else if !calendar.isDateInToday(lastLoginDay) {
                // Reset streak if not yesterday and not today
                try await updateUser(id: user.id, fields: [
                    "loginStreak": 1,
                    "lastLoginDate": Timestamp(date: Date())
                ])
            } else {
                // Already logged in today, just update timestamp
                try await updateUser(id: user.id, fields: [
                    "lastLoginDate": Timestamp(date: Date())
                ])
            }
        }
    }
    
    /// Updates user preferences
    func updatePreferences(for userId: String, preferences: UserPreferences) async throws {
        try await updateUser(id: userId, fields: [
            "preferences": preferences.toDictionary()
        ])
    }
    
    /// Updates subscription status
    func updateSubscription(for userId: String, status: SubscriptionStatus, expiryDate: Date?) async throws {
        var fields: [String: Any] = ["subscriptionStatus": status.rawValue]
        
        if let expiryDate = expiryDate {
            fields["subscriptionExpiryDate"] = Timestamp(date: expiryDate)
        }
        
        try await updateUser(id: userId, fields: fields)
    }
    
    /// Resets weekly coins
    func resetWeeklyCoins(for userId: String) async throws {
        let nextReset = Date().nextSunday()
        
        try await updateUser(id: userId, fields: [
            "weeklyCoins": 1000,
            "weeklyCoinsReset": Timestamp(date: nextReset)
        ])
    }
}
