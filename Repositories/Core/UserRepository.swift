//
//  UserRepository.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Updated by Paul Soni on 4/9/25 for tournament system
//  Version: 3.0.0 - Modified for tournament-based betting
//

import Foundation
import FirebaseFirestore

class UserRepository: Repository {
    // MARK: - Properties
    typealias T = User
    
    let cacheFilename = "users.cache"
    let cacheExpiryTime: TimeInterval = 3600 // 1 hour
    private let userService: UserService
    private let tournamentService = TournamentService.shared
    
    // Cache container
    private var cachedUsers: [String: User] = [:]
    
    // MARK: - Initialization
    init() {
        self.userService = UserService()
        loadCachedUsers()
    }
    
    // MARK: - Repository Protocol Methods
    
    func fetch(id: String) async throws -> User? {
        // Try cache first
        if let cachedUser = cachedUsers[id], isCacheValid() {
            return cachedUser
        }
        
        // If not in cache or cache expired, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        do {
            let user = try await userService.fetchUser(userId: id)
            
            // Save to cache
            cachedUsers[id] = user
            try saveCachedUsers()
            
            return user
        } catch {
            // If not found, return nil instead of throwing
            if case DatabaseError.documentNotFound = error {
                return nil
            }
            throw error
        }
    }
    
    /// Saves a user
    /// - Parameter user: The user to save
    func save(_ user: User) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Save to network
        let savedUser = try await userService.updateUser(user)
        
        // Update cache
        cachedUsers[user.id] = savedUser
        try saveCachedUsers()
    }
    
    /// Removes a user
    /// - Parameter id: The user's ID
    func remove(id: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Remove from network
        try await userService.deleteUser(userId: id)
        
        // Remove from cache
        cachedUsers.removeValue(forKey: id)
        try saveCachedUsers()
    }
    
    /// Clears the user cache
    func clearCache() throws {
        cachedUsers.removeAll()
        try saveCachedUsers()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedUsers() {
        do {
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<User>.self, from: data)
            cachedUsers = container.items
        } catch {
            cachedUsers = [:]
        }
    }
    
    private func saveCachedUsers() throws {
        let container = CacheContainer(items: cachedUsers)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
    }
    
    // MARK: - Subscription Methods
    
    /// Subscribes a user to the tournament system
    /// - Parameter userId: The user's ID
    /// - Returns: Updated user
    func subscribeUser(userId: String) async throws -> User {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Get the current user
        guard var user = try await fetch(id: userId) else {
            throw RepositoryError.itemNotFound
        }
        
        // Update subscription status
        user.subscriptionStatus = .active
        user.subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        
        // Register for tournament if available
        if let tournament = try await tournamentService.fetchActiveTournament() {
            try await tournamentService.registerForTournament(
                userId: userId,
                tournamentId: tournament.id
            )
            
            // Update user's tournament ID
            user.currentTournamentId = tournament.id
        }
        
        // Save updated user
        try await save(user)
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
        
        // Return updated user
        return try await fetch(id: userId) ?? user
    }
    
    /// Cancels a user's subscription
    /// - Parameter userId: The user's ID
    /// - Returns: Updated user
    func cancelSubscription(userId: String) async throws -> User {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Get the current user
        guard var user = try await fetch(id: userId) else {
            throw RepositoryError.itemNotFound
        }
        
        // Update subscription status
        user.subscriptionStatus = .cancelled
        
        // Save updated user
        try await save(user)
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
        
        // Return updated user
        return try await fetch(id: userId) ?? user
    }
    
    // MARK: - Tournament Methods
    
    /// Updates tournament coins for a user
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: Amount to change (positive for increase, negative for decrease)
    /// - Returns: Updated weekly coins balance
    func updateTournamentCoins(userId: String, amount: Int) async throws -> Int {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Get the current user
        guard var user = try await fetch(id: userId) else {
            throw RepositoryError.itemNotFound
        }
        
        // Update coins
        user.weeklyCoins += amount
        
        // Ensure coins don't go negative
        if user.weeklyCoins < 0 {
            user.weeklyCoins = 0
        }
        
        // Save updated user
        try await save(user)
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
        
        // Return new balance
        return user.weeklyCoins
    }
    
    /// Claims a daily login bonus
    /// - Parameter userId: The user's ID
    /// - Returns: Bonus amount and updated user
    func claimDailyBonus(userId: String) async throws -> (bonusAmount: Int, user: User) {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Get the current user
        guard var user = try await fetch(id: userId) else {
            throw RepositoryError.itemNotFound
        }
        
        // Check if user is in an active tournament
        guard let tournamentId = user.currentTournamentId else {
            throw RepositoryError.operationNotSupported
        }
        
        // Calculate streak
        let loginStreak = calculateLoginStreak(user: user)
        user.loginStreak = loginStreak
        user.lastLoginDate = Date()
        
        // Calculate bonus amount
        let bonusAmount = DailyBonus.bonusForDay(loginStreak)
        
        // Use tournament service to claim bonus
        try await tournamentService.claimDailyBonus(
            userId: userId,
            tournamentId: tournamentId
        )
        
        // Save updated user
        try await save(user)
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
        
        // Return bonus amount and updated user
        return (bonusAmount, user)
    }
    
    /// Resets weekly tournament coins
    /// - Parameter userId: The user's ID
    /// - Returns: Updated user
    func resetWeeklyCoins(userId: String) async throws -> User {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Get the current user
        guard var user = try await fetch(id: userId) else {
            throw RepositoryError.itemNotFound
        }
        
        // Reset coins and set next reset date
        user.weeklyCoins = 1000
        user.weeklyCoinsReset = Date().nextSunday()
        
        // Save updated user
        try await save(user)
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
        
        // Return updated user
        return user
    }
    
    // MARK: - Other Account Methods
    
    /// Updates user preferences
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - preferences: New preferences
    func updatePreferences(userId: String, preferences: UserPreferences) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Get the current user
        guard var user = try await fetch(id: userId) else {
            throw RepositoryError.itemNotFound
        }
        
        // Update preferences
        user.preferences = preferences
        
        // Save updated user
        try await save(user)
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
    }
    
    // MARK: - Helper Methods
    
    /// Calculates login streak based on last login date
    private func calculateLoginStreak(user: User) -> Int {
        guard let lastLoginDate = user.lastLoginDate else {
            return 1 // First login
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check if last login was yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        if calendar.isDate(lastLoginDate, inSameDayAs: yesterday) {
            // Consecutive login
            return user.loginStreak + 1
        }
        
        // Check if login was today already
        if calendar.isDate(lastLoginDate, inSameDayAs: now) {
            // Maintain current streak
            return user.loginStreak
        }
        
        // Streak broken
        return 1
    }
}
