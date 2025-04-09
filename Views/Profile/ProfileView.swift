// Updated file: Views/Profile/ProfileView.swift
// Version: 3.0.0 - Added tournament support
// Updated: April 2025

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingCoinPurchase = false
    @State private var showingSettings = false
    @State private var showingSubscription = false
    @State private var scrollOffset: CGFloat = 0
    
    // MARK: - ScrollOffset Preference Key
    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    private struct ScrollOffsetModifier: ViewModifier {
        let coordinateSpace: String
        @Binding var offset: CGFloat
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named(coordinateSpace)).minY
                            )
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    offset = value
                }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Primary").opacity(0.2),
                        Color.white.opacity(0.1),
                        Color("Primary").opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(scrollOffset / 2))
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 8) {
                            Text("Profile")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color("Primary"))
                                .padding(.top, -60)
                            
                            Text(authViewModel.user?.email ?? "User")
                                .font(.system(size: 18))
                                .foregroundColor(Color("Primary"))
                            
                            if let dateJoined = authViewModel.user?.dateJoined {
                                Text("Member since \(dateJoined.formatted(.dateTime.month().year()))")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("Primary"))
                            }
                        }
                        
                        // Subscription Status
                        if let user = authViewModel.user {
                            SubscriptionStatusView(status: user.subscriptionStatus, expiryDate: user.subscriptionExpiryDate)
                                .padding(.horizontal)
                        }
                        
                        // Tournament Coins
                        if let user = authViewModel.user, user.subscriptionStatus == .active {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("🏆")
                                        .font(.system(size: 24))
                                    
                                    Text("\(user.weeklyCoins)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.textPrimary)
                                }
                                
                                Text("Tournament Coins")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                
                                if let resetDate = user.weeklyCoinsReset {
                                    Text("Resets \(resetDate.formatted(.dateTime.weekday(.wide)))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Tournament Stats Section
                        if let user = authViewModel.user, user.subscriptionStatus == .active {
                            TournamentStatsSection(stats: user.tournamentStats)
                                .padding(.horizontal)
                        }
                        
                        // Quick Actions
                        VStack(spacing: 0) {
                            // Add subscription button
                            ActionButton(
                                title: authViewModel.user?.subscriptionStatus == .active ? "Manage Subscription" : "Subscribe Now",
                                icon: "trophy.fill"
                            ) {
                                showingSubscription = true
                            }
                            
                            ActionButton(
                                title: "Transaction History",
                                icon: "clock.fill"
                            ) {
                                // Navigate to transaction history
                            }
                            
                            ActionButton(
                                title: "Settings",
                                icon: "gearshape.fill"
                            ) {
                                showingSettings = true
                            }
                            
                            ActionButton(
                                title: "Sign Out",
                                icon: "rectangle.portrait.and.arrow.right",
                                showDivider: false,
                                isDestructive: true
                            ) {
                                showSignOutConfirmation()
                            }
                        }
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                        .shadow(color: Color.backgroundPrimary.opacity(0.1), radius: 5)
                        .padding(.horizontal)
                    }
                }
                .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                .coordinateSpace(name: "scroll")
            }
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .navigationBarHidden(true)
    }
    
    private func showSignOutConfirmation() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            authViewModel.signOut()
        })
        
        viewController.present(alert, animated: true)
    }
}

// New component: Subscription status
struct SubscriptionStatusView: View {
    let status: SubscriptionStatus
    let expiryDate: Date?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription Status")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)
                        
                        Text(statusText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Spacer()
                
                if status == .active, let date = expiryDate {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next Payment")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                        
                        Text(date, style: .date)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            
            if status != .active {
                Button(action: {
                    // Show subscription view
                }) {
                    Text("Subscribe Now")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color("Primary"))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    var statusText: String {
        switch status {
        case .active: return "Active"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        case .none: return "Not Subscribed"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .active: return .green
        case .expired: return .orange
        case .cancelled: return .red
        case .none: return .gray
        }
    }
}

// Tournament stats section
struct TournamentStatsSection: View {
    let stats: TournamentStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Statistics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(label: "Tournaments", value: "\(stats.tournamentsEntered)")
                StatItem(label: "Best Finish", value: stats.bestFinish > 0 ? "#\(stats.bestFinish)" : "-")
                StatItem(label: "Win Rate", value: String(format: "%.1f%%", winRate))
                StatItem(label: "Total Winnings", value: "$\(Int(stats.totalWinnings))")
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    var winRate: Double {
        guard stats.lifetimeBets > 0 else { return 0 }
        return Double(stats.lifetimeWins) / Double(stats.lifetimeBets) * 100
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
        }
    }
}
