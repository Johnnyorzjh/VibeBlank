import SwiftUI
import VibeBlankCore

struct OverlayBackgroundView: View {
    let style: OverlayBackgroundStyle
    @ObservedObject var transition: OverlayTransitionModel

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            EdgeCollapseShape(progress: min(1, transition.coverage + 0.045))
                .fill(edgeShadowColor, style: FillStyle(eoFill: true))
                .ignoresSafeArea()

            backgroundLayer
                .mask {
                    EdgeCollapseShape(progress: transition.coverage)
                        .fill(style: FillStyle(eoFill: true))
                }
                .ignoresSafeArea()

            EdgeCollapseShape(progress: transition.coverage)
                .fill(primaryFillColor, style: FillStyle(eoFill: true))
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch style {
        case .pureBlack:
            Color.black
        case .whiteGlass:
            ZStack {
                NativeGlassSurface(material: .hudWindow, blendingMode: .behindWindow)
                Color.white.opacity(0.64)
                Color.black.opacity(0.10)
            }
        case .blackGlass:
            ZStack {
                NativeGlassSurface(material: .fullScreenUI, blendingMode: .behindWindow)
                Color.black.opacity(0.82)
                Color.white.opacity(0.035)
            }
        }
    }

    private var edgeShadowColor: Color {
        switch style {
        case .pureBlack:
            return Color.black.opacity(0.34)
        case .whiteGlass:
            return Color.white.opacity(0.30)
        case .blackGlass:
            return Color.black.opacity(0.42)
        }
    }

    private var primaryFillColor: Color {
        switch style {
        case .pureBlack:
            return .black
        case .whiteGlass:
            return Color.white.opacity(0.78)
        case .blackGlass:
            return Color.black.opacity(0.88)
        }
    }
}

private struct EdgeCollapseShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(1, max(0, progress))
        var path = Path()
        path.addRect(rect)

        guard clampedProgress < 0.995 else {
            return path
        }

        let hole = rect.insetBy(
            dx: rect.width * clampedProgress / 2,
            dy: rect.height * clampedProgress / 2
        )

        guard hole.width > 0, hole.height > 0 else {
            return path
        }

        path.addRoundedRect(
            in: hole,
            cornerSize: CGSize(
                width: min(rect.width, rect.height) * 0.04 * (1 - clampedProgress),
                height: min(rect.width, rect.height) * 0.04 * (1 - clampedProgress)
            )
        )
        return path
    }
}
