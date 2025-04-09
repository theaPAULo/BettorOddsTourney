//
//  GameCard.swift
//  BettorOdds
//
//  Version: 2.2.0 - Added winning team and score display
//  Updated: February 2025 test

import SwiftUI

struct GameCard: View {
    // MARK: - Properties
    let game: Game
    let isFeatured: Bool
    let onSelect: () -> Void
    @Binding var globalSelectedTeam: (gameId: String, team: TeamSelection)?
    
    private var isTeamSelected: Bool {
        globalSelectedTeam?.gameId == game.id
    }
    
    private var selectedTeam: TeamSelection? {
        isTeamSelected ? globalSelectedTeam?.team : nil
    }
    
    private var gradientOverlay: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                game.awayTeamColors.primary.opacity(0.9),
                game.awayTeamColors.secondary.opacity(0.7),
                game.homeTeamColors.secondary.opacity(0.7),
                game.homeTeamColors.primary.opacity(0.9)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Lock Status Components
    private var lockOverlay: some View {
        Group {
            if game.shouldBeLocked || game.isLocked {
                // Show lock overlay for locked games
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        VStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(.top, 40)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        game.awayTeamColors.primary.opacity(0.4),
                        game.homeTeamColors.primary.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1
            )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(spacing: 0) {
                // Header with League and Time
                HStack {
                    // League Badge
                    Text(game.league)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Game Status Badge
                    GameStatusBadge(status: game.status)
                    
                    // Game Time
                    if game.status == .upcoming {
                        HStack(spacing: 4) {
                            Text(game.formattedDateTime)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Teams and Scores
                HStack(spacing: 0) {
                    // Away Team
                    TeamButton(
                        game: game,
                        teamName: game.awayTeam,
                        spread: game.awaySpread,
                        isSelected: selectedTeam == .away,
                        teamColors: game.awayTeamColors,
                        score: game.score,
                        isHomeTeam: false,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                globalSelectedTeam = (game.id, .away)
                            }
                            hapticFeedback()
                            onSelect()
                        }
                    )
                    
                    // VS Badge
                    Text("@")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.2))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        )
                    
                    // Home Team
                    TeamButton(
                        game: game,
                        teamName: game.homeTeam,
                        spread: game.homeSpread,
                        isSelected: selectedTeam == .home,
                        teamColors: game.homeTeamColors,
                        score: game.score,
                        isHomeTeam: true,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                globalSelectedTeam = (game.id, .home)
                            }
                            hapticFeedback()
                            onSelect()
                        }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
            .background(gradientOverlay)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(cardBorder)
        .shadow(
            color: Color.backgroundPrimary.opacity(0.2),
            radius: 10,
            x: 0,
            y: 4
        )
        .lockWarning(for: game)
        .overlay(lockOverlay)
        .opacity(game.shouldBeLocked || game.isLocked ? 0.7 : 1.0)
        .disabled(game.shouldBeLocked || game.isLocked)
        .onTapGesture {
            if !game.shouldBeLocked && !game.isLocked {
                onSelect()
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Team Button Component
struct TeamButton: View {
    // MARK: - Properties
    let game: Game  // Added game property
    let teamName: String
    let spread: String
    let isSelected: Bool
    let teamColors: TeamColors
    let score: GameScore?
    let isHomeTeam: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Team Name with potential winning checkmark
                HStack(spacing: 4) {
                    Text(teamName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2, reservesSpace: true)
                        .minimumScaleFactor(0.8)
                    
                    if game.isCompleted && game.winningTeam == teamName {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                    }
                }
                
                if let score = score {
                    // Show final score
                    Text("\(isHomeTeam ? score.homeScore : score.awayScore)")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                } else {
                    // Show spread for upcoming games
                    Text(spread)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        Color.white.opacity(0.2)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Modifier for Press Events
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview Provider
#Preview {
    VStack(spacing: 20) {
        GameCard(
            game: Game.sampleGames[0],
            isFeatured: true,
            onSelect: {},
            globalSelectedTeam: .constant(nil)
        )
        
        // Preview with selected team
        GameCard(
            game: Game.sampleGames[1],
            isFeatured: false,
            onSelect: {},
            globalSelectedTeam: .constant((Game.sampleGames[1].id, .home))
        )
        
        // Preview locked state
        GameCard(
            game: {
                var game = Game.sampleGames[0]
                return game
            }(),
            isFeatured: false,
            onSelect: {},
            globalSelectedTeam: .constant(nil)
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}
