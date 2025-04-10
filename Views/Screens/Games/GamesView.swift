//
//  GamesView.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import SwiftUI
import FirebaseAuth

struct GamesView: View {
    // MARK: - Properties
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel  // Updated line
    @State private var showBetModal = false
    @State private var selectedGame: Game?
    @State private var selectedTeam: (gameId: String, team: TeamSelection)?
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header and wallet
                headerView
                
                // Tournament card if in tournament
                if let tournament = viewModel.currentTournament {
                    TournamentCard(tournament: tournament)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Tab selection for games
                gamesTabPickerView
                
                // Content based on selection
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.games.isEmpty {
                    emptyStateView
                } else {
                    gamesList
                }
            }
            .padding(.top, 1) // Add a tiny bit of padding to prevent layout issues
        }
        .onAppear {
            Task {
                await viewModel.loadGames()
            }
        }
        .sheet(isPresented: $showBetModal) {
            if let game = selectedGame, let user = authViewModel.user {
                // Create BetModalViewModel and pass the parameters correctly
                let betViewModel = BetModalViewModel(game: game, user: user)
                
                BetModal(
                    viewModel: betViewModel,
                    isPresented: $showBetModal,
                    selectedTeam: $selectedTeam,
                    game: game,
                    user: user
                )
            }
        }
    }
    
    // MARK: - Components
    
    // Header view with wallet info
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Logo or title
                Text("BettorOdds")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Wallet preview
                if let user = authViewModel.user {
                    HStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Text("🏆")
                                .font(.system(size: 18))
                            
                            Text("\(user.weeklyCoins)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.textSecondary.opacity(0.2))
        }
    }
    
    // Games tab selection
    private var gamesTabPickerView: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Game Types", selection: $viewModel.selectedGameType) {
                    Text("All").tag(GameType.all)
                    Text("Basketball").tag(GameType.basketball)
                    Text("Football").tag(GameType.football)
                    Text("Baseball").tag(GameType.baseball)
                    Text("Soccer").tag(GameType.soccer)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
                .background(Color.textSecondary.opacity(0.2))
        }
    }
    
    // Games list
    private var gamesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Featured games section
                if !viewModel.featuredGames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.featuredGames) { game in
                                    FeaturedGameCard(game: game) {
                                        selectedGame = game
                                        showBetModal = true
                                    }
                                    .frame(width: 280)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                
                // Regular games
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming Games")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.horizontal)
                    
                    ForEach(viewModel.filteredGames) { game in
                        GameCard(
                            game: game,
                            isFeatured: false,
                            onSelect: {
                                selectedGame = game
                                showBetModal = true
                            },
                            globalSelectedTeam: $selectedTeam
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Padding at bottom for better scrolling experience
                Color.clear.frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.loadGames()
        }
    }
    
    // Empty state
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Games Available")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Check back soon for upcoming games.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                Task {
                    await viewModel.loadGames()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color("Primary"))
                .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
}

// MARK: - Game Type
enum GameType {
    case all
    case basketball
    case football
    case baseball
    case soccer
}

// MARK: - Team Selection
enum TeamSelection {
    case home
    case away
}

// MARK: - Tournament Card
struct TournamentCard: View {
    let tournament: Tournament
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.headline)
                
                Text("\(tournament.daysRemaining) days remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Prize pool info
            VStack(alignment: .trailing, spacing: 4) {
                Text("Prize Pool")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("$\(Int(tournament.totalPrizePool))")
                    .font(.headline)
                    .foregroundColor(Color("Primary"))
            }
        }
        .padding()
        .background(
            Color.backgroundSecondary.opacity(0.8)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("Primary").opacity(0.6),
                            Color("Primary").opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// Preview
#Preview {
    GamesView()
}
