import AppKit
import VibeBlankCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private let overlayManager = OverlayManager()
    private let hotKeyController = HotKeyController()

    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var hotKeyRegistrationSucceeded = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("VibeBlank is a resident menu bar utility.")
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
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "VibeBlank"
        item.button?.toolTip = "VibeBlank visual privacy"
        statusItem = item
    }

    private func configureCallbacks() {
        overlayManager.onStateChange = { [weak self] in
            self?.rebuildMenu()
        }

        hotKeyController.onPressed = { [weak self] in
            self?.toggleOverlay()
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

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: overlayManager.isActive ? "Exit Black Screen" : "Activate Black Screen",
            action: #selector(toggleOverlayFromMenu),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        let scopeItem = NSMenuItem(
            title: "Scope: \(settingsStore.load().overlayScope.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        scopeItem.isEnabled = false
        menu.addItem(scopeItem)

        let hotkeyTitle: String
        if settingsStore.load().globalHotkeyEnabled {
            hotkeyTitle = hotKeyRegistrationSucceeded ? "Hotkey: Control-Option-Command-B" : "Hotkey: Unavailable (use menu or Esc)"
        } else {
            hotkeyTitle = "Hotkey: Off (Esc still exits overlays)"
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
            title: "Settings...",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit VibeBlank",
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
        overlayManager.deactivate()
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
