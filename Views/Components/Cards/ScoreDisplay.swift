//
//  ScoreDisplay.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/4/25.
//

import SwiftUI

// ScoreDisplay.swift
struct ScoreDisplay: View {
    let score: GameScore
    let isHomeTeam: Bool
    
    var body: some View {
        Text("\(isHomeTeam ? score.homeScore : score.awayScore)")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primary)
            .transition(.scale.combined(with: .opacity))
    }
}
