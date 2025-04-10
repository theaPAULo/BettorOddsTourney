//
//  ModernCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import SwiftUI

struct ModernCard<Content: View>: View {
    // MARK: - Properties
    let content: Content
    var hasHapticFeedback: Bool = true
    @State private var isPressed = false
    
    // MARK: - Initialization
    init(
        hasHapticFeedback: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.hasHapticFeedback = hasHapticFeedback
    }
    
    // MARK: - Body
    var body: some View {
        content
            .padding()
            .background(glassBackground)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                if hasHapticFeedback {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                
                withAnimation {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
    }
    
    // MARK: - Glass Background
    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .opacity(0.8)
                .blur(radius: 0.5)
            
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.5),
                            .white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

// MARK: - Card Modifier
struct ModernCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        ModernCard {
            content
        }
    }
}

// MARK: - View Extension
extension View {
    func modernCard() -> some View {
        modifier(ModernCardModifier())
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack(spacing: 20) {
            ModernCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sample Card")
                        .font(.headline)
                    Text("This is a modern card with glass effect")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Regular content")
                .modernCard()
        }
        .padding()
    }
}
