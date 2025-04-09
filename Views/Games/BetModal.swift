// Updates to BetModal.swift
// Version: 3.0.0 - Modified for tournament system
// Updated: April 2025

import SwiftUI

struct BetModal: View {
    // MARK: - Properties
    let game: Game
    @Binding var isPresented: Bool
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: String?
    @State private var isHomeTeamSelected: Bool = false
    
    // MARK: - Initialization
    init(game: Game, user: User, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.game = game
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    // Background gradient colors
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("Primary").opacity(0.2),
                Color.white.opacity(0.1),
                Color("Primary").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time Display
                        Text(game.formattedTime)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.top, 8)
                        
                        // Team Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Team")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 16) {
                                    // Away Team Button
                                    TeamSelectionButton(
                                        team: game.awayTeam,
                                        spread: -game.spread,
                                        teamColors: game.awayTeamColors,
                                        isSelected: selectedTeam == game.awayTeam,
                                        width: (geometry.size.width - 16) / 2
                                    ) {
                                        selectedTeam = game.awayTeam
                                        isHomeTeamSelected = false
                                        hapticFeedback()
                                    }
                                    
                                    // Home Team Button
                                    TeamSelectionButton(
                                        team: game.homeTeam,
                                        spread: game.spread,
                                        teamColors: game.homeTeamColors,
                                        isSelected: selectedTeam == game.homeTeam,
                                        width: (geometry.size.width - 16) / 2
                                    ) {
                                        selectedTeam = game.homeTeam
                                        isHomeTeamSelected = true
                                        hapticFeedback()
                                    }
                                }
                            }
                            .frame(height: 100)
                        }
                        
                        // Tournament Info (NEW)
                        if let tournament = viewModel.currentTournament {
                            TournamentInfoCard(tournament: tournament, coinsRemaining: viewModel.coinsRemaining)
                                .padding(.horizontal)
                        }
                        
                        // Bet Amount Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bet Amount")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack {
                                Text("🏆")
                                TextField("0", text: $viewModel.betAmount)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Text("Coins Remaining: \(viewModel.coinsRemaining)")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
                        
                        // Potential Winnings
                        VStack(spacing: 8) {
                            Text("Potential Winnings")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack {
                                Text("🏆")
                                Text(viewModel.potentialWinnings)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                        
                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.statusError)
                                .font(.system(size: 14))
                        }
                        
                        // Place Bet Button
                        CustomButton(
                            title: "PLACE BET",
                            action: handlePlaceBet,
                            style: .primary,
                            isLoading: viewModel.isProcessing,
                            disabled: !viewModel.canPlaceBet || selectedTeam == nil
                        )
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Place Tournament Bet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") { isPresented = false })
            .onAppear {
                Task {
                    await viewModel.loadTournamentData()
                }
            }
        }
    }
    
    // MARK: - Methods
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func handlePlaceBet() {
        guard let team = selectedTeam else { return }
        
        Task {
            do {
                let success = try await viewModel.placeBet(team: team, isHomeTeam: isHomeTeamSelected)
                
                await MainActor.run {
                    if success {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        isPresented = false
                    } else {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

// NEW: Tournament Info Card
struct TournamentInfoCard: View {
    let tournament: Tournament
    let coinsRemaining: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tournament: \(tournament.formattedDateRange)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prize Pool")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                    
                    Text("$\(Int(tournament.totalPrizePool))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Your Coins")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                    
                    Text("\(coinsRemaining)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// Updated ViewModel
class BetModalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var betAmount: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var coinsRemaining: Int = 0
    @Published var currentTournament: Tournament?
    
    // MARK: - Private Properties
    private let game: Game
    private let user: User
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Computed Properties
    var canPlaceBet: Bool {
        guard let amount = Int(betAmount), amount > 0 else {
            return false
        }
            
        // Check if game is locked
        if game.isLocked {
            return false
        }
        
        // Check if user has enough coins
        return amount <= coinsRemaining
    }
    
    var potentialWinnings: String {
        guard let amount = Int(betAmount) else { return "0" }
        return String(format: "%d", amount)
    }
    
    // MARK: - Initialization
    init(game: Game, user: User) {
        self.game = game
        self.user = user
        self.coinsRemaining = user.weeklyCoins
    }
    
    // MARK: - Public Methods
    
    func loadTournamentData() async {
        do {
            // Load current tournament
            let tournamentSnapshot = try await db.collection("tournaments")
                .whereField("status", isEqualTo: TournamentStatus.active.rawValue)
                .limit(to: 1)
                .getDocuments()
            
            guard let tournamentDoc = tournamentSnapshot.documents.first,
                  let tournament = Tournament(document: tournamentDoc) else {
                throw NSError(domain: "", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "No active tournament found"
                ])
            }
            
            // Load user's coins
            if let userId = Auth.auth().currentUser?.uid {
                let leaderboardSnapshot = try await db.collection("leaderboard")
                    .whereField("tournamentId", isEqualTo: tournament.id)
                    .whereField("userId", isEqualTo: userId)
                    .limit(to: 1)
                    .getDocuments()
                
                if let leaderboardDoc = leaderboardSnapshot.documents.first,
                   let coinsRemaining = leaderboardDoc.data()["coinsRemaining"] as? Int {
                    await MainActor.run {
                        self.coinsRemaining = coinsRemaining
                    }
                }
            }
            
            await MainActor.run {
                self.currentTournament = tournament
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Places a bet for the tournament
    func placeBet(team: String, isHomeTeam: Bool) async throws -> Bool {
        guard !isProcessing else { return false }
        guard let amount = Int(betAmount), amount > 0 else {
            errorMessage = "Invalid bet amount"
            return false
        }
        
        // Check coin balance
        guard amount <= coinsRemaining else {
            errorMessage = "Insufficient coins"
            return false
        }
        
        isProcessing = true
        defer { isProcessing = false }
        errorMessage = nil
        
        do {
            guard let userId = Auth.auth().currentUser?.uid,
                  let tournamentId = currentTournament?.id else {
                throw NSError(domain: "", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Missing user or tournament information"
                ])
            }
            
            // Create bet
            let bet = Bet(
                userId: userId,
                gameId: game.id,
                tournamentId: tournamentId,
                amount: amount,
                initialSpread: isHomeTeam ? game.spread : -game.spread,
                team: team,
                isHomeTeam: isHomeTeam
            )
            
            // Save bet
            try await db.collection("bets").document(bet.id).setData(bet.toDictionary())
            
            // Update leaderboard entry
            let leaderboardSnapshot = try await db.collection("leaderboard")
                .whereField("tournamentId", isEqualTo: tournamentId)
                .whereField("userId", isEqualTo: userId)
                .limit(to: 1)
                .getDocuments()
            
            if let leaderboardDoc = leaderboardSnapshot.documents.first {
                try await db.collection("leaderboard").document(leaderboardDoc.id).updateData([
                    "coinsRemaining": FieldValue.increment(Int64(-amount)),
                    "coinsBet": FieldValue.increment(Int64(amount)),
                    "betsPlaced": FieldValue.increment(Int64(1))
                ])
                
                // Update local coins remaining
                await MainActor.run {
                    self.coinsRemaining -= amount
                }
            }
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
