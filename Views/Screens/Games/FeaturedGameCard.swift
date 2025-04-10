// FeaturedGameCard.swift
// Version: 2.0.0
// Updated design for featured game cards

import SwiftUI

struct FeaturedGameCard: View {
    let game: Game
    let onSelect: () -> Void
    
    @State private var isGlowing = false // For animation
    
    var body: some View {
        GameCard(
            game: game,
            isFeatured: true,
            onSelect: onSelect,
            globalSelectedTeam: .constant(nil)
        )
        .overlay(
            // Featured badge with star
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 2, x: 0, y: 0)
                
                Text("Featured")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "#00E6CA").opacity(0.9), // Your app's primary color
                        Color(hex: "#00E6CA").opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            .padding(12),
            alignment: .topLeading
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#00E6CA").opacity(isGlowing ? 0.7 : 0.3),
                            Color(hex: "#00E6CA").opacity(isGlowing ? 0.4 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: Color(hex: "#00E6CA").opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

#Preview {
    // Import Game+Samples to access the sample games
    let game = Game(
        id: "sample-game-1",
        homeTeam: "Lakers",
        awayTeam: "Warriors",
        time: Date().addingTimeInterval(3600 * 3), // 3 hours from now
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
    
    return FeaturedGameCard(
        game: game,
        onSelect: {}
    )
    .padding()
}
