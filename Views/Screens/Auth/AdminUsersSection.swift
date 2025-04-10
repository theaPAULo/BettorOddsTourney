//
//  AdminUsersSection.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Updated for tournament system
//

import SwiftUI
import FirebaseFirestore

// MARK: - Admin Users Section
struct AdminUsersSection: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedUser: User?
    @State private var showUserDetail = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Users")
                .font(.title2)
                .fontWeight(.bold)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search users by email", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Users list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredUsers) { user in
                        AdminUserRow(
                            user: user,
                            onTap: {
                                selectedUser = user
                                showUserDetail = true
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 400)
            
            // Stats
            HStack {
                AdminStatBox(
                    title: "Total Users",
                    value: "\(viewModel.users.count)"
                )
                
                AdminStatBox(
                    title: "Active Subscribers",
                    value: "\(viewModel.users.filter { $0.subscriptionStatus == .active }.count)"
                )
                
                AdminStatBox(
                    title: "Tournament Coins",
                    value: "\(viewModel.users.reduce(0) { $0 + $1.weeklyCoins })"
                )
            }
            
            // Refresh button
            Button(action: {
                Task {
                    await viewModel.loadUsers()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal)
        .sheet(isPresented: $showUserDetail, content: {
            if let user = selectedUser {
                AdminUserDetailView(user: user)
            }
        })
    }
    
    // Filter users based on search
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter { user in
                user.email.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

// MARK: - Admin User Row
struct AdminUserRow: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.email)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Joined: \(user.dateJoined.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Subscription badge
                Text(user.subscriptionStatus.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(subscriptionColor.opacity(0.2))
                    .foregroundColor(subscriptionColor)
                    .cornerRadius(4)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.backgroundPrimary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var subscriptionColor: Color {
        switch user.subscriptionStatus {
        case .active:
            return .green
        case .cancelled:
            return .orange
        case .expired:
            return .red
        case .none:
            return .gray
        }
    }
}

// MARK: - Admin User Detail View
struct AdminUserDetailView: View {
    @Environment(\.dismiss) var dismiss
    let user: User
    
    @State private var showConfirmation = false
    @State private var actionType: ActionType = .none
    
    enum ActionType {
        case none
        case resetCoins
        case addCoins
        case removeCoins
        case cancelSubscription
        case addSubscription
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Basic info section
                Section(header: Text("User Information")) {
                    DetailRow(title: "Email", value: user.email)
                    DetailRow(title: "Join Date", value: user.dateJoined.formatted())
                    DetailRow(title: "ID", value: user.id)
                }
                
                // Subscription section
                Section(header: Text("Subscription")) {
                    DetailRow(
                        title: "Status",
                        value: user.subscriptionStatus.rawValue,
                        valueColor: subscriptionColor
                    )
                    
                    if let expiryDate = user.subscriptionExpiryDate {
                        DetailRow(
                            title: "Expiry Date",
                            value: expiryDate.formatted()
                        )
                    }
                    
                    // Subscription action buttons
                    if user.subscriptionStatus == .active || user.subscriptionStatus == .cancelled {
                        Button("Cancel Subscription") {
                            actionType = .cancelSubscription
                            showConfirmation = true
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Add Subscription") {
                            actionType = .addSubscription
                            showConfirmation = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Tournament coins section
                Section(header: Text("Tournament Coins")) {
                    DetailRow(title: "Weekly Coins", value: "\(user.weeklyCoins)")
                    DetailRow(title: "Reset Date", value: user.weeklyCoinsReset.formatted())
                    
                    // Coin management buttons
                    HStack {
                        Button("Add 500") {
                            actionType = .addCoins
                            showConfirmation = true
                        }
                        .foregroundColor(.green)
                        
                        Spacer()
                        
                        Button("Reset") {
                            actionType = .resetCoins
                            showConfirmation = true
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                // Tournament stats section
                Section(header: Text("Tournament Stats")) {
                    DetailRow(title: "Tournaments Entered", value: "\(user.tournamentStats.tournamentsEntered)")
                    DetailRow(title: "Best Finish", value: "\(user.tournamentStats.bestFinish > 0 ? "\(user.tournamentStats.bestFinish)" : "N/A")")
                    DetailRow(title: "Total Winnings", value: "$\(String(format: "%.2f", user.tournamentStats.totalWinnings))")
                    DetailRow(title: "Lifetime Bets", value: "\(user.tournamentStats.lifetimeBets)")
                    DetailRow(title: "Lifetime Wins", value: "\(user.tournamentStats.lifetimeWins)")
                }
            }
            .navigationTitle("User Details")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .alert(isPresented: $showConfirmation) {
                getAlertForAction()
            }
        }
    }
    
    // Get the appropriate alert for the selected action
    private func getAlertForAction() -> Alert {
        switch actionType {
        case .resetCoins:
            return Alert(
                title: Text("Reset Coins"),
                message: Text("Are you sure you want to reset this user's tournament coins?"),
                primaryButton: .destructive(Text("Reset")) {
                    // Reset coins logic would go here
                    print("Resetting coins for \(user.email)")
                },
                secondaryButton: .cancel()
            )
        case .addCoins:
            return Alert(
                title: Text("Add Coins"),
                message: Text("Add 500 tournament coins to this user's account?"),
                primaryButton: .default(Text("Add")) {
                    // Add coins logic would go here
                    print("Adding coins for \(user.email)")
                },
                secondaryButton: .cancel()
            )
        case .removeCoins:
            return Alert(
                title: Text("Remove Coins"),
                message: Text("Remove coins from this user?"),
                primaryButton: .destructive(Text("Remove")) {
                    // Remove coins logic would go here
                    print("Removing coins for \(user.email)")
                },
                secondaryButton: .cancel()
            )
        case .cancelSubscription:
            return Alert(
                title: Text("Cancel Subscription"),
                message: Text("Cancel this user's subscription?"),
                primaryButton: .destructive(Text("Cancel Subscription")) {
                    // Cancel subscription logic would go here
                    print("Cancelling subscription for \(user.email)")
                },
                secondaryButton: .cancel()
            )
        case .addSubscription:
            return Alert(
                title: Text("Add Subscription"),
                message: Text("Add a 1-month subscription for this user?"),
                primaryButton: .default(Text("Add Subscription")) {
                    // Add subscription logic would go here
                    print("Adding subscription for \(user.email)")
                },
                secondaryButton: .cancel()
            )
        case .none:
            return Alert(title: Text("Error"), message: Text("Invalid action"))
        }
    }
    
    private var subscriptionColor: Color {
        switch user.subscriptionStatus {
        case .active:
            return .green
        case .cancelled:
            return .orange
        case .expired:
            return .red
        case .none:
            return .gray
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Admin Stat Box
struct AdminStatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
}
