//
//  StatusBadge.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/30/25.
//  Updated by Paul Soni on 4/9/25
//  Version: 2.0.0 - Modified for tournament system
//

import SwiftUI

struct StatusBadge: View {
    // MARK: - Properties
    let status: BetStatus
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 12))
            
            Text(status.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Legacy Status Handling
    // This handles any old status types from the P2P system during migration
    init(status: BetStatus) {
        // Map any legacy status to current ones
        switch status.rawValue {
        case "Partially Matched":
            self.status = .pending
        default:
            self.status = status
        }
    }
}
