import SwiftUI
import UIKit

extension Color {
    static let backgroundDark = Color(hex: "#1A0E0B")
    static let cardBackground = Color(hex: "#2B1310")
    static let accentOrange = Color(hex: "#FF7A1A")
    static let accentYellow = Color(hex: "#FFD93D")
    static let alertRed = Color(hex: "#FF3B30")
    static let successGreen = Color(hex: "#E6FF6A")
    static let textPrimary = Color(hex: "#FFF6E8")
    static let textSecondary = Color(hex: "#C9B9A8")
    
    static let fieryGradient = LinearGradient(gradient: Gradient(colors: [.accentOrange, .alertRed]), startPoint: .topLeading, endPoint: .bottomTrailing)
    static let glowGradient = RadialGradient(gradient: Gradient(colors: [.accentYellow.opacity(0.5), .clear]), center: .center, startRadius: 0, endRadius: 100)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    
    static func designSystem(_ token: DesignSystem.ColorToken) -> Color {
        token.color
    }
    
}

extension View {
    func toast(show: Binding<Bool>, message: String) -> some View {
        self.overlay(
            Toast(message: message, show: show)
        )
    }
}

struct DesignSystem {
    enum ColorToken: CaseIterable {
        case backgroundDark, cardBackground, accentOrange, accentYellow, alertRed, successLime, textPrimary, textSecondary
        
        var color: Color {
            switch self {
            case .backgroundDark: return Color(hex: "#1A0E0B")
            case .cardBackground: return Color(hex: "#2B1310")
            case .accentOrange: return Color(hex: "#FF7A1A")
            case .accentYellow: return Color(hex: "#FFD93D")
            case .alertRed: return Color(hex: "#FF3B30")
            case .successLime: return Color(hex: "#E6FF6A")
            case .textPrimary: return Color(hex: "#FFF6E8")
            case .textSecondary: return Color(hex: "#C9B9A8")
            }
        }
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    enum ShadowToken {
        case cardOuter, iconSoft, buttonGlow, fireTrail
        
        var shadow: Shadow {
            switch self {
            case .cardOuter: return .init(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            case .iconSoft: return .init(color: .design(.accentOrange).opacity(0.3), radius: 8, x: 0, y: 4)
            case .buttonGlow: return .init(color: .design(.accentYellow).opacity(0.6), radius: 15, x: 0, y: 0)
            case .fireTrail: return .init(color: .design(.alertRed).opacity(0.4), radius: 25, x: 0, y: 0)
            }
        }
    }
    
    enum GradientToken {
        case fieryMain, cardBorder, buttonFire, chartGlow
        
        var gradient: Gradient {
            switch self {
            case .fieryMain: return Gradient(colors: [.design(.accentOrange), .design(.alertRed)])
            case .cardBorder: return Gradient(colors: [.design(.accentOrange).opacity(0.3), .clear])
            case .buttonFire: return Gradient(colors: [.design(.accentYellow), .design(.accentOrange), .design(.alertRed)])
            case .chartGlow: return Gradient(colors: [.design(.accentYellow).opacity(0.8), .clear])
            }
        }
    }
    
    enum Spacing { static let xs = 4.0, s = 8.0, m = 16.0, l = 24.0, xl = 32.0 }
    enum Radius { static let small = 8.0, medium = 12.0, large = 20.0 }
    
    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension Color {
    static func design(_ token: DesignSystem.ColorToken) -> Color { token.color }

    static let cardBorderGradient = AngularGradient(gradient: DesignSystem.GradientToken.cardBorder.gradient, center: .center)
}

extension Font {
    static func inter(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter-\(weight == .regular ? "Regular" : weight == .medium ? "Medium" : "Bold")", size: size)
    }
    static func nunito(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Nunito-\(weight == .regular ? "Regular" : weight == .medium ? "Medium" : "Bold")", size: size)
    }
}

extension View {
    func fieryShadow(_ token: DesignSystem.ShadowToken) -> some View {
        let shadow = token.shadow
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func gradientBorder(_ token: DesignSystem.GradientToken) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(AngularGradient(gradient: token.gradient, center: .center), lineWidth: 2)
        )
    }
    
    func glassmorphism() -> some View {
        self.background(.ultraThinMaterial)
            .overlay(Color.design(.cardBackground).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
    }
}
