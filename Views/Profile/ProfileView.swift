import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingCoinPurchase = false
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 8) {
                    Text(authViewModel.user?.email ?? "User")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    if let dateJoined = authViewModel.user?.dateJoined {
                        Text("Member since \(dateJoined.formatted(.dateTime.month().year()))")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.top)
                
                // Coin Balances
                HStack(spacing: 16) {
                    // Yellow Coins
                    CoinBalanceCard(
                        type: .yellow,
                        balance: authViewModel.user?.yellowCoins ?? 0
                    )
                    
                    // Green Coins
                    CoinBalanceCard(
                        type: .green,
                        balance: authViewModel.user?.greenCoins ?? 0
                    )
                }
                .padding(.horizontal)
                
                // Quick Actions
                VStack(spacing: 0) {
                    ActionButton(
                        title: "Buy Coins",
                        icon: "dollarsign.circle.fill"
                    ) {
                        showingCoinPurchase = true
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
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Profile")
        .sheet(isPresented: $showingCoinPurchase) {
            CoinPurchaseView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
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

struct CoinBalanceCard: View {
    let type: CoinType
    let balance: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(type == .yellow ? "🟡" : "💚")
                    .font(.system(size: 24))
                Spacer()
                Text(balance.formatted())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            
            HStack {
                Text(type == .yellow ? "Play Coins" : "Real Coins")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                Spacer()
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.backgroundPrimary.opacity(0.1), radius: 5)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    var showDivider: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .statusError : .primary)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(isDestructive ? .statusError : .textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            .padding()
        }
        
        if showDivider {
            Divider()
                .padding(.leading, 56)
                .background(Color.backgroundPrimary)
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthenticationViewModel())
    }
}
