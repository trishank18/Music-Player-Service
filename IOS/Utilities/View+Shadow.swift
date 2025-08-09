import SwiftUI
extension View {
    func cinematicShadow(
        color: Color = Color.black.opacity(0.3),
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    func cardShadow(
        color: Color = Color.black.opacity(0.1),
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    func dramaticShadow(
        color: Color = Color.black.opacity(0.5),
        radius: CGFloat = 20,
        x: CGFloat = 0,
        y: CGFloat = 10
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    func glowEffect(
        color: Color,
        radius: CGFloat = 10,
        opacity: Double = 0.6
    ) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
    func layeredShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    func floatingShadow(
        elevation: CGFloat = 8
    ) -> some View {
        self.shadow(
            color: Color.black.opacity(0.15),
            radius: elevation,
            x: 0,
            y: elevation / 2
        )
    }
    func themeShadow(
        style: ShadowStyle = .card
    ) -> some View {
        let themeColors = ThemeManager.shared.colors
        
        switch style {
        case .card:
            return AnyView(
                self.shadow(
                    color: themeColors.shadow,
                    radius: 6,
                    x: 0,
                    y: 3
                )
            )
        case .elevated:
            return AnyView(
                self.shadow(
                    color: themeColors.shadow,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            )
        case .dramatic:
            return AnyView(
                self.shadow(
                    color: themeColors.shadow.opacity(0.8),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            )
        case .subtle:
            return AnyView(
                self.shadow(
                    color: themeColors.shadow.opacity(0.5),
                    radius: 3,
                    x: 0,
                    y: 1
                )
            )
        case .glow:
            return AnyView(
                self.shadow(
                    color: themeColors.accent.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 0
                )
            )
        }
    }
}
enum ShadowStyle {
    case card
    case elevated
    case dramatic
    case subtle
    case glow
}
extension View {
    func glassmorphism(
        blurRadius: CGFloat = 10,
        shadowRadius: CGFloat = 8
    ) -> some View {
        self
            .background(.ultraThinMaterial)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }
    func neumorphism(
        lightShadowColor: Color = Color.white.opacity(0.5),
        darkShadowColor: Color = Color.black.opacity(0.2),
        radius: CGFloat = 8
    ) -> some View {
        self
            .shadow(color: lightShadowColor, radius: radius, x: -radius/2, y: -radius/2)
            .shadow(color: darkShadowColor, radius: radius, x: radius/2, y: radius/2)
    }
    func insetShadow(
        color: Color = Color.black.opacity(0.2),
        radius: CGFloat = 4
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(color, lineWidth: 1)
                .blur(radius: radius/2)
                .offset(x: 1, y: 1)
                .mask(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(LinearGradient(
                            colors: [Color.clear, Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
        )
    }
    func borderedShadow(
        borderColor: Color = Color.gray.opacity(0.3),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 8,
        shadowColor: Color = Color.black.opacity(0.1),
        shadowRadius: CGFloat = 4
    ) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
    }
    func floatingCard(
        cornerRadius: CGFloat = 12,
        shadowColor: Color = Color.black.opacity(0.1),
        shadowRadius: CGFloat = 8
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ThemeManager.shared.colors.surface)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
            )
    }
    func elevatedButton(
        pressedScale: CGFloat = 0.95,
        shadowRadius: CGFloat = 6
    ) -> some View {
        self
            .shadow(
                color: Color.black.opacity(0.2),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
            .scaleEffect(pressedScale)
    }
    func animatedShadow(
        isPressed: Bool,
        normalShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.2), 8, 0, 4),
        pressedShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.1), 2, 0, 1)
    ) -> some View {
        self.shadow(
            color: isPressed ? pressedShadow.color : normalShadow.color,
            radius: isPressed ? pressedShadow.radius : normalShadow.radius,
            x: isPressed ? pressedShadow.x : normalShadow.x,
            y: isPressed ? pressedShadow.y : normalShadow.y
        )
    }
}
extension View {
    func appleCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 4)
    }
    func materialShadow(elevation: MaterialElevation = .level2) -> some View {
        switch elevation {
        case .level1:
            return AnyView(
                self.shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                    .shadow(color: Color.black.opacity(0.24), radius: 2, x: 0, y: 1)
            )
        case .level2:
            return AnyView(
                self.shadow(color: Color.black.opacity(0.16), radius: 3, x: 0, y: 1)
                    .shadow(color: Color.black.opacity(0.23), radius: 6, x: 0, y: 3)
            )
        case .level3:
            return AnyView(
                self.shadow(color: Color.black.opacity(0.19), radius: 10, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.23), radius: 20, x: 0, y: 6)
            )
        case .level4:
            return AnyView(
                self.shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 5)
                    .shadow(color: Color.black.opacity(0.22), radius: 28, x: 0, y: 10)
            )
        case .level5:
            return AnyView(
                self.shadow(color: Color.black.opacity(0.30), radius: 19, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.22), radius: 38, x: 0, y: 15)
            )
        }
    }
    func noirShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    func ambientShadow(color: Color = ThemeManager.shared.colors.accent) -> some View {
        self
            .shadow(color: color.opacity(0.2), radius: 15, x: 0, y: 0)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
enum MaterialElevation {
    case level1, level2, level3, level4, level5
}
extension View {
    func albumArtShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    func playerControlShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
    func miniPlayerShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -1)
    }
    func navigationBarShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    func tabBarShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    func modalShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
    }
    func buttonHoverShadow(isHovered: Bool) -> some View {
        self.shadow(
            color: Color.black.opacity(isHovered ? 0.2 : 0.1),
            radius: isHovered ? 8 : 4,
            x: 0,
            y: isHovered ? 4 : 2
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: 200, height: 100)
            .cardShadow()
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.blue)
            .frame(width: 200, height: 100)
            .dramaticShadow()
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.purple)
            .frame(width: 200, height: 100)
            .glowEffect(color: .purple)
        RoundedRectangle(cornerRadius: 12)
            .fill(ThemeManager.shared.colors.surface)
            .frame(width: 200, height: 100)
            .themeShadow(style: .elevated)
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.green)
            .frame(width: 200, height: 100)
            .materialShadow(elevation: .level3)
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black)
            .frame(width: 200, height: 100)
            .noirShadow()
    }
    .padding()
    .background(ThemeManager.shared.colors.background)
}
