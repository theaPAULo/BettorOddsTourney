//
//  Game+Samples.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  Game+Samples.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//  Version: 1.0.0
//

import Foundation

// MARK: - Sample Data Extension
extension Game {
    /// Sample games for SwiftUI previews
    static var sampleGames: [Game] {
        [
            // Sample Game 1 (Upcoming)
            Game(
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
            ),
            
            // Sample Game 2 (About to Start)
            Game(
                id: "sample-game-2",
                homeTeam: "Celtics",
                awayTeam: "Nets",
                time: Date().addingTimeInterval(60 * 4), // 4 minutes from now
                league: "NBA",
                spread: 2.5,
                totalBets: 22,
                homeTeamColors: TeamColors.getTeamColors("Celtics"),
                awayTeamColors: TeamColors.getTeamColors("Nets"),
                isFeatured: false,
                manuallyFeatured: false,
                isVisible: true,
                isLocked: false
            ),
            
            // Sample Game 3 (Locked)
            Game(
                id: "sample-game-3",
                homeTeam: "Heat",
                awayTeam: "Bulls",
                time: Date().addingTimeInterval(-60 * 5), // Started 5 minutes ago
                league: "NBA",
                spread: -1.0,
                totalBets: 45,
                homeTeamColors: TeamColors.getTeamColors("Heat"),
                awayTeamColors: TeamColors.getTeamColors("Bulls"),
                isFeatured: false,
                manuallyFeatured: false,
                isVisible: true,
                isLocked: true
            ),
            
            // Sample Game 4 (Finished with Score)
            {
                var game = Game(
                    id: "sample-game-4",
                    homeTeam: "Bucks",
                    awayTeam: "76ers",
                    time: Date().addingTimeInterval(-3600 * 3), // 3 hours ago
                    league: "NBA",
                    spread: 3.0,
                    totalBets: 78,
                    homeTeamColors: TeamColors.getTeamColors("Bucks"),
                    awayTeamColors: TeamColors.getTeamColors("76ers"),
                    isFeatured: false,
                    manuallyFeatured: false,
                    isVisible: true,
                    isLocked: true
                )
                
                // Add score
                game.score = GameScore(
                    gameId: "sample-game-4",
                    homeScore: 112,
                    awayScore: 104,
                    finalizedAt: Date().addingTimeInterval(-3600 * 1), // 1 hour ago
                    verifiedAt: Date()
                )
                
                return game
            }()
        ]
    }
}