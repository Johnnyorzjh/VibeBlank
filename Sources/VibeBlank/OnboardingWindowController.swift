import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
    private let window: NSPanel
    private var loginItemStatus: LoginItemSyncStatus
    private let openLoginItemsSettings: () -> Void
    private let start: () -> Void

    init(
        loginItemStatus: LoginItemSyncStatus,
        openLoginItemsSettings: @escaping () -> Void,
        start: @escaping () -> Void
    ) {
        self.loginItemStatus = loginItemStatus
        self.openLoginItemsSettings = openLoginItemsSettings
        self.start = start

        window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = AppCopy.Onboarding.windowTitle
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.isFloatingPanel = true
        window.hidesOnDeactivate = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces]
        window.minSize = NSSize(width: 560, height: 600)
        window.isReleasedWhenClosed = false
        window.center()
        updateContent()
    }

    func show(loginItemStatus: LoginItemSyncStatus) {
        self.loginItemStatus = loginItemStatus
        updateContent()
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func close() {
        window.close()
    }

    private func updateContent() {
        let hostingView = NSHostingView(
            rootView: OnboardingView(
                loginItemStatus: loginItemStatus,
                openLoginItemsSettings: openLoginItemsSettings,
                start: start
            )
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let glassView = NSVisualEffectView()
        glassView.material = .underPageBackground
        glassView.blendingMode = .behindWindow
        glassView.state = .active
        glassView.isEmphasized = false
        glassView.wantsLayer = true
        glassView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: glassView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: glassView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: glassView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: glassView.bottomAnchor)
        ])

        window.contentView = glassView
    }
}
