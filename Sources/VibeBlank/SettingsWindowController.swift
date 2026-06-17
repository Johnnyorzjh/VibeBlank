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
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "VibeBlank Settings"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}
