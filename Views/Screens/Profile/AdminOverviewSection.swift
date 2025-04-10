//
//  AdminOverviewSection.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.0.0
//

import SwiftUI

struct AdminOverviewSection: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(spacing: 16) {
            // Quick Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickStatCard(title: "Active Users", value: "\(stats.activeUsers)")
                QuickStatCard(title: "Daily Bets", value: "\(stats.dailyBets)")
                QuickStatCard(title: "Revenue", value: "$\(String(format: "%.2f", stats.revenue))")
                QuickStatCard(title: "Pending Bets", value: "\(stats.pendingBets)")
            }
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                ForEach(stats.recentActivity) { activity in
                    HStack {
                        Circle()
                            .fill(activity.type.color)
                            .frame(width: 8, height: 8)
                        Text(activity.description)
                            .font(.system(size: 14))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(activity.time)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    AdminOverviewSection(
        stats: DashboardStats(
            activeUsers: 125,
            dailyBets: 450,
            revenue: 1250.50,
            pendingBets: 32,
            recentActivity: [
                ActivityItem(type: .bet, description: "New bet placed", time: "2m ago"),
                ActivityItem(type: .user, description: "New user registered", time: "5m ago"),
                ActivityItem(type: .transaction, description: "Withdrawal processed", time: "10m ago")
            ]
        )
    )
    .padding()
    .background(Color.backgroundPrimary)
}
