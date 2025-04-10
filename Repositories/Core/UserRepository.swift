// Repositories/UserRepository.swift
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
}
