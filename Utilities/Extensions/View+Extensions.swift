//
//  View+Extensions.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.1.0
//

import SwiftUI

// MARK: - View Modifiers
extension View {
    // Note: withAnimatedBackground() is defined in AnimatedBackground.swift
    
    /// Wraps a view in a modern card style
    func modernCard(hasHapticFeedback: Bool = true) -> some View {
        ModernCard(hasHapticFeedback: hasHapticFeedback) {
            self
        }
    }
    
    /// Applies a shimmering effect to a view (for loading states)
    func shimmering() -> some View {
        modifier(ShimmeringView())
    }
    
    /// Applies a standard shadow to a view
    func standardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    /// Applies an elevated shadow to a view
    func elevatedShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.15),
            radius: 15,
            x: 0,
            y: 8
        )
    }
    
    /// Applies standard corner radius to a view
    func standardCornerRadius() -> some View {
        self.cornerRadius(12)
    }
    
    /// Applies corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Applies modifier if condition is met
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Triggers haptic feedback
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Shows a loading state overlay
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            }
        )
        .disabled(isLoading)
    }
}

// MARK: - Helper Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Shimmer Effect
struct ShimmeringView: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.5),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .position(x: proxy.size.width * phase - proxy.size.width,
                            y: proxy.size.height / 2)
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .onAppear {
                phase = 2
            }
    }
}
