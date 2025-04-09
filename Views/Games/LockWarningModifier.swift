// Updated version of Views/Games/LockWarningModifier.swift
// Version: 1.1.0 - Fixed deprecation warning
// Updated: April 2025

import SwiftUI

// Custom view modifier for lock warning animations
struct LockWarningModifier: ViewModifier {
    let game: Game
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if game.needsVisualIndicator {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .red.opacity(0.3 * game.visualIntensity),
                                        .orange.opacity(0.3 * game.visualIntensity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .scaleEffect(isPulsing ? 1.02 : 1.0)
                    }
                }
            )
            // Updated onChange syntax for iOS 17+
            .onChange(of: game.needsVisualIndicator) { _, needsIndicator in
                if needsIndicator {
                    startPulsing()
                }
            }
            .onAppear {
                if game.needsVisualIndicator {
                    startPulsing()
                }
            }
    }
    
    private func startPulsing() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
}

// Extend View to make the modifier easier to use
extension View {
    func lockWarning(for game: Game) -> some View {
        modifier(LockWarningModifier(game: game))
    }
}
