//
//  LeaderboardView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import SwiftUI
import FirebaseAuth

struct LeaderboardView: View {
    // MARK: - Properties
    @StateObject private var viewModel = LeaderboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var showSubscriptionView = false
    
    // MARK: - ScrollOffset Helper
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
    
    // MARK: - View Body
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
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Tournament Leaderboard")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("Primary"))
                        
                        if let tournament = viewModel.currentTournament {
                            Text(tournament.formattedDateRange)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                
                            Text("Prize Pool: \(viewModel.formatCurrency(tournament.totalPrizePool))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("Primary"))
                        }
                    }
                    .padding()
                    
                    // Subscription CTA if needed
                    if authViewModel.user?.subscriptionStatus != .active {
                        subscriptionPromptView
                    } else {
                        // User's position highlight
                        if let userEntry = viewModel.userEntry {
                            UserRankCard(entry: userEntry)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                        
                        // Leaderboard List
                        leaderboardContent
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.refreshLeaderboard()
                }
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView()
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Subscription Prompt
    private var subscriptionPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("Primary").opacity(0.8))
            
            Text("Join the Tournament")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Subscribe to participate in weekly tournaments and compete for real cash prizes!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                showSubscriptionView = true
            }) {
                Text("Subscribe Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Primary"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            Text("$20/month - Cancel anytime")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 40)
    }
    
    // MARK: - Leaderboard Content
    private var leaderboardContent: some View {
        Group {
            if viewModel.isLoading && viewModel.leaderboardEntries.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.top, 80)
            } else if viewModel.leaderboardEntries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Leaderboard Entries Yet")
                        .font(.headline)
                    
                    Text("Be the first to place a bet and join the tournament!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Headers
                        HStack {
                            Text("Rank")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .center)
                            
                            Text("User")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            
                            Text("Coins")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        // Leaderboard Entries
                        ForEach(viewModel.leaderboardEntries) { entry in
                            LeaderboardEntryRow(
                                entry: entry,
                                isCurrentUser: entry.userId == Auth.auth().currentUser?.uid
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(entry.userId == Auth.auth().currentUser?.uid ?
                                          Color("Primary").opacity(0.1) : Color.clear)
                            )
                        }
                        
                        // Load More Button
                        if viewModel.hasMoreEntries {
                            Button(action: {
                                Task {
                                    await viewModel.loadMoreEntries()
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .padding()
                                } else {
                                    Text("Load More")
                                        .font(.subheadline)
                                        .foregroundColor(Color("Primary"))
                                        .padding()
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await viewModel.refreshLeaderboard()
                }
                .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                .coordinateSpace(name: "scroll")
            }
        }
    }
}

// MARK: - User Rank Card
struct UserRankCard: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack {
            Text("#\(entry.rank)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(entry.rank <= 5 ? .yellow : .primary)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Ranking")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("\(entry.coinsRemaining) coins remaining")
                    .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Win Rate")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f%%", entry.winPercentage))
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding()
        .background(Color.backgroundSecondary.opacity(0.8))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("Primary").opacity(0.7),
                            Color("Primary").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Leaderboard Entry Row
struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            // Rank
            Text("#\(entry.rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 50, alignment: .center)
            
            // Username with optional crown for top 3
            HStack(spacing: 4) {
                if entry.rank <= 3 {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                }
                
                Text(entry.username)
                    .font(.system(size: 16, weight: isCurrentUser ? .bold : .regular))
                    .foregroundColor(isCurrentUser ? Color("Primary") : .primary)
            }
            
            Spacer()
            
            // Total Coins
            Text("\(entry.totalCoins)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
    }
    
    var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2...3: return .orange
        case 4...10: return .blue
        default: return .primary
        }
    }
}

// MARK: - Preview
#Preview {
    LeaderboardView()
        .environmentObject(AuthenticationViewModel())
}
