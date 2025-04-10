//
//  StatCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  StatCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Shared component
//

import SwiftUI

// Shared StatCard component to avoid redeclaration
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Preview
#Preview {
    StatCard(
        title: "Title",
        value: "Value",
        icon: "star.fill",
        color: .blue
    )
}