import AppKit
import SwiftUI
import VibeBlankCore

@MainActor
final class SettingsWindowController {
    private let window: NSWindow
    private let viewModel: SettingsViewModel

    init(store: SettingsStore) {
        viewModel = SettingsViewModel(store: store)

        let hostingView = NSHostingView(rootView: SettingsView(viewModel: viewModel))
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

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 940, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = AppCopy.settingsWindowTitle
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.minSize = NSSize(width: 540, height: 560)
        window.contentView = glassView
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: glassView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: glassView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: glassView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: glassView.bottomAnchor)
        ])
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}
