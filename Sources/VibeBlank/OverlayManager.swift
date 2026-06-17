import AppKit
import CoreGraphics
import VibeBlankCore

@MainActor
final class OverlayManager {
    private var windows: [OverlayWindow] = []
    private var retiredWindows: [OverlayWindow] = []
    private var activeSettings: AppSettings?
    private var isDeactivating = false
    private var deactivationID = UUID()
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
        if !isActive {
            previousFrontmostApplication = NSWorkspace.shared.frontmostApplication
        } else {
            forceCloseWindows()
        }

        activeSettings = settings
        isDeactivating = false

        let targetScreens = screens(for: settings)
        windows = targetScreens.map { screen in
            OverlayWindow(screen: screen, settings: settings) { [weak self] in
                self?.deactivate()
            }
        }

        NSApp.activate(ignoringOtherApps: true)

        for window in windows {
            window.orderFrontRegardless()
            window.startAppearing()
        }

        if let firstWindow = windows.first {
            firstWindow.makeKeyAndOrderFront(nil)
            firstWindow.makeFirstResponder(firstWindow)
        }

        onStateChange?()
    }

    func deactivate() {
        guard !windows.isEmpty, !isDeactivating else {
            return
        }

        isDeactivating = true
        activeSettings = nil
        let currentDeactivationID = UUID()
        deactivationID = currentDeactivationID
        let windowsToClose = windows
        var remainingWindows = windowsToClose.count

        for window in windowsToClose {
            window.startDisappearing { [weak self] in
                guard let self, self.deactivationID == currentDeactivationID else {
                    return
                }

                remainingWindows -= 1
                if remainingWindows == 0 {
                    self.finishDeactivation(windowsToClose, deactivationID: currentDeactivationID)
                }
            }
        }
    }

    func forceDeactivate() {
        activeSettings = nil
        isDeactivating = false
        deactivationID = UUID()
        retireWindows(windows)
        restorePreviousApplication()
        onStateChange?()
    }

    private func finishDeactivation(_ windowsToClose: [OverlayWindow], deactivationID: UUID) {
        guard self.deactivationID == deactivationID else {
            return
        }

        retireWindows(windowsToClose)
        isDeactivating = false

        if windows.isEmpty {
            restorePreviousApplication()
        }

        onStateChange?()
    }

    private func forceCloseWindows() {
        deactivationID = UUID()
        isDeactivating = false
        retireWindows(windows)
    }

    private func retireWindows(_ windowsToRetire: [OverlayWindow]) {
        guard !windowsToRetire.isEmpty else {
            return
        }

        for window in windowsToRetire {
            window.orderOut(nil)
        }

        windows.removeAll { window in
            windowsToRetire.contains { $0 === window }
        }
        retiredWindows.append(contentsOf: windowsToRetire)

        DispatchQueue.main.asyncAfter(deadline: .now() + OverlayTransitionModel.duration + 0.25) { [weak self] in
            self?.retiredWindows.removeAll { retiredWindow in
                windowsToRetire.contains { $0 === retiredWindow }
            }
        }
    }

    private func restorePreviousApplication() {
        if let previousFrontmostApplication, !previousFrontmostApplication.isTerminated {
            previousFrontmostApplication.activate(options: [.activateIgnoringOtherApps])
        }

        previousFrontmostApplication = nil
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
