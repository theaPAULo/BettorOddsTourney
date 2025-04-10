//
//  GamesHeaderView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//


//
//  GamesHeaderView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

struct GamesHeaderView: View {
    let balance: Double
    let dailyTotal: Double
    let dailyLimit: Double = 100  // $100 daily limit
    
    var body: some View {
        HStack {
            Text("BettorOdds")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("Primary"))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$ \(String(format: "%.0f", balance))")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Daily Total: $\(String(format: "%.0f", dailyTotal))/\(String(format: "%.0f", dailyLimit))")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}