//
//  MyBetsView.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import SwiftUI
import FirebaseAuth

struct MyBetsView: View {
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedFilter: BetStatus? = nil
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Tournament Stats Bar
                    if let tournament = viewModel.currentTournament {
                        tournamentInfoBar(tournament: tournament)
                    }
                    
                    // Header with filter
                    HStack {
                        Text("My Bets")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Filter button
                        Menu {
                            Button("All Bets", action: { selectedFilter = nil })
                            
                            Divider()
                            
                            ForEach(BetStatus.allCases, id: \.self) { status in
                                Button(status.rawValue, action: { selectedFilter = status })
                            }
                        } label: {
                            HStack {
                                Text(selectedFilter?.rawValue ?? "All Bets")
                                    .font(.subheadline)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else if viewModel.bets.isEmpty {
                        emptyStateView
                    } else {
                        // Bets list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredBets) { bet in
                                    BetCard(
                                        bet: bet,
                                        onCancelTapped: {
                                            BetsManager.shared.cancelBet(bet)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            // Refresh data
                            loadData()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
        }
    }
    
    // Filter bets based on selected filter
    private var filteredBets: [Bet] {
        if let filter = selectedFilter {
            return viewModel.bets.filter { $0.status == filter }
        } else {
            return viewModel.bets
        }
    }
    
    // Load data
    private func loadData() {
        Task {
            await viewModel.loadTournament()
            await viewModel.loadMyBets()
            await viewModel.loadStats()
        }
    }
    
    // Tournament info bar
    private func tournamentInfoBar(tournament: Tournament) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tournament.name)
                    .font(.headline)
                
                Text(tournament.formattedDateRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let stats = viewModel.stats {
                HStack(spacing: 16) {
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(stats.totalWonBets)")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Wins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(stats.formattedWinPercentage)
                            .font(.headline)
                        
                        Text("Win Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No bets yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Your bets will appear here once you place them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                BetsManager.shared.loadMyBets()
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

// MARK: - MyBetsViewModel
class MyBetsViewModel: ObservableObject {
    @Published var bets: [Bet] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentTournament: Tournament?
    @Published var stats: TournamentBetStats?
    
    private let betsManager = BetsManager.shared
    
    @MainActor
    func loadMyBets() async {
        isLoading = true
        
        // Use BetsManager to load bets
        betsManager.loadMyBets()
        
        // Get bets from manager
        self.bets = betsManager.myBets
        self.error = betsManager.error
        self.isLoading = false
    }
    
    @MainActor
    func loadTournament() async {
        await betsManager.loadCurrentTournament()
        self.currentTournament = betsManager.currentTournament
    }
    
    @MainActor
    func loadStats() async {
        if self.currentTournament != nil {
            do {
                let stats = try await betsManager.getTournamentStats()
                self.stats = stats
            } catch {
                self.error = error
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MyBetsView()
}
