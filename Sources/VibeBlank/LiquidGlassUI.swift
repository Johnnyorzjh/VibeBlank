import AppKit
import SwiftUI

enum LiquidGlassInterfaceLayout: Equatable {
    case regular
    case rail
    case compact

    var isCompact: Bool {
        self == .compact
    }
}

private struct LiquidGlassInterfaceLayoutKey: EnvironmentKey {
    static let defaultValue: LiquidGlassInterfaceLayout = .regular
}

extension EnvironmentValues {
    var liquidGlassInterfaceLayout: LiquidGlassInterfaceLayout {
        get { self[LiquidGlassInterfaceLayoutKey.self] }
        set { self[LiquidGlassInterfaceLayoutKey.self] = newValue }
    }
}

enum LiquidGlassProminence {
    case sidebar
    case rail
    case header
    case card
    case control
    case footer
    case menu
    case menuItem
    case onboarding
    case hud
}

typealias GlassProminence = LiquidGlassProminence

private struct LiquidGlassMotionPreferenceKey: EnvironmentKey {
    static let defaultValue = false
}

private struct LiquidGlassTransparencyPreferenceKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var liquidGlassReduceMotion: Bool {
        get { self[LiquidGlassMotionPreferenceKey.self] }
        set { self[LiquidGlassMotionPreferenceKey.self] = newValue }
    }

    var liquidGlassReduceTransparency: Bool {
        get { self[LiquidGlassTransparencyPreferenceKey.self] }
        set { self[LiquidGlassTransparencyPreferenceKey.self] = newValue }
    }
}

enum LiquidGlassPalette {
    static let accent = Color(nsColor: .systemBlue)
    static let privacyAccent = Color(nsColor: .systemGreen)
    static let primaryText = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)

    static func surfaceTint(
        _ colorScheme: ColorScheme,
        prominence: LiquidGlassProminence,
        reduceTransparency: Bool = false,
        increasedContrast: Bool = false
    ) -> Color {
        if reduceTransparency {
            let opacity = increasedContrast ? 0.96 : 0.90
            return Color(nsColor: .windowBackgroundColor).opacity(opacity)
        }

        let contrastBoost = increasedContrast ? 1.45 : 1.0
        let opacity: Double
        switch (colorScheme, prominence) {
        case (.dark, .sidebar), (.dark, .rail):
            opacity = 0.024
        case (.dark, .header), (.dark, .menu):
            opacity = 0.022
        case (.dark, .card), (.dark, .onboarding):
            opacity = 0.018
        case (.dark, .control), (.dark, .menuItem), (.dark, .hud):
            opacity = 0.034
        case (.dark, .footer):
            opacity = 0.022
        case (_, .sidebar), (_, .rail):
            opacity = 0.030
        case (_, .header), (_, .menu):
            opacity = 0.034
        case (_, .card), (_, .onboarding):
            opacity = 0.026
        case (_, .control), (_, .menuItem):
            return Color.white.opacity(0.042 * contrastBoost)
        case (_, .hud):
            opacity = 0.050
        case (_, .footer):
            opacity = 0.030
        }
        return Color.white.opacity(min(0.16, opacity * contrastBoost))
    }

    static func border(
        _ colorScheme: ColorScheme,
        reduceTransparency: Bool = false,
        increasedContrast: Bool = false
    ) -> Color {
        if increasedContrast {
            return colorScheme == .dark ? Color.white.opacity(0.36) : Color.black.opacity(0.24)
        }
        if reduceTransparency {
            return colorScheme == .dark ? Color.white.opacity(0.24) : Color.black.opacity(0.16)
        }
        return colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.36)
    }

    static func hairline(
        _ colorScheme: ColorScheme,
        reduceTransparency: Bool = false,
        increasedContrast: Bool = false
    ) -> Color {
        if increasedContrast {
            return colorScheme == .dark ? Color.white.opacity(0.28) : Color.black.opacity(0.16)
        }
        if reduceTransparency {
            return colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.10)
        }
        return colorScheme == .dark ? Color.white.opacity(0.085) : Color.black.opacity(0.052)
    }

    static func materialOpacity(
        _ colorScheme: ColorScheme,
        prominence: LiquidGlassProminence,
        reduceTransparency: Bool = false
    ) -> Double {
        if reduceTransparency {
            return 0.16
        }

        switch (colorScheme, prominence) {
        case (.dark, .control), (.dark, .menuItem), (.dark, .hud):
            return 0.92
        case (.dark, _):
            return 0.88
        case (_, .control), (_, .menuItem), (_, .hud):
            return 0.94
        case (_, .header), (_, .sidebar), (_, .rail), (_, .menu):
            return 0.91
        case (_, .card), (_, .footer), (_, .onboarding):
            return 0.86
        }
    }

    static func edgeGlow(_ colorScheme: ColorScheme, increasedContrast: Bool = false) -> Color {
        if increasedContrast {
            return colorScheme == .dark ? Color.white.opacity(0.30) : Color.white.opacity(0.42)
        }
        return colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.30)
    }

    static func hoverBloom(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.34)
    }
}

typealias GlassPalette = LiquidGlassPalette

extension View {
    func liquidGlassSurface(
        cornerRadius: CGFloat,
        material: NSVisualEffectView.Material,
        prominence: LiquidGlassProminence
    ) -> some View {
        modifier(
            LiquidGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                material: material,
                prominence: prominence
            )
        )
    }

    func liquidGlassControl(cornerRadius: CGFloat, isActive: Bool) -> some View {
        modifier(LiquidGlassControlModifier(cornerRadius: cornerRadius, isActive: isActive))
    }

    func brightGlass(
        cornerRadius: CGFloat,
        material: NSVisualEffectView.Material,
        prominence: LiquidGlassProminence
    ) -> some View {
        liquidGlassSurface(cornerRadius: cornerRadius, material: material, prominence: prominence)
    }

    func glassControl(cornerRadius: CGFloat, isActive: Bool) -> some View {
        liquidGlassControl(cornerRadius: cornerRadius, isActive: isActive)
    }

    func glassHoverExpansion(
        cornerRadius: CGFloat,
        isEnabled: Bool = true,
        isProminent: Bool = false
    ) -> some View {
        modifier(
            GlassHoverExpansion(
                cornerRadius: cornerRadius,
                isEnabled: isEnabled,
                isProminent: isProminent
            )
        )
    }

    func liquidGlassPreferencesFromSystem() -> some View {
        modifier(LiquidGlassSystemPreferenceModifier())
    }
}

private struct LiquidGlassSystemPreferenceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .environment(\.liquidGlassReduceMotion, reduceMotion)
            .environment(\.liquidGlassReduceTransparency, reduceTransparency)
    }
}

private struct LiquidGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let material: NSVisualEffectView.Material
    let prominence: LiquidGlassProminence

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let increasedContrast = colorSchemeContrast == .increased

        content
            .background {
                NativeGlassSurface(material: material, blendingMode: .behindWindow)
                    .clipShape(shape)
                    .opacity(
                        LiquidGlassPalette.materialOpacity(
                            colorScheme,
                            prominence: prominence,
                            reduceTransparency: reduceTransparency
                        )
                    )
            }
            .background {
                shape.fill(
                    LiquidGlassPalette.surfaceTint(
                        colorScheme,
                        prominence: prominence,
                        reduceTransparency: reduceTransparency,
                        increasedContrast: increasedContrast
                    )
                )
            }
            .overlay {
                shape.stroke(
                    LiquidGlassPalette.border(
                        colorScheme,
                        reduceTransparency: reduceTransparency,
                        increasedContrast: increasedContrast
                    ),
                    lineWidth: borderWidth(increasedContrast: increasedContrast)
                )
            }
            .overlay(alignment: .topLeading) {
                shape
                    .stroke(topHighlight(increasedContrast: increasedContrast), lineWidth: 0.55)
                    .padding(0.55)
            }
            .overlay {
                LiquidGlassEdgeGlow(shape: shape, prominence: prominence)
            }
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    private func borderWidth(increasedContrast: Bool) -> CGFloat {
        if increasedContrast {
            return prominence == .control ? 0.8 : 1.05
        }
        return prominence == .control ? 0.55 : 0.82
    }

    private func topHighlight(increasedContrast: Bool) -> Color {
        if increasedContrast {
            return colorScheme == .dark ? Color.white.opacity(0.20) : Color.white.opacity(0.34)
        }
        return colorScheme == .dark ? Color.white.opacity(0.13) : Color.white.opacity(0.30)
    }

    private var shadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.18 : 0.070)
    }

    private var shadowRadius: CGFloat {
        switch prominence {
        case .sidebar, .rail:
            return 30
        case .header:
            return 24
        case .card, .onboarding:
            return 24
        case .menu:
            return 30
        case .menuItem, .control:
            return 10
        case .hud:
            return 22
        case .footer:
            return 18
        }
    }

    private var shadowY: CGFloat {
        switch prominence {
        case .sidebar, .rail:
            return 12
        case .header:
            return 7
        case .card, .onboarding:
            return 8
        case .menu:
            return 14
        case .menuItem, .control:
            return 3
        case .hud:
            return 9
        case .footer:
            return 6
        }
    }
}

private struct LiquidGlassEdgeGlow<S: InsettableShape>: View {
    let shape: S
    let prominence: LiquidGlassProminence
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.liquidGlassReduceTransparency) private var reduceTransparency

    var body: some View {
        if !reduceTransparency {
            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            LiquidGlassPalette.edgeGlow(
                                colorScheme,
                                increasedContrast: colorSchemeContrast == .increased
                            ),
                            Color.white.opacity(colorScheme == .dark ? 0.035 : 0.090),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: prominence == .control ? 0.7 : 1.0
                )
                .blendMode(.screen)
        }
    }
}

private struct LiquidGlassControlModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isActive: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let increasedContrast = colorSchemeContrast == .increased

        content
            .background {
                shape.fill(fill(increasedContrast: increasedContrast))
            }
            .overlay {
                shape.stroke(
                    LiquidGlassPalette.hairline(
                        colorScheme,
                        reduceTransparency: reduceTransparency,
                        increasedContrast: increasedContrast
                    ),
                    lineWidth: increasedContrast ? 0.85 : 0.6
                )
            }
    }

    private func fill(increasedContrast: Bool) -> Color {
        if reduceTransparency {
            return Color(nsColor: .controlBackgroundColor).opacity(increasedContrast ? 0.96 : 0.86)
        }
        if isActive {
            return LiquidGlassPalette.accent.opacity(colorScheme == .dark ? 0.16 : 0.13)
        }
        return colorScheme == .dark ? Color.white.opacity(0.056) : Color.black.opacity(0.040)
    }
}

struct GlassHoverExpansion: ViewModifier {
    let cornerRadius: CGFloat
    var isEnabled = true
    var isProminent = false

    @State private var isHovered = false
    @State private var shimmerOffset: CGFloat = -1.15
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.liquidGlassReduceMotion) private var reduceMotion
    @Environment(\.liquidGlassReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let shouldHighlight = isEnabled && isHovered
        let increasedContrast = colorSchemeContrast == .increased

        content
            .background {
                shape.fill(shouldHighlight ? hoverFill(increasedContrast: increasedContrast) : Color.clear)
            }
            .overlay {
                shape.stroke(
                    shouldHighlight
                        ? LiquidGlassPalette.border(
                            colorScheme,
                            reduceTransparency: reduceTransparency,
                            increasedContrast: increasedContrast
                        ).opacity(isProminent ? 0.92 : 0.58)
                        : Color.clear,
                    lineWidth: increasedContrast ? 0.9 : 0.7
                )
            }
            .overlay {
                if shouldHighlight && !reduceTransparency {
                    HoverShimmer(shape: shape, offset: shimmerOffset, isProminent: isProminent)
                }
            }
            .scaleEffect(shouldHighlight && isProminent ? 1.010 : 1)
            .contentShape(shape)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: shouldHighlight)
            .onHover { hovering in
                isHovered = hovering
                guard !reduceMotion else {
                    shimmerOffset = hovering ? 0.18 : -1.15
                    return
                }
                if hovering {
                    shimmerOffset = -1.15
                    withAnimation(.easeOut(duration: 0.72)) {
                        shimmerOffset = 1.20
                    }
                } else {
                    shimmerOffset = -1.15
                }
            }
    }

    private func hoverFill(increasedContrast: Bool) -> Color {
        if reduceTransparency {
            return Color(nsColor: .selectedContentBackgroundColor).opacity(increasedContrast ? 0.16 : 0.10)
        }
        if colorScheme == .dark {
            return Color.white.opacity(increasedContrast ? 0.095 : 0.058)
        }
        return Color.white.opacity(increasedContrast ? 0.32 : 0.22)
    }
}

private struct HoverShimmer<S: Shape>: View {
    let shape: S
    let offset: CGFloat
    let isProminent: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let height = max(proxy.size.height, 1)
            let travel = width + height

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12),
                            LiquidGlassPalette.hoverBloom(colorScheme).opacity(isProminent ? 1 : 0.74),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: max(36, width * 0.34), height: travel * 1.4)
                .rotationEffect(.degrees(23))
                .offset(x: -travel * 0.55 + travel * offset, y: -height * 0.42)
                .blur(radius: isProminent ? 5.5 : 4.0)
                .blendMode(.screen)
        }
        .clipShape(shape)
        .allowsHitTesting(false)
    }
}
