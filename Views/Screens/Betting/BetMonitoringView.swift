//
//  BetMonitoringView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//  Version: 1.0.0 - Initial implementation
//

import SwiftUI

struct BetMonitoringView: View {
    @StateObject private var viewModel = BetMonitoringViewModel()
    @State private var selectedTab = 0
    @State private var showCancelConfirmation = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Title and refresh button
            HStack {
                Text("Bet Monitoring")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.refreshData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // System status indicator
            SystemStatusView(systemHealth: viewModel.systemHealth)
                .padding()
            
            // Tabs
            Picker("View", selection: $selectedTab) {
                Text("Stats").tag(0)
                Text("Queue").tag(1)
                Text("Alerts").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Tab content
            TabView(selection: $selectedTab) {
                StatsView(stats: viewModel.stats)
                    .tag(0)
                
                QueueView(
                    queueItems: viewModel.queueItems,
                    onTriggerMatchingTapped: { betId in
                        Task {
                            try await viewModel.triggerMatching(for: betId)
                        }
                    }
                )
                .tag(1)
                
                AlertsView(alerts: viewModel.riskAlerts)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Bottom maintenance actions
            VStack {
                Divider()
                Button(action: {
                    showCancelConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel All Pending Bets")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.statusError)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .alert("Cancel All Pending Bets", isPresented: $showCancelConfirmation) {
            Button("Keep Bets", role: .cancel) { }
            Button("Cancel All", role: .destructive) {
                Task {
                    try await viewModel.cancelAllPendingBets()
                }
            }
        } message: {
            Text("This will cancel all pending bets in the system. This action cannot be undone.")
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
}

// MARK: - System Status View
struct SystemStatusView: View {
    let systemHealth: SystemHealth
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Status")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(Color(systemHealth.status.color))
                        .frame(width: 10, height: 10)
                    
                    Text(systemHealth.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Color(systemHealth.status.color))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Last Updated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(systemHealth.lastUpdate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
    }
}

// MARK: - Stats View
// MARK: - Stats View
struct StatsView: View {
    let stats: BetMonitoringStats
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Volume metrics
                HStack {
                    MonitoringStatCard(
                        title: "Hourly Volume",
                        value: stats.formattedHourlyVolume,
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    
                    MonitoringStatCard(
                        title: "24h Change",
                        value: stats.formattedVolumeChange24h,
                        icon: stats.volumeChangeIsPositive ? "arrow.up.right" : "arrow.down.right",
                        color: stats.volumeChangeIsPositive ? .green : .red
                    )
                }
                
                // Performance metrics
                HStack {
                    MonitoringStatCard(
                        title: "Match Rate",
                        value: stats.formattedMatchSuccessRate,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    MonitoringStatCard(
                        title: "Avg Match Time",
                        value: stats.formattedAverageMatchTime,
                        icon: "timer",
                        color: .orange
                    )
                }
                
                // Queue metrics
                HStack {
                    MonitoringStatCard(
                        title: "Pending Bets",
                        value: "\(stats.pendingBetsCount)",
                        icon: "clock.fill",
                        color: .purple
                    )
                    
                    MonitoringStatCard(
                        title: "Avg Queue Depth",
                        value: "\(stats.averageQueueDepth)",
                        icon: "list.bullet",
                        color: .blue
                    )
                }
                
                // Risk metrics
                HStack {
                    MonitoringStatCard(
                        title: "Suspicious Activity",
                        value: "\(stats.suspiciousActivityCount)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )
                    
                    MonitoringStatCard(
                        title: "Rapid Cancellations",
                        value: "\(stats.rapidCancellationCount)",
                        icon: "xmark.circle.fill",
                        color: .orange
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Queue View
struct QueueView: View {
    let queueItems: [BetQueueItem]
    let onTriggerMatchingTapped: (String) -> Void
    
    var body: some View {
        if queueItems.isEmpty {
            VStack {
                Spacer()
                Text("No items in queue")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            List {
                ForEach(queueItems) { item in
                    QueueItemRow(
                        item: item,
                        onTriggerMatchingTapped: onTriggerMatchingTapped
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - Alerts View
struct AlertsView: View {
    let alerts: [RiskAlert]
    
    var body: some View {
        if alerts.isEmpty {
            VStack {
                Spacer()
                Text("No alerts detected")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            List {
                ForEach(alerts) { alert in
                    RiskAlertRow(alert: alert)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - Supporting Views
struct QueueItemRow: View {
    let item: BetQueueItem
    let onTriggerMatchingTapped: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.bet.team)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Text("\(item.bet.amount) coins")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("In queue: \(item.formattedTimeInQueue)", systemImage: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(item.isPotentiallyStuck ? .orange : .secondary)
                
                Spacer()
                
                Label("\(item.potentialMatches) potential matches", systemImage: "person.2")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Est. match time: \(item.formattedEstimatedMatchTime)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    onTriggerMatchingTapped(item.bet.id)
                }) {
                    Text("Force Match")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct RiskAlertRow: View {
    let alert: RiskAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: alert.type.icon)
                    .foregroundColor(Color(alert.severity.color))
                
                Text(alert.type.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(alert.severity.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(alert.severity.color).opacity(0.2))
                    .foregroundColor(Color(alert.severity.color))
                    .cornerRadius(4)
            }
            
            Text("User ID: \(alert.userId)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text(alert.details)
                .font(.system(size: 14))
            
            Text(alert.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
// MARK: - Preview
#Preview {
    BetMonitoringView()
}

// Monitoring-specific stat card
struct MonitoringStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
    }
}
