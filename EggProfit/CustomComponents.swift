import SwiftUI

// Enhanced Toast with slide-in and glow
struct Toast: View {
    let message: String
    @Binding var show: Bool
    @State private var offset: CGFloat = 100
    
    var body: some View {
        if show {
            VStack {
                Text(message)
                    .foregroundColor(.designSystem(.textPrimary))
                    .padding()
                    .background(Color.designSystem(.accentYellow))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.designSystem(.accentOrange), lineWidth: 1))
                    .offset(y: offset)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                offset = 100
                                show = false
                            }
                        }
                    }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}



struct FieryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    @State private var fireIntensity = 0.0
    @State private var rotation = 0.0
    
    var body: some View {
        Button(action: {
            DesignSystem.haptic(.medium)
            DesignSystem.successHaptic()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isPressed = true
                fireIntensity = 1.0
                rotation = 1.0
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                    fireIntensity = 0.0
                    rotation = 0.0
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(Color.design(.accentOrange))
                    .frame(minWidth: 200, minHeight: 50)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .rotationEffect(.degrees(rotation))
                
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(DesignSystem.GradientToken.buttonFire.gradient)
                    .frame(width: 200 + fireIntensity * 20, height: 50 + fireIntensity * 10)
                    .blur(radius: 10 * fireIntensity)
                    .offset(y: -fireIntensity * 5)
                
                Text(title)
                    .font(.nunito(size: 18, weight: .bold))
                    .foregroundColor(.design(.textPrimary))
                    .multilineTextAlignment(.center)
            }
            .fieryShadow(.buttonGlow)
            .gradientBorder(.fieryMain)
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

struct PremiumCard<Content: View>: View {
    let title: String?
    let content: Content
    @State private var scale: CGFloat = 0.95
    @State private var opacity: Double = 0.0
    let delay: Double
    
    init(title: String? = nil, delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        self.delay = delay
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            if let title = title {
                Text(title)
                    .font(.inter(size: 18, weight: .medium))
                    .foregroundColor(.design(.textPrimary))
                    .padding(.bottom, DesignSystem.Spacing.s)
            }
            content
        }
        .padding(DesignSystem.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(Color.design(.cardBackground))
                .glassmorphism()
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                        .stroke(Color.fieryGradient, lineWidth: 1)
                )
                .blur(radius: 2)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .fieryShadow(.cardOuter)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

struct EnhancedLineChart: View {
    let data: [Double]
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    let points = data.enumerated().map { (i, value) in
                        CGPoint(x: geo.size.width * CGFloat(i) / CGFloat(data.count - 1),
                                y: geo.size.height * (1 - CGFloat(value / (data.max() ?? 1))))
                    }
                    path.move(to: points.first ?? .zero)
                    path.addLines(points)
                    path.addLine(to: CGPoint(x: points.last?.x ?? geo.size.width, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(Color.fieryGradient.opacity(0.3))
                .animation(.easeInOut(duration: 1.2), value: animate)
                
                Path { path in
                    let points = data.enumerated().map { (i, value) in
                        CGPoint(x: geo.size.width * CGFloat(i) / CGFloat(data.count - 1),
                                y: geo.size.height * (1 - CGFloat(value / (data.max() ?? 1))))
                    }
                    path.move(to: points.first ?? .zero)
                    for i in 1..<points.count {
                        let previous = points[i-1]
                        let current = points[i]
                        let control1 = CGPoint(x: previous.x + (current.x - previous.x)/3, y: previous.y)
                        let control2 = CGPoint(x: current.x - (current.x - previous.x)/3, y: current.y)
                        path.addQuadCurve(to: current, control: control1)
                    }
                }
                .stroke(Color.design(.accentYellow), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .animation(.easeInOut(duration: 1.0).delay(0.2), value: animate)
                
                Color.glowGradient
                    .mask(
                        Path { path in
                            let points = data.enumerated().map { (i, value) in
                                CGPoint(x: geo.size.width * CGFloat(i) / CGFloat(data.count - 1),
                                        y: geo.size.height * (1 - CGFloat(value / (data.max() ?? 1))))
                            }
                            path.move(to: points.first ?? .zero)
                            for i in 1..<points.count {
                                let previous = points[i-1]
                                let current = points[i]
                                let control1 = CGPoint(x: previous.x + (current.x - previous.x)/3, y: previous.y)
                                let control2 = CGPoint(x: current.x - (current.x - previous.x)/3, y: current.y)
                                path.addQuadCurve(to: current, control: control1)
                            }
                        }
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    )
                    .opacity(animate ? 0.5 : 0)
                    .animation(.easeInOut(duration: 0.8), value: animate)
            }
        }
        .frame(height: 120)
        .onAppear {
            animate = true
        }
    }
}

struct EnhancedBarChart: View {
    let categories: [String]
    let values: [Double]
    @State private var animateHeights: [CGFloat]
    
    init(categories: [String], values: [Double]) {
        self.categories = categories
        self.values = values
        self._animateHeights = State(initialValue: Array(repeating: 0, count: values.count))
    }
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: DesignSystem.Spacing.s) {
                ForEach(Array(zip(categories.indices, values)), id: \.0) { i, value in
                    VStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.fieryGradient)
                            .frame(width: 30, height: animateHeights[i])
                            .scaleEffect(y: animateHeights[i] > 0 ? 1 : 0, anchor: .bottom)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(Double(i) * 0.1), value: animateHeights[i])
                        
                        Text(categories[i])
                            .font(.inter(size: 10, weight: .medium))
                            .foregroundColor(.design(.textSecondary))
                            .frame(height: 20)
                    }
                    .onAppear {
                        animateHeights[i] = CGFloat(value / (values.max() ?? 1) * 100)
                    }
                }
            }
        }
        .frame(height: 100)
    }
}

struct PremiumToast: View {
    let message: String
    @Binding var show: Bool
    @State private var offset: CGFloat = 100
    
    var body: some View {
        if show {
            VStack {
                Spacer()
                HStack {
                    Text(message)
                        .font(.nunito(size: 14, weight: .medium))
                        .foregroundColor(.design(.textPrimary))
                    Spacer()
                }
                .padding()
                .background(Color.design(.accentYellow))
                .cornerRadius(DesignSystem.Radius.medium)
                .gradientBorder(.fieryMain)
                .fieryShadow(.fireTrail)
                .offset(y: offset)
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.spring(response: 0.5)) {
                            offset = 100
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            show = false
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.l)
        }
    }
}

struct PremiumEmptyState: View {
    let message: String
    let icon: String
    let action: () -> Void
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.design(.accentOrange), Color.design(.accentYellow))
                .scaleEffect(iconScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        iconScale = 1.05
                    }
                }
                .fieryShadow(.iconSoft)
            
            Text(message)
                .font(.inter(size: 16, weight: .medium))
                .foregroundColor(.design(.textSecondary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.l)
            
            FieryButton(title: "Get Started") {
                action()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
