import AppKit
import SwiftUI
import VibeBlankCore

final class OverlayWindow: NSWindow {
    private let escapeKeyCode: UInt16 = 53
    private let settings: AppSettings
    private let exitHandler: () -> Void
    private let transition = OverlayTransitionModel()
    private var isAnimatingOut = false

    init(screen: NSScreen, settings: AppSettings, exitHandler: @escaping () -> Void) {
        self.settings = settings
        self.exitHandler = exitHandler

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        title = AppCopy.overlayWindowTitle
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        animationBehavior = .none
        isReleasedWhenClosed = false
        canHide = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let hostingView = NSHostingView(rootView: OverlayContentView(settings: settings, transition: transition))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        contentView = hostingView
    }

    func startAppearing() {
        transition.appear()
    }

    func startDisappearing(completion: @escaping () -> Void) {
        guard !isAnimatingOut else {
            return
        }

        isAnimatingOut = true
        transition.disappear { [weak self] in
            self?.isAnimatingOut = false
            completion()
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == escapeKeyCode {
            requestExit()
            return
        }

        if settings.keyToExitEnabled {
            requestExit()
        }
    }

    override func keyUp(with event: NSEvent) {}
    override func flagsChanged(with event: NSEvent) {}

    override func mouseDown(with event: NSEvent) {
        handlePointerEvent()
    }

    override func rightMouseDown(with event: NSEvent) {
        handlePointerEvent()
    }

    override func otherMouseDown(with event: NSEvent) {
        handlePointerEvent()
    }

    override func scrollWheel(with event: NSEvent) {}

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == escapeKeyCode || settings.keyToExitEnabled {
            requestExit()
        }
        return true
    }

    private func handlePointerEvent() {
        if settings.clickToExitEnabled {
            requestExit()
        }
    }

    private func requestExit() {
        DispatchQueue.main.async { [exitHandler] in
            exitHandler()
        }
    }
}
