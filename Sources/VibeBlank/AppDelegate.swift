import AppKit
import Carbon.HIToolbox
import VibeBlankCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private let overlayManager = OverlayManager()
    private let comboHotKeyController = HotKeyController()
    private let modifierTapTriggerController = ModifierTapTriggerController()
    private let hotCornerTriggerController = HotCornerTriggerController()
    private let loginItemController = LoginItemController()
    private let escapeHotKeyController = HotKeyController(
        keyCode: UInt32(kVK_Escape),
        modifiers: 0,
        id: 2,
        isExclusive: false
    )

    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var hotKeyConflictStatus: HotKeyConflictStatus = .unchecked
    private var keyboardPermissionStatus: KeyboardPermissionStatus = .unknown
    private var loginItemSyncStatus: LoginItemSyncStatus = .disabled

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination(AppCopy.residentUtilityReason)
        configureStatusItem()
        configureCallbacks()
        syncTriggers()
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

        comboHotKeyController.onPressed = { [weak self] in
            self?.toggleOverlay()
        }

        modifierTapTriggerController.onPressed = { [weak self] in
            self?.toggleOverlay()
        }

        hotCornerTriggerController.onTriggered = { [weak self] in
            self?.activateOverlayIfNeeded()
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

    private func syncTriggers() {
        let settings = settingsStore.load()

        loginItemSyncStatus = loginItemController.sync(isEnabled: settings.launchAtLoginEnabled)
        keyboardPermissionStatus = modifierTapTriggerController.update(settings: settings.modifierTapTrigger)
        let hotKeyRegistrationSucceeded = comboHotKeyController.update(settings: settings.comboHotKeyTrigger)

        if settings.comboHotKeyTrigger.isEnabled {
            hotKeyConflictStatus = hotKeyRegistrationSucceeded ? .available : .conflict
        } else {
            hotKeyConflictStatus = .disabled
        }

        hotCornerTriggerController.update(settings: settings.cornerTrigger)
        postTriggerStatus()
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

        let settings = settingsStore.load()

        let primaryTriggerTitle: String
        if settings.modifierTapTrigger.isEnabled {
            primaryTriggerTitle = keyboardPermissionStatus == .needsAccessibilityPermission
                ? AppCopy.Menu.primaryTriggerNeedsPermission
                : AppCopy.Menu.primaryTriggerAvailable
        } else {
            primaryTriggerTitle = AppCopy.Menu.primaryTriggerOff
        }

        let primaryTriggerItem = NSMenuItem(
            title: primaryTriggerTitle,
            action: nil,
            keyEquivalent: ""
        )
        primaryTriggerItem.isEnabled = false
        menu.addItem(primaryTriggerItem)

        let comboTitle: String
        if settings.comboHotKeyTrigger.isEnabled {
            comboTitle = hotKeyConflictStatus == .available
                ? AppCopy.Menu.comboHotkeyAvailable(settings.comboHotKeyTrigger.displayName)
                : AppCopy.Menu.comboHotkeyUnavailable
        } else {
            comboTitle = AppCopy.Menu.comboHotkeyOff
        }

        let comboItem = NSMenuItem(title: comboTitle, action: nil, keyEquivalent: "")
        comboItem.isEnabled = false
        menu.addItem(comboItem)

        let cornerTitle = settings.cornerTrigger.isEnabled
            ? AppCopy.Menu.cornerAvailable(settings.cornerTrigger.corner.displayName)
            : AppCopy.Menu.cornerOff

        let cornerItem = NSMenuItem(title: cornerTitle, action: nil, keyEquivalent: "")
        cornerItem.isEnabled = false
        menu.addItem(cornerItem)

        let loginItem = NSMenuItem(title: loginItemSyncStatus.displayName, action: nil, keyEquivalent: "")
        loginItem.isEnabled = false
        menu.addItem(loginItem)

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

    private func activateOverlayIfNeeded() {
        guard !overlayManager.isActive else {
            return
        }
        overlayManager.activate(settings: settingsStore.load())
    }

    @objc private func openSettingsFromMenu() {
        showSettings()
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(store: settingsStore)
        }
        settingsWindowController?.show()
        postTriggerStatus()
    }

    @objc private func quitFromMenu() {
        overlayManager.forceDeactivate()
        NSApp.terminate(nil)
    }

    @objc private func settingsDidChange() {
        syncTriggers()
        rebuildMenu()

        if overlayManager.isActive {
            overlayManager.activate(settings: settingsStore.load())
        }
    }

    private func postTriggerStatus() {
        NotificationCenter.default.post(
            name: .vibeBlankTriggerStatusDidChange,
            object: nil,
            userInfo: [
                TriggerStatusUserInfoKey.keyboardPermission: keyboardPermissionStatus.rawValue,
                TriggerStatusUserInfoKey.hotKeyConflict: hotKeyConflictStatus.rawValue,
                TriggerStatusUserInfoKey.loginItem: loginItemSyncStatus.displayName
            ]
        )
    }
}
