import SwiftUI
import VibeBlankCore

struct OverlayContentView: View {
    let settings: AppSettings

    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let text = overlayText {
                Text(text)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(48)
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
            return "VibeBlank Active"
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
