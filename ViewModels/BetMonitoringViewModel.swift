//
//  BetMonitoringViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  BetMonitoringViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//  Version: 1.0.0
//

import SwiftUI
import FirebaseFirestore

@MainActor
class BetMonitoringViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var systemHealth = SystemHealth(
        status: .healthy,
        matchingLatency: 0.5,
        queueProcessingRate: 92.5,
        errorRate: 0.8,
        lastUpdate: Date()
    )
    
    @Published var stats = BetMonitoringStats()
    @Published var queueItems: [BetQueueItem] = []
    @Published var riskAlerts: [RiskAlert] = []
    
    // MARK: - Private Properties
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Initialization
    init() {
        loadData()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes all monitoring data
    func refreshData() async {
        // In a real implementation, this would fetch data from Firebase
        // For now, we'll generate sample data
        
        // Update system health
        systemHealth = SystemHealth(
            status: [.healthy, .degraded, .healthy].randomElement()!,
            matchingLatency: Double.random(in: 0.2...1.5),
            queueProcessingRate: Double.random(in: 85...99),
            errorRate: Double.random(in: 0.1...2.0),
            lastUpdate: Date()
        )
        
        // Update stats
        stats.pendingBetsCount = Int.random(in: 10...40)
        stats.averageMatchTime = Double.random(in: 10...30)
        stats.matchSuccessRate = Double.random(in: 90...99)
        stats.hourlyVolume = Double.random(in: 1000...5000)
        stats.volumeChange24h = Double.random(in: -10...20)
        
        // Load queue items
        loadQueueItems()
        
        // Load risk alerts
        loadRiskAlerts()
    }
    
    /// Triggers manual matching for a bet
    func triggerMatching(for betId: String) async throws {
        // Simulate a network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Remove the bet from the queue
        queueItems.removeAll { $0.bet.id == betId }
        
        // Update stats
        stats.pendingBetsCount -= 1
        stats.matchSuccessRate += 0.1
    }
    
    /// Cancels all pending bets (for maintenance mode)
    func cancelAllPendingBets() async throws {
        // Simulate a network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Clear the queue
        queueItems.removeAll()
        
        // Update stats
        stats.pendingBetsCount = 0
    }
    
    // MARK: - Private Methods
    
    /// Loads initial data
    private func loadData() {
        // In a real implementation, this would fetch data from Firebase
        // For now, we'll generate sample data
        stats = BetMonitoringStats(
            pendingBetsCount: Int.random(in: 10...40),
            averageMatchTime: Double.random(in: 10...30),
            partiallyMatchedCount: Int.random(in: 5...15),
            fullyMatchedCount: Int.random(in: 20...50),
            totalBetVolume: Double.random(in: 10000...50000),
            hourlyVolume: Double.random(in: 1000...5000),
            peakVolume: Double.random(in: 5000...10000),
            volumeChange24h: Double.random(in: -10...20),
            matchSuccessRate: Double.random(in: 90...99),
            averageQueueDepth: Int.random(in: 5...20),
            systemLatency: Double.random(in: 0.2...1.5),
            suspiciousActivityCount: Int.random(in: 0...5),
            rapidCancellationCount: Int.random(in: 0...3),
            unusualPatternCount: Int.random(in: 0...2)
        )
        
        loadQueueItems()
        loadRiskAlerts()
    }
    
    /// Loads queue items
    private func loadQueueItems() {
        // Generate sample queue items
        queueItems = []
        
        for i in 1...Int.random(in: 3...8) {
            let bet = Bet(
                id: "queue-\(i)",
                userId: "user-\(Int.random(in: 1...100))",
                gameId: "game-\(Int.random(in: 1...10))",
                tournamentId: "tournament1",
                amount: Int.random(in: 10...100) * 5,
                initialSpread: Double.random(in: -10...10),
                team: ["Lakers", "Warriors", "Celtics", "Nets", "Heat"].randomElement()!,
                isHomeTeam: Bool.random()
            )
            
            let queueItem = BetQueueItem(
                id: "queue-item-\(i)",
                bet: bet,
                timeInQueue: Double.random(in: 60...3600),
                potentialMatches: Int.random(in: 0...15),
                estimatedMatchTime: Double.random(in: 0...300)
            )
            
            queueItems.append(queueItem)
        }
    }
    
    /// Loads risk alerts
    private func loadRiskAlerts() {
        // Generate sample risk alerts
        riskAlerts = []
        
        for i in 1...Int.random(in: 2...5) {
            let alert = RiskAlert(
                id: "alert-\(i)",
                userId: "user-\(Int.random(in: 1...100))",
                type: [.rapidCancellation, .unusualVolume, .suspiciousPattern, .systemAnomaly].randomElement()!,
                severity: [.low, .medium, .high].randomElement()!,
                timestamp: Date().addingTimeInterval(-Double.random(in: 0...7200)),
                details: [
                    "User placed and cancelled 5 bets in 3 minutes",
                    "Unusual betting pattern detected: 20 identical bets",
                    "User attempted to exploit spread change with rapid bets",
                    "System detected potential collusion between related accounts",
                    "Unusual activity spike detected from same IP address"
                ].randomElement()!
            )
            
            riskAlerts.append(alert)
        }
        
        // Sort by timestamp (most recent first)
        riskAlerts.sort { $0.timestamp > $1.timestamp }
    }
}