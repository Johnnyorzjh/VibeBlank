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

            if let text = overlayText {
                Text(text)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(48)
                    .opacity(transition.phase == .visible ? 1 : 0)
            }
        }
        .onReceive(timer) { value in
            now = value
        }
    }

    private var overlayText: String? {
        switch settings.overlayContentMode {
        case .blank:
            return nil
        case .time:
            return formattedTime
        case .statusText:
            return "黑码码已开启"
        case .customText:
            return settings.sanitizedCustomText
        case .particleTimer:
            return ElapsedTimerFormatter.string(elapsedSeconds: elapsedSeconds)
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
}
