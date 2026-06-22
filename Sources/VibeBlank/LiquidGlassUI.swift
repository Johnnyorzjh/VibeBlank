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
            opacity = 0.048
        case (.dark, .header), (.dark, .menu):
            opacity = 0.044
        case (.dark, .card), (.dark, .onboarding):
            opacity = 0.036
        case (.dark, .control), (.dark, .menuItem), (.dark, .hud):
            opacity = 0.060
        case (.dark, .footer):
            opacity = 0.040
        case (_, .sidebar), (_, .rail):
            opacity = 0.055
        case (_, .header), (_, .menu):
            opacity = 0.060
        case (_, .card), (_, .onboarding):
            opacity = 0.048
        case (_, .control), (_, .menuItem):
            return Color.black.opacity(0.034 * contrastBoost)
        case (_, .hud):
            opacity = 0.085
        case (_, .footer):
            opacity = 0.050
        }
        return Color.white.opacity(min(0.18, opacity * contrastBoost))
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
            return 0.84
        case (.dark, _):
            return 0.76
        case (_, .control), (_, .menuItem), (_, .hud):
            return 0.86
        case (_, .header), (_, .sidebar), (_, .rail), (_, .menu):
            return 0.80
        case (_, .card), (_, .footer), (_, .onboarding):
            return 0.72
        }
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
        return colorScheme == .dark ? Color.white.opacity(0.085) : Color.white.opacity(0.22)
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
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
            .scaleEffect(shouldHighlight && isProminent ? 1.006 : 1)
            .contentShape(shape)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: shouldHighlight)
            .onHover { isHovered = $0 }
    }

    private func hoverFill(increasedContrast: Bool) -> Color {
        if reduceTransparency {
            return Color(nsColor: .selectedContentBackgroundColor).opacity(increasedContrast ? 0.16 : 0.10)
        }
        if colorScheme == .dark {
            return Color.white.opacity(increasedContrast ? 0.075 : 0.044)
        }
        return Color.white.opacity(increasedContrast ? 0.26 : 0.17)
    }
}

