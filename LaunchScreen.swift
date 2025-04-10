//
//  LaunchScreen.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/5/25.
//


// Create new file: LaunchScreen.swift

import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Use our existing theme colors
            LinearGradient(
                colors: [
                    Color("Primary").opacity(0.2),
                    Color.white.opacity(0.1),
                    Color("Primary").opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("BettorOdds")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(Color("Primary"))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                // Show coins animation
                HStack(spacing: 16) {
                    Text("🟡")
                    Text("💚")
                }
                .font(.system(size: 24))
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}
