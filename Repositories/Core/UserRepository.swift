// Repositories/Core/UserRepository.swift
// Version: 1.0.0
// Created: April 10, 2025
// Description: Repository to handle user data operations

import Foundation
import Firebase
import FirebaseFirestore

class UserRepository {
    // MARK: - Properties
    private let userService = UserService.shared
    private let dataInitService = DataInitializationService.shared
    
    // MARK: - CRUD Operations
    
    /// Fetches current user and performs maintenance checks
    func fetchCurrentUser(userId: String) async throws -> User? {
        guard let user = try await userService.fetchUser(id: userId) else {
            return nil
        }
        
        // Perform maintenance checks
        try await dataInitService.checkWeeklyCoinReset(for: user)
        try await dataInitService.checkSubscriptionStatus(for: user)
        try await userService.updateLoginStreak(for: user)
        
        // Fetch fresh user data after updates
        return try await userService.fetchUser(id: userId)
    }
    
    /// Saves a user
    func save(_ user: User) async throws {
        try await userService.saveUser(user)
    }
    
    /// Updates user preferences
    func updatePreferences(for userId: String, preferences: UserPreferences) async throws {
        try await userService.updatePreferences(for: userId, preferences: preferences)
    }
    
    /// Resets a user's weekly coins
    func resetWeeklyCoins(userId: String) async throws {
        try await userService.resetWeeklyCoins(for: userId)
    }
    
    /// Updates a user's tournament coins
    func updateTournamentCoins(userId: String, amount: Int) async throws {
        // Get current user data
        guard let user = try await userService.fetchUser(id: userId) else {
            throw NSError(domain: "UserRepository", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        // Calculate new coin amount
        let newAmount = user.weeklyCoins + amount
        
        // Update coins in user document
        try await userService.updateUser(id: userId, fields: ["weeklyCoins": newAmount])
    }
    
    /// Subscribes a user to the premium service
    func subscribeUser(userId: String) async throws {
        // Set subscription to active with one month expiry
        let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        try await userService.updateSubscription(for: userId, status: SubscriptionStatus.active, expiryDate: expiryDate)
    }
    
    /// Cancels a user's subscription
    func cancelSubscription(userId: String) async throws {
        // Set subscription status to cancelled but maintain existing expiry date
        guard let user = try await userService.fetchUser(id: userId) else {
            throw NSError(domain: "UserRepository", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        try await userService.updateSubscription(for: userId, status: SubscriptionStatus.cancelled, expiryDate: user.subscriptionExpiryDate)
    }
}
