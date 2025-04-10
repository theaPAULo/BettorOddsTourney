//
//  AnimatedBackground.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import SwiftUI

struct AnimatedBackground: View {
    // MARK: - Properties
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    
    // MARK: - Color Sets
    private var colors: [Color] {
        colorScheme == .dark ? darkModeColors : lightModeColors
    }
    
    private let lightModeColors = [
        Color(hex: "#f8f9fa").opacity(0.8),
        Color(hex: "#e9ecef").opacity(0.8),
        Color(hex: "#dee2e6").opacity(0.8)
    ]
    
    private let darkModeColors = [
        Color(hex: "#212529").opacity(0.8),
        Color(hex: "#343a40").opacity(0.8),
        Color(hex: "#495057").opacity(0.8)
    ]
    
    // MARK: - Body
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .linear(duration: 5.0)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

#Preview {
    VStack {
        Text("Sample Content")
            .font(.title)
            .foregroundColor(.primary)
    }
    .background(AnimatedBackground()) // ✅ Correct way to apply the background
}
