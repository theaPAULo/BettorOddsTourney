//
//  AdminDashboardView.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @EnvironmentObject var adminNavigation: AdminNavigation
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with system health
                header
                
                // Tab selection
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Users").tag(1)
                    Text("Tournaments").tag(2)
                    Text("Bets").tag(3)
                    Text("Transactions").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab content
                Group {
                    if selectedTab == 0 {
                        overviewSection
                    } else if selectedTab == 1 {
                        AdminUsersSection()
                    } else if selectedTab == 2 {
                        tournamentSection
                    } else if selectedTab == 3 {
                        AdminBetsSection()
                    } else if selectedTab == 4 {
                        AdminTransactionsSection()
                    }
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Admin Dashboard")
        .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
        .onAppear {
            Task {
                await viewModel.loadSystemStats()
                await viewModel.loadTournaments()
            }
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Status")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(Color(viewModel.systemHealth.status.color))
                            .frame(width: 10, height: 10)
                        
                        Text(viewModel.systemHealth.status.rawValue)
                            .font(.subheadline)
                            .foregroundColor(Color(viewModel.systemHealth.status.color))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.loadSystemStats()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                Spacer()
                
                VStack {
                    Text("Latency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.systemHealth.formattedLatency)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack {
                    Text("Processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.systemHealth.formattedProcessingRate)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack {
                    Text("Error Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.systemHealth.formattedErrorRate)
                        .font(.subheadline)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var overviewSection: some View {
            VStack(spacing: 20) {
                // Stats cards
                HStack {
                    StatCard(title: "Total Users", value: "\(viewModel.totalUsers)", icon: "person.fill", color: .blue)
                    StatCard(title: "Active Subscribers", value: "\(viewModel.activeSubscribers)", icon: "star.fill", color: .green)
                }
                
                HStack {
                    StatCard(title: "Total Bets", value: "\(viewModel.totalBets)", icon: "sportscourt.fill", color: .orange)
                    StatCard(title: "Active Tournaments", value: "\(viewModel.activeTournaments.count)", icon: "trophy.fill", color: .purple)
                }
                
                // Quick actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        NavigationLink(destination: CreateTournamentView()) {
                            ActionButton(title: "Create Tournament", icon: "plus.circle.fill", color: .green)
                        }
                        
                        NavigationLink(destination: AdminSettingsView()) {
                            ActionButton(title: "App Settings", icon: "gear", color: .blue)
                        }
                        
                        NavigationLink(destination: AdminSystemHealthView()) {
                            ActionButton(title: "System Health", icon: "waveform.path.ecg", color: .orange)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    
    private var tournamentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournaments")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Active tournaments
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Tournaments")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.activeTournaments.isEmpty {
                    Text("No active tournaments")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ForEach(viewModel.activeTournaments) { tournament in
                        AdminTournamentRow(tournament: tournament)
                    }
                    .padding(.horizontal)
                }
            }
            
            // Completed tournaments
            VStack(alignment: .leading, spacing: 12) {
                Text("Completed Tournaments")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.completedTournaments.isEmpty {
                    Text("No completed tournaments")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ForEach(viewModel.completedTournaments.prefix(3)) { tournament in
                        AdminTournamentRow(tournament: tournament)
                    }
                    .padding(.horizontal)
                }
            }
            
            // Create tournament button
            Button(action: {
                // Action to create new tournament
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Tournament")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
}


struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

struct AdminTournamentRow: View {
    let tournament: Tournament
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.system(size: 16, weight: .medium))
                
                Text(tournament.formattedDateRange)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(tournament.totalPrizePool))")
                    .font(.system(size: 16, weight: .medium))
                
                HStack {
                    Text("\(tournament.participantCount) participants")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(tournament.status.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(tournament.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tournament.status.color.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
}

// Placeholder Views
struct CreateTournamentView: View {
    var body: some View {
        Text("Create Tournament View")
    }
}

struct AdminSettingsView: View {
    var body: some View {
        Text("Admin Settings View")
    }
}

struct AdminSystemHealthView: View {
    var body: some View {
        Text("System Health View")
    }
}

#Preview {
    NavigationView {
        AdminDashboardView()
            .environmentObject(AdminNavigation.shared)
    }
}
