import AppKit
import SwiftUI
import VibeBlankCore

struct OverlayContentView: View {
    let settings: AppSettings
    @ObservedObject var transition: OverlayTransitionModel

    @State private var now = Date()
    @State private var activationDate = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            OverlayBackgroundView(style: settings.overlayBackgroundStyle, transition: transition)

            overlayContent
        }
        .onReceive(timer) { value in
            now = value
        }
        .liquidGlassPreferencesFromSystem()
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch settings.overlayContentMode {
        case .particleTimer:
            ParticleTimerView(
                text: ElapsedTimerFormatter.string(elapsedSeconds: elapsedSeconds),
                placement: settings.timerPlacement,
                backgroundStyle: settings.overlayBackgroundStyle
            )
            .opacity(transition.phase == .visible ? 1 : 0)
        case .blank, .time, .statusText, .customText:
            if let text = overlayText {
                Text(text)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(centeredTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .liquidGlassSurface(cornerRadius: 22, material: centeredTextMaterial, prominence: .hud)
                    .padding(48)
                    .opacity(transition.phase == .visible ? 1 : 0)
            }
        }
    }

    private var overlayText: String? {
        switch settings.overlayContentMode {
        case .blank, .particleTimer:
            return nil
        case .time:
            return formattedTime
        case .statusText:
            return "黑码码已开启"
        case .customText:
            return settings.sanitizedCustomText
        }
    }

    private var elapsedSeconds: Int {
        max(0, Int(now.timeIntervalSince(activationDate)))
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: now)
    }

    private var centeredTextColor: Color {
        switch settings.overlayBackgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.68)
        case .pureBlack, .blackGlass:
            return Color.white.opacity(0.72)
        }
    }

    private var centeredTextMaterial: NSVisualEffectView.Material {
        switch settings.overlayBackgroundStyle {
        case .whiteGlass:
            return .hudWindow
        case .pureBlack, .blackGlass:
            return .fullScreenUI
        }
    }
}
