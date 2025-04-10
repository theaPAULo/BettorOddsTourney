//
//  GameStatusBadge.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/4/25.
//

import SwiftUI

// GameStatusBadge.swift - New component
struct GameStatusBadge: View {
    let status: GameStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Text(status.displayText)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.backgroundColor.opacity(0.15))
        .foregroundColor(status.textColor)
        .cornerRadius(8)
    }
}

extension GameStatus {
    var displayText: String {
        switch self {
        case .upcoming: return "UPCOMING"
        case .locked: return "STARTING SOON"
        case .inProgress: return "LIVE"
        case .completed: return "FINAL"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .upcoming: return .primary
        case .locked: return .gray
        case .inProgress: return .green
        case .completed: return .secondary
        }
    }
    
    var textColor: Color {
        switch self {
        case .upcoming: return .primary
        case .locked: return .gray
        case .inProgress: return .green
        case .completed: return .secondary
        }
    }
}
