import AppKit
import Carbon.HIToolbox
import VibeBlankCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private let overlayManager = OverlayManager()
    private let hotKeyController = HotKeyController()
    private let escapeHotKeyController = HotKeyController(
        keyCode: UInt32(kVK_Escape),
        modifiers: 0,
        id: 2
    )

    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var hotKeyRegistrationSucceeded = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination(AppCopy.residentUtilityReason)
        configureStatusItem()
        configureCallbacks()
        updateHotKey()
        rebuildMenu()

        if !settingsStore.hasCompletedFirstLaunch {
            showSettings()
            settingsStore.markFirstLaunchCompleted()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let icon = loadStatusIcon() {
            icon.isTemplate = true
            icon.size = NSSize(width: 18, height: 18)
            item.button?.image = icon
            item.button?.title = ""
        } else {
            item.length = NSStatusItem.variableLength
            item.button?.title = AppCopy.appName
        }
        item.button?.toolTip = AppCopy.statusTooltip
        statusItem = item
    }

    private func loadStatusIcon() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "heimama-status-template", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    private func configureCallbacks() {
        overlayManager.onStateChange = { [weak self] in
            self?.updateOverlayEscapeHotKey()
            self?.rebuildMenu()
        }

        hotKeyController.onPressed = { [weak self] in
            self?.toggleOverlay()
        }

        escapeHotKeyController.onPressed = { [weak self] in
            self?.overlayManager.deactivate()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .vibeBlankSettingsDidChange,
            object: nil
        )
    }

    private func updateHotKey() {
        hotKeyRegistrationSucceeded = hotKeyController.update(isEnabled: settingsStore.load().globalHotkeyEnabled)
    }

    private func updateOverlayEscapeHotKey() {
        _ = escapeHotKeyController.update(isEnabled: overlayManager.isActive)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: overlayManager.isActive ? AppCopy.Menu.deactivate : AppCopy.Menu.activate,
            action: #selector(toggleOverlayFromMenu),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        let scopeItem = NSMenuItem(
            title: "\(AppCopy.Menu.scopePrefix)：\(settingsStore.load().overlayScope.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        scopeItem.isEnabled = false
        menu.addItem(scopeItem)

        let hotkeyTitle: String
        if settingsStore.load().globalHotkeyEnabled {
            hotkeyTitle = hotKeyRegistrationSucceeded ? AppCopy.Menu.hotkeyAvailable : AppCopy.Menu.hotkeyUnavailable
        } else {
            hotkeyTitle = AppCopy.Menu.hotkeyOff
        }

        let hotkeyItem = NSMenuItem(
            title: hotkeyTitle,
            action: nil,
            keyEquivalent: ""
        )
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: AppCopy.Menu.settings,
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: AppCopy.Menu.quit,
            action: #selector(quitFromMenu),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func toggleOverlayFromMenu() {
        toggleOverlay()
    }

    private func toggleOverlay() {
        overlayManager.toggle(settings: settingsStore.load())
    }

    @objc private func openSettingsFromMenu() {
        showSettings()
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(store: settingsStore)
        }
        settingsWindowController?.show()
    }

    @objc private func quitFromMenu() {
        overlayManager.forceDeactivate()
        NSApp.terminate(nil)
    }

    @objc private func settingsDidChange() {
        updateHotKey()
        rebuildMenu()

        if overlayManager.isActive {
            overlayManager.activate(settings: settingsStore.load())
        }
    }
}
