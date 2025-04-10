//
//  AdminGameManagementView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/30/25.
//


//
//  AdminGameManagementView.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.0.0
//

import SwiftUI

struct AdminGameManagementView: View {
    @StateObject private var viewModel = AdminGameManagementViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // Featured Game Section
            // Featured Game Section
            Section {
                if let featuredGame = viewModel.games.first(where: { $0.isFeatured }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(featuredGame.homeTeam) vs \(featuredGame.awayTeam)")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(featuredGame.time.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    Text("No featured game selected")
                        .foregroundColor(.textSecondary)
                }
                
                Button("Select Featured Game") {
                    viewModel.showGameSelector = true
                }
                .foregroundColor(AppTheme.Brand.primary)
            } header: {
                Text("Featured Game")
                    .foregroundColor(.textSecondary)
            } footer: {
                Text("Featured games appear at the top of the list.")
                    .foregroundColor(.textSecondary)
            }
            
            // Game Management Section
            Section {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ForEach(viewModel.games) { game in
                        GameManagementRow(
                            game: game,
                            onToggleLock: {
                                Task { await viewModel.toggleGameLock(game) }
                            },
                            onToggleVisibility: {
                                Task { await viewModel.toggleGameVisibility(game) }
                            }
                        )
                    }
                }
            } header: {
                Text("Game Management")
                    .foregroundColor(.textSecondary)
            }
        }
        .navigationTitle("Game Management")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Done") { dismiss() })
        .sheet(isPresented: $viewModel.showGameSelector) {
            GameSelectorView(
                games: viewModel.availableGames,
                onSelect: { game in
                    Task {
                        await viewModel.setFeaturedGame(game)
                    }
                }
            )
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.successMessage ?? "Operation completed successfully")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .refreshable {
            await viewModel.loadGames()
        }
    }
}

// MARK: - Supporting Views
struct FeaturedGameRow: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(game.homeTeam) vs \(game.awayTeam)")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.textSecondary)
                Text(game.time.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            if let lastUpdated = game.lastUpdatedAt {
                Text("Last updated: \(lastUpdated.formatted())")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GameManagementRow: View {
    let game: Game
    let onToggleLock: () -> Void
    let onToggleVisibility: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(game.homeTeam) vs \(game.awayTeam)")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                // Locked Toggle
                HStack {
                    Text("Locked")
                        .foregroundColor(.textSecondary)
                    Button(action: onToggleLock) {
                        Image(systemName: game.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(game.isLocked ? .red : .green)
                    }
                }
                
                Spacer()
                
                // Visible Toggle
                HStack {
                    Text("Visible")
                        .foregroundColor(.textSecondary)
                    Button(action: onToggleVisibility) {
                        Image(systemName: game.isVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(game.isVisible ? .green : .gray)
                    }
                }
            }
            
            if let lastUpdated = game.lastUpdatedAt {
                Text("Last updated: \(lastUpdated.formatted())")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GameSelectorView: View {
    let games: [Game]
    let onSelect: (Game) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(games) { game in
                Button(action: {
                    onSelect(game)
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text("\(game.homeTeam) vs \(game.awayTeam)")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(game.time.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Select Featured Game")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        AdminGameManagementView()
    }
}
