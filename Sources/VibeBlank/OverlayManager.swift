import AppKit
import CoreGraphics
import VibeBlankCore

@MainActor
final class OverlayManager {
    private var windows: [OverlayWindow] = []
    private var retiredWindows: [OverlayWindow] = []
    private var activeSettings: AppSettings?
    private weak var previousFrontmostApplication: NSRunningApplication?

    var onStateChange: (() -> Void)?

    var isActive: Bool {
        !windows.isEmpty
    }

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func toggle(settings: AppSettings) {
        if isActive {
            deactivate()
        } else {
            activate(settings: settings)
        }
    }

    func activate(settings: AppSettings) {
        activeSettings = settings

        if !isActive {
            previousFrontmostApplication = NSWorkspace.shared.frontmostApplication
        } else {
            closeWindows()
        }

        let targetScreens = screens(for: settings)
        windows = targetScreens.map { screen in
            OverlayWindow(screen: screen, settings: settings) { [weak self] in
                self?.deactivate()
            }
        }

        NSApp.activate(ignoringOtherApps: true)

        for window in windows {
            window.orderFrontRegardless()
        }

        if let firstWindow = windows.first {
            firstWindow.makeKeyAndOrderFront(nil)
            firstWindow.makeFirstResponder(firstWindow)
        }

        onStateChange?()
    }

    func deactivate() {
        closeWindows()
        activeSettings = nil

        if let previousFrontmostApplication, !previousFrontmostApplication.isTerminated {
            previousFrontmostApplication.activate(options: [.activateIgnoringOtherApps])
        }

        previousFrontmostApplication = nil
        onStateChange?()
    }

    private func closeWindows() {
        let windowsToRetire = windows
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        retiredWindows.append(contentsOf: windowsToRetire)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.retiredWindows.removeAll()
        }
    }

    private func screens(for settings: AppSettings) -> [NSScreen] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return []
        }

        switch settings.overlayScope {
        case .allDisplays:
            return screens
        case .externalDisplays:
            let externalScreens = screens.filter { !isBuiltInDisplay($0) }
            if !externalScreens.isEmpty {
                return externalScreens
            }
            if let mainScreen = NSScreen.main {
                return [mainScreen]
            }
            return [screens[0]]
        }
    }

    private func isBuiltInDisplay(_ screen: NSScreen) -> Bool {
        guard
            let displayNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else {
            return false
        }

        let displayID = CGDirectDisplayID(displayNumber.uint32Value)
        return CGDisplayIsBuiltin(displayID) != 0
    }

    @objc private func screenParametersDidChange() {
        guard let activeSettings else {
            return
        }
        activate(settings: activeSettings)
    }
}
