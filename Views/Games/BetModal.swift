//
//  BetModal.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Remove the problematic import and ensure BetModalViewModel is accessible

struct BetModal: View {
    // MARK: - Properties
    @ObservedObject var viewModel: BetModalViewModel
    @Binding var isPresented: Bool
    @Binding var selectedTeam: (gameId: String, team: TeamSelection)?
    
    let game: Game
    let user: User
    
    // MARK: - UI State
    @State private var isConfirmingBet = false
    @State private var showSuccessMessage = false
    @State private var showSubscriptionView = false
    
    private var teamName: String {
        if let team = selectedTeam?.team {
            return team == .home ? game.homeTeam : game.awayTeam
        }
        return ""
    }
    
    private var isHomeTeam: Bool {
        return selectedTeam?.team == .home
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            betModalHeader
            
            ScrollView {
                VStack(spacing: 24) {
                    // Team selection display
                    teamSelectionView
                    
                    // Bet type selection
                    betTypeSelectionView
                    
                    // Tournament coin info
                    if user.subscriptionStatus == .active {
                        tournamentInfoView
                    } else {
                        subscriptionPromptView
                    }
                    
                    // Bet amount input
                    betAmountView
                    
                    // Potential winnings
                    potentialWinningsView
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            // Place bet button
            placeBetButton
        }
        .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
        .onAppear {
            Task {
                await viewModel.loadTournamentData()
            }
        }
        .alert("Confirm Bet", isPresented: $isConfirmingBet) {
            Button("Cancel", role: .cancel) {}
            Button("Place Bet", role: .none) {
                placeBet()
            }
        } message: {
            Text("Place a \(viewModel.betAmount) coin bet on \(teamName) with spread \(String(format: "%.1f", isHomeTeam ? game.spread : -game.spread))?")
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView()
        }
    }
    
    // MARK: - Components
    
    private var betModalHeader: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .padding(8)
                        .background(Color.backgroundSecondary.opacity(0.5))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Place Bet")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Empty spacer to balance header
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding()
            
            Divider()
        }
        .background(Color.backgroundPrimary)
    }
    
    private var teamSelectionView: some View {
        VStack(spacing: 10) {
            Text("Your Selection")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(teamName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Spread: \(String(format: "%.1f", isHomeTeam ? game.spread : -game.spread))")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Home/Away indicator
                Text(isHomeTeam ? "Home" : "Away")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isHomeTeam ? Color.blue : Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        isHomeTeam ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1)
                    )
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
    
    private var betTypeSelectionView: some View {
        VStack(spacing: 10) {
            Text("Bet Type")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("Bet Type", selection: $viewModel.selectedBetType) {
                Text("Spread").tag(BetType.spread)
                Text("Moneyline").tag(BetType.moneyline)
                Text("Over/Under").tag(BetType.overUnder)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var tournamentInfoView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Tournament Coins")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.coinsRemaining) coins remaining")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            
            if let tournament = viewModel.currentTournament {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.name)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("\(tournament.formattedDateRange) • \(tournament.daysRemaining) days left")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Active")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
            }
        }
    }
    
    private var subscriptionPromptView: some View {
        VStack(spacing: 16) {
            Text("Tournament Subscription Required")
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("Subscribe to participate in weekly tournaments and compete for cash prizes!")
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showSubscriptionView = true
            }) {
                Text("Subscribe Now")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Primary"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    private var betAmountView: some View {
        VStack(spacing: 10) {
            Text("Bet Amount")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                TextField("Enter amount", text: $viewModel.betAmount)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .medium))
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)
                
                // Quick amount buttons
                ForEach([50, 100, 250], id: \.self) { amount in
                    Button(action: {
                        viewModel.betAmount = "\(amount)"
                    }) {
                        Text("\(amount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(8)
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
    }
    
    private var potentialWinningsView: some View {
        VStack(spacing: 10) {
            Text("Potential Winnings")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("🏆")
                    .font(.system(size: 22))
                
                Text(viewModel.potentialWinnings)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("coins")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
    
    private var placeBetButton: some View {
        Button(action: {
            if viewModel.canPlaceBet {
                isConfirmingBet = true
            }
        }) {
            Text("Place Bet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.canPlaceBet ? Color("Primary") : Color.gray.opacity(0.3)
                )
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.vertical, 12)
        }
        .disabled(!viewModel.canPlaceBet || viewModel.isProcessing)
        .background(Color.backgroundPrimary)
    }
    
    // MARK: - Methods
    
    private func placeBet() {
        Task {
            do {
                if try await viewModel.placeBet(
                    team: teamName,
                    isHomeTeam: isHomeTeam
                ) {
                    showSuccessMessage = true
                    // Delay dismissal to show success animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }
            } catch {
                print("Error placing bet: \(error.localizedDescription)")
            }
            
            // Always ensure processing state is reset
            if viewModel.isProcessing {
                viewModel.isProcessing = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    // Create a sample Game for preview
    let game = Game(
        id: "sample-game-1",
        homeTeam: "Lakers",
        awayTeam: "Warriors",
        time: Date().addingTimeInterval(3600 * 3),
        league: "NBA",
        spread: -5.5,
        totalBets: 34,
        homeTeamColors: TeamColors.getTeamColors("Lakers"),
        awayTeamColors: TeamColors.getTeamColors("Warriors"),
        isFeatured: true,
        manuallyFeatured: true,
        isVisible: true,
        isLocked: false
    )
    
    let user = User(id: "test-user", email: "test@example.com")
    
    // Create a BetModalViewModel instance for preview
    let viewModel = BetModalViewModel(game: game, user: user)
    
    return BetModal(
        viewModel: viewModel,
        isPresented: .constant(true),
        selectedTeam: .constant((game.id, .home)),
        game: game,
        user: user
    )
}
