//
//  LeaderboardView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/8/25.
//


// New file: Views/Tournament/LeaderboardView.swift
// Version: 1.0.0
// Created: April 2025

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background (reusing from GamesView)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Primary").opacity(0.2),
                        Color.white.opacity(0.1),
                        Color("Primary").opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                                
                            Text("Prize Pool: $\(Int(tournament.totalPrizePool))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("Primary"))
                        }
                    }
                    .padding()
                    
                    // User's position highlight
                    if let userEntry = viewModel.userEntry {
                        UserRankCard(entry: userEntry)
                            .padding(.horizontal)
                    }
                    
                    // Leaderboard List
                    List {
                        ForEach(viewModel.leaderboardEntries) { entry in
                            LeaderboardEntryRow(
                                entry: entry,
                                isCurrentUser: entry.userId == authViewModel.user?.id
                            )
                        }
                    }
                    .refreshable {
                        await viewModel.refreshLeaderboard()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.refreshLeaderboard()
                }
            }
        }
    }
}

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

struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            Text("#\(entry.rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 40)
            
            Text(entry.username)
                .font(.system(size: 16, weight: isCurrentUser ? .bold : .regular))
                .foregroundColor(isCurrentUser ? Color("Primary") : .primary)
            
            Spacer()
            
            Text("\(entry.coinsRemaining)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .listRowBackground(isCurrentUser ? Color.backgroundSecondary.opacity(0.4) : Color.clear)
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

// ViewModel for Leaderboard
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var currentTournament: Tournament?
    @Published var userEntry: LeaderboardEntry?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = FirebaseConfig.shared.db
    
    func refreshLeaderboard() async {
        isLoading = true
        
        do {
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // 1. Fetch current tournament
            let tournamentSnapshot = try await db.collection("tournaments")
                .whereField("status", isEqualTo: TournamentStatus.active.rawValue)
                .limit(to: 1)
                .getDocuments()
            
            guard let tournamentDoc = tournamentSnapshot.documents.first,
                  let tournament = Tournament(document: tournamentDoc) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active tournament found"])
            }
            
            // 2. Fetch leaderboard entries
            let leaderboardSnapshot = try await db.collection("leaderboard")
                .whereField("tournamentId", isEqualTo: tournament.id)
                .order(by: "rank")
                .limit(to: 100)
                .getDocuments()
            
            var entries: [LeaderboardEntry] = []
            for document in leaderboardSnapshot.documents {
                guard let userId = document.data()["userId"] as? String,
                      let tournamentId = document.data()["tournamentId"] as? String,
                      let username = document.data()["username"] as? String,
                      let rank = document.data()["rank"] as? Int,
                      let coinsRemaining = document.data()["coinsRemaining"] as? Int,
                      let coinsBet = document.data()["coinsBet"] as? Int,
                      let coinsWon = document.data()["coinsWon"] as? Int,
                      let betsPlaced = document.data()["betsPlaced"] as? Int,
                      let betsWon = document.data()["betsWon"] as? Int else {
                    continue
                }
                
                let entry = LeaderboardEntry(
                    id: document.documentID,
                    userId: userId,
                    tournamentId: tournamentId,
                    username: username,
                    rank: rank,
                    coinsRemaining: coinsRemaining,
                    coinsBet: coinsBet,
                    coinsWon: coinsWon,
                    betsPlaced: betsPlaced,
                    betsWon: betsWon
                )
                
                entries.append(entry)
                
                // Track user's entry
                if userId == currentUserId {
                    await MainActor.run {
                        self.userEntry = entry
                    }
                }
            }
            
            // If user's entry not found in top 100, fetch it separately
            if userEntry == nil {
                let userEntrySnapshot = try await db.collection("leaderboard")
                    .whereField("tournamentId", isEqualTo: tournament.id)
                    .whereField("userId", isEqualTo: currentUserId)
                    .limit(to: 1)
                    .getDocuments()
                
                if let userDoc = userEntrySnapshot.documents.first,
                   let userId = userDoc.data()["userId"] as? String,
                   let tournamentId = userDoc.data()["tournamentId"] as? String,
                   let username = userDoc.data()["username"] as? String,
                   let rank = userDoc.data()["rank"] as? Int,
                   let coinsRemaining = userDoc.data()["coinsRemaining"] as? Int,
                   let coinsBet = userDoc.data()["coinsBet"] as? Int,
                   let coinsWon = userDoc.data()["coinsWon"] as? Int,
                   let betsPlaced = userDoc.data()["betsPlaced"] as? Int,
                   let betsWon = userDoc.data()["betsWon"] as? Int {
                    
                    await MainActor.run {
                        self.userEntry = LeaderboardEntry(
                            id: userDoc.documentID,
                            userId: userId,
                            tournamentId: tournamentId,
                            username: username,
                            rank: rank,
                            coinsRemaining: coinsRemaining,
                            coinsBet: coinsBet,
                            coinsWon: coinsWon,
                            betsPlaced: betsPlaced,
                            betsWon: betsWon
                        )
                    }
                }
            }
            
            await MainActor.run {
                self.currentTournament = tournament
                self.leaderboardEntries = entries
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}