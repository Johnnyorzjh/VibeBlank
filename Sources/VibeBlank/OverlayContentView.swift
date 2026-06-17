import SwiftUI
import VibeBlankCore

struct OverlayContentView: View {
    let settings: AppSettings
    @ObservedObject var transition: OverlayTransitionModel

    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            EdgeCollapseShape(progress: min(1, transition.coverage + 0.045))
                .fill(Color.black.opacity(0.34), style: FillStyle(eoFill: true))
                .ignoresSafeArea()

            EdgeCollapseShape(progress: transition.coverage)
                .fill(Color.black, style: FillStyle(eoFill: true))
                .ignoresSafeArea()

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
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: now)
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
