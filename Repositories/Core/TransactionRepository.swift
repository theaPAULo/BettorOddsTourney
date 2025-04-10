//
//  TransactionRepository.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import Foundation
import FirebaseFirestore

class TransactionRepository: Repository {
    // MARK: - Properties
    typealias T = Transaction
    
    let cacheFilename = "transactions.cache"
    let cacheExpiryTime: TimeInterval = 3600 // 1 hour
    private var cachedTransactions: [String: Transaction] = [:]
    
    // MARK: - Initialization
    init() {
        loadCachedTransactions()
    }
    
    // MARK: - Repository Protocol Methods
    
    func fetch(id: String) async throws -> Transaction? {
        // Try cache first
        if let cachedTransaction = cachedTransactions[id], isCacheValid() {
            return cachedTransaction
        }
        
        // If not in cache or cache invalid, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        do {
            let document = try await FirebaseConfig.shared.db.collection("transactions").document(id).getDocument()
            
            guard let transaction = Transaction(document: document) else {
                throw RepositoryError.itemNotFound
            }
            
            // Save to cache
            cachedTransactions[id] = transaction
            try saveCachedTransactions()
            
            return transaction
        } catch {
            if case RepositoryError.itemNotFound = error {
                return nil
            }
            throw error
        }
    }
    
    func save(_ transaction: Transaction) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await FirebaseConfig.shared.db.collection("transactions").document(transaction.id).setData(transaction.toDictionary())
        
        // Update cache
        cachedTransactions[transaction.id] = transaction
        try saveCachedTransactions()
    }
    
    func remove(id: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await FirebaseConfig.shared.db.collection("transactions").document(id).delete()
        
        // Remove from cache
        cachedTransactions.removeValue(forKey: id)
        try saveCachedTransactions()
    }
    
    func clearCache() throws {
        cachedTransactions.removeAll()
        try saveCachedTransactions()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedTransactions() {
        do {
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<Transaction>.self, from: data)
            cachedTransactions = container.items
        } catch {
            cachedTransactions = [:]
        }
    }
    
    private func saveCachedTransactions() throws {
        let container = CacheContainer(items: cachedTransactions)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
    }
    
    // MARK: - Additional Methods
    
    /// Fetches user's transactions
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - limit: Maximum number of transactions
    ///   - type: Optional transaction type filter
    /// - Returns: Array of transactions
    func fetchUserTransactions(
        userId: String,
        limit: Int = 20,
        type: TransactionType? = nil
    ) async throws -> [Transaction] {
        guard NetworkMonitor.shared.isConnected else {
            // Return cached transactions
            var filteredTransactions = cachedTransactions.values.filter { $0.userId == userId }
            
            if let type = type {
                filteredTransactions = filteredTransactions.filter { $0.type == type }
            }
            
            return Array(filteredTransactions.prefix(limit))
        }
        
        // Start with base query
        var query: Query = FirebaseConfig.shared.db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
        
        // Apply type filter if needed
        if let type = type {
            query = query.whereField("type", isEqualTo: type.rawValue)
        }
        
        // Apply sort and limit
        query = query.order(by: "timestamp", descending: true).limit(to: limit)
        
        // Execute query
        let snapshot = try await query.getDocuments()
        
        // Process results
        let transactions = snapshot.documents.compactMap { Transaction(document: $0) }
        
        // Cache each transaction
        for transaction in transactions {
            cachedTransactions[transaction.id] = transaction
        }
        try saveCachedTransactions()
        
        return transactions
    }
}
