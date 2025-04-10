//
//  BetMonitoring.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//  Version: 1.0.0 - Support models for bet monitoring
//

import Foundation

// MARK: - System Health
struct SystemHealth {
    enum Status: String {
        case healthy = "Healthy"
        case degraded = "Degraded"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .healthy: return "statusSuccess"
            case .degraded: return "statusWarning"
            case .critical: return "statusError"
            }
        }
    }
    
    let status: Status
    let matchingLatency: Double // in seconds
    let queueProcessingRate: Double // percentage
    let errorRate: Double // percentage
    let lastUpdate: Date
    
    var formattedLatency: String {
        return String(format: "%.2f s", matchingLatency)
    }
    
    var formattedProcessingRate: String {
        return String(format: "%.1f%%", queueProcessingRate)
    }
    
    var formattedErrorRate: String {
        return String(format: "%.1f%%", errorRate)
    }
}

// MARK: - Monitoring Stats
struct BetMonitoringStats {
    var pendingBetsCount: Int = 0
    var averageMatchTime: Double = 0.0 // in seconds
    var partiallyMatchedCount: Int = 0
    var fullyMatchedCount: Int = 0
    var totalBetVolume: Double = 0.0
    var hourlyVolume: Double = 0.0
    var peakVolume: Double = 0.0
    var volumeChange24h: Double = 0.0
    var matchSuccessRate: Double = 0.0
    var averageQueueDepth: Int = 0
    var systemLatency: Double = 0.0
    var suspiciousActivityCount: Int = 0
    var rapidCancellationCount: Int = 0
    var unusualPatternCount: Int = 0
    
    var formattedAverageMatchTime: String {
        return String(format: "%.1f s", averageMatchTime)
    }
    
    var formattedHourlyVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: hourlyVolume)) ?? "\(Int(hourlyVolume))"
    }
    
    var formattedVolumeChange24h: String {
        return String(format: "%.1f%%", volumeChange24h)
    }
    
    var formattedMatchSuccessRate: String {
        return String(format: "%.1f%%", matchSuccessRate)
    }
    
    var volumeChangeIsPositive: Bool {
        return volumeChange24h >= 0
    }
}

// MARK: - Queue Item
struct BetQueueItem: Identifiable {
    let id: String
    let bet: Bet
    let timeInQueue: TimeInterval // in seconds
    let potentialMatches: Int
    let estimatedMatchTime: TimeInterval // in seconds
    
    var formattedTimeInQueue: String {
        if timeInQueue < 60 {
            return String(format: "%.0f sec", timeInQueue)
        } else if timeInQueue < 3600 {
            return String(format: "%.0f min", timeInQueue / 60)
        } else {
            return String(format: "%.1f hr", timeInQueue / 3600)
        }
    }
    
    var formattedEstimatedMatchTime: String {
        if estimatedMatchTime <= 0 {
            return "Unknown"
        } else if estimatedMatchTime < 60 {
            return String(format: "%.0f sec", estimatedMatchTime)
        } else {
            return String(format: "%.0f min", estimatedMatchTime / 60)
        }
    }
    
    var isPotentiallyStuck: Bool {
        return timeInQueue > 300 && potentialMatches == 0
    }
}

// MARK: - Risk Alert
struct RiskAlert: Identifiable {
    let id: String
    let userId: String
    let type: RiskAlertType
    let severity: RiskSeverity
    let timestamp: Date
    let details: String
    
    enum RiskAlertType: String {
        case rapidCancellation = "Rapid Cancellation"
        case unusualVolume = "Unusual Volume"
        case suspiciousPattern = "Suspicious Pattern"
        case systemAnomaly = "System Anomaly"
        
        var icon: String {
            switch self {
            case .rapidCancellation: return "xmark.circle"
            case .unusualVolume: return "chart.line.uptrend.xyaxis"
            case .suspiciousPattern: return "exclamationmark.triangle"
            case .systemAnomaly: return "gearshape.2"
            }
        }
    }
    
    enum RiskSeverity: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "statusWarning"
            case .high: return "statusError"
            }
        }
    }
}
