//
//  AppTheme.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import SwiftUI

/// AppTheme: Central theme configuration for the entire app
struct AppTheme {
    /// Brand Colors
    struct Brand {
        static let primary = Color("Primary", bundle: nil) // Turquoise #00E6CA
        static let primaryDark = Color("PrimaryDark", bundle: nil) // Darker turquoise #00B5A0
        static let secondary = Color("Secondary", bundle: nil) // Blue #4B56D2
        static let secondaryDark = Color("SecondaryDark", bundle: nil) // Darker blue #3A42A0
    }
    
    /// Background Colors
    struct Background {
        static let primary = Color("BackgroundPrimary", bundle: nil) // Dark #1A1A1A
        static let secondary = Color("BackgroundSecondary", bundle: nil) // Slightly lighter #2A2A2A
        static let card = Color("BackgroundCard", bundle: nil) // Card background #333333
    }
    
    /// Text Colors
    struct Text {
        static let primary = Color("TextPrimary", bundle: nil) // White #FFFFFF
        static let secondary = Color("TextSecondary", bundle: nil) // Light gray #B0B0B0
        static let accent = Color("TextAccent", bundle: nil) // Turquoise #00E6CA
    }
    
    /// Status Colors
    struct Status {
        static let success = Color("StatusSuccess", bundle: nil) // Green #4CAF50
        static let warning = Color("StatusWarning", bundle: nil) // Yellow #FFC107
        static let error = Color("StatusError", bundle: nil) // Red #FF5252
    }
    
    /// Coin Colors
    struct Coins {
        static let yellow = Color("CoinYellow", bundle: nil) // #FFD700
        static let green = Color("CoinGreen", bundle: nil) // #00C853
    }
    
    /// Border and Shadow Colors
    struct Border {
        static let primary = Color("BorderPrimary", bundle: nil) // #404040
        static let shadow = Color.black.opacity(0.1)
    }
}

/// Color Extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


// MARK: - Color Extensions
// Renamed to avoid conflicts with AppTheme in Theme.swift
extension Color {
    // Colors are now prefixed with "theme" to avoid conflicts
    static var themeTextPrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var themeTextSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "A0A0A0") : UIColor(hex: "666666")
        })
    }
    
    static var themeBackgroundPrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "1A1A1A") : .white
        })
    }
    
    static var themeBackgroundSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "2A2A2A") : UIColor(hex: "F5F5F5")
        })
    }
    
    static var themePrimary: Color {
        Color(hex: "00E6CA")
    }
    
    static var themeSecondary: Color {
        Color(hex: "4B56D2")
    }
    
    static var themeStatusSuccess: Color {
        Color(hex: "4CAF50")
    }
    
    static var themeStatusWarning: Color {
        Color(hex: "FFC107")
    }
    
    static var themeStatusError: Color {
        Color(hex: "FF5252")
    }
}

// Keep the UIColor extension as is
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}


