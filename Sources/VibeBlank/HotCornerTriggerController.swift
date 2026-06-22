import AppKit
import VibeBlankCore

@MainActor
final class HotCornerTriggerController {
    var onTriggered: (() -> Void)?

    private var settings: CornerTriggerSettings = .defaults
    private var evaluator = HotCornerPushEvaluator()
    private var timer: Timer?

    deinit {
        timer?.invalidate()
    }

    func update(settings: CornerTriggerSettings) {
        self.settings = settings
        evaluator.reset()

        if settings.isEnabled {
            start()
        } else {
            stop()
        }
    }

    private func start() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard settings.isEnabled else {
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens.enumerated().map { index, screen in
            ScreenFrameSnapshot(
                id: Self.displayID(for: screen) ?? UInt32(index),
                frame: screen.frame
            )
        }

        if evaluator.update(
            mouseLocation: mouseLocation,
            screens: screens,
            corner: settings.corner,
            timestamp: Date()
        ) {
            onTriggered?()
        }
    }

    private static func displayID(for screen: NSScreen) -> UInt32? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? NSNumber)?.uint32Value
    }
}
