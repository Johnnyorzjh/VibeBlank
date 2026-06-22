import AppKit
import Carbon.HIToolbox
import SwiftUI
import VibeBlankCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private let overlayManager = OverlayManager()
    private let comboHotKeyController = HotKeyController()
    private let modifierTapTriggerController = ModifierTapTriggerController()
    private let hotCornerTriggerController = HotCornerTriggerController()
    private let loginItemController = LoginItemController()
    private let systemSessionGuard = SystemSessionGuard()
    private let escapeHotKeyController = HotKeyController(
        keyCode: UInt32(kVK_Escape),
        modifiers: 0,
        id: 2,
        isExclusive: false
    )

    private var statusItem: NSStatusItem?
    private var statusPanel: NSPanel?
    private var statusPanelDismissMonitor: Any?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?
    private var hotKeyConflictStatus: HotKeyConflictStatus = .unchecked
    private var keyboardPermissionStatus: KeyboardPermissionStatus = .unknown
    private var loginItemSyncStatus: LoginItemSyncStatus = .disabled

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination(AppCopy.residentUtilityReason)
        configureStatusItem()
        configureCallbacks()
        syncTriggers()
        refreshStatusPanel()

        if !settingsStore.hasCompletedOnboarding {
            showOnboarding()
        } else if !settingsStore.hasCompletedFirstLaunch {
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
        item.button?.target = self
        item.button?.action = #selector(toggleStatusPanel)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.menu = nil
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
            self?.refreshStatusPanel()
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

        systemSessionGuard.onProtectedSessionStarted = { [weak self] in
            self?.overlayManager.forceDeactivate()
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

    private func refreshStatusPanel() {
        guard let statusPanel else {
            return
        }
        statusPanel.contentView = makeStatusPanelHostingView(size: statusPanel.frame.size)
    }

    private func makeStatusPanelHostingView(size: NSSize) -> NSView {
        let rootView = makeStatusPanelView()
            .frame(width: size.width, height: size.height, alignment: .center)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        return hostingView
    }

    private func makeStatusPanelView() -> StatusPanelView {
        StatusPanelView(
            settings: settingsStore.load(),
            isOverlayActive: overlayManager.isActive,
            keyboardPermissionStatus: keyboardPermissionStatus,
            hotKeyConflictStatus: hotKeyConflictStatus,
            loginItemStatus: loginItemSyncStatus,
            toggleOverlay: { [weak self] in
                Task { @MainActor in
                    self?.toggleOverlay()
                    self?.refreshStatusPanel()
                }
            },
            openSettings: { [weak self] in
                Task { @MainActor in
                    self?.closeStatusPanel()
                    self?.showSettings()
                }
            },
            quit: { [weak self] in
                Task { @MainActor in
                    self?.quitFromPanel()
                }
            }
        )
    }

    @objc private func toggleStatusPanel() {
        guard let button = statusItem?.button else {
            return
        }

        if statusPanel?.isVisible == true {
            closeStatusPanel()
            return
        }

        showStatusPanel(relativeTo: button)
    }

    private func showStatusPanel(relativeTo button: NSStatusBarButton) {
        let frame = statusPanelFrame(relativeTo: button)
        let panel = statusPanel ?? NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.contentView = makeStatusPanelHostingView(size: frame.size)
        panel.setFrame(frame, display: true)
        statusPanel = panel
        panel.orderFrontRegardless()
        installStatusPanelDismissMonitor()
    }

    private func closeStatusPanel() {
        statusPanel?.orderOut(nil)
        removeStatusPanelDismissMonitor()
    }

    private func statusPanelFrame(relativeTo button: NSStatusBarButton) -> NSRect {
        let screen = button.window?.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let size = statusPanelSize(in: visibleFrame)

        let buttonFrame: NSRect
        if let window = button.window {
            buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        } else {
            buttonFrame = NSRect(x: visibleFrame.maxX - size.width, y: visibleFrame.maxY, width: 0, height: 0)
        }

        let horizontalMargin: CGFloat = 10
        let verticalMargin: CGFloat = 8
        let proposedX = buttonFrame.midX - size.width / 2
        let minX = visibleFrame.minX + horizontalMargin
        let maxX = visibleFrame.maxX - size.width - horizontalMargin
        let x = min(max(proposedX, minX), maxX)
        let y = visibleFrame.maxY - size.height - verticalMargin

        return NSRect(origin: NSPoint(x: x, y: y), size: size)
    }

    private func statusPanelSize(in visibleFrame: NSRect) -> NSSize {
        NSSize(width: 384, height: min(634, max(544, visibleFrame.height - 18)))
    }

    private func installStatusPanelDismissMonitor() {
        guard statusPanelDismissMonitor == nil else {
            return
        }
        statusPanelDismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closeStatusPanel()
            }
        }
    }

    private func removeStatusPanelDismissMonitor() {
        if let statusPanelDismissMonitor {
            NSEvent.removeMonitor(statusPanelDismissMonitor)
            self.statusPanelDismissMonitor = nil
        }
    }

    private func toggleOverlay() {
        if overlayManager.isActive {
            overlayManager.deactivate()
            return
        }

        guard systemSessionGuard.canActivateOverlay else {
            return
        }

        overlayManager.activate(settings: settingsStore.load())
    }

    private func activateOverlayIfNeeded() {
        guard !overlayManager.isActive else {
            return
        }
        guard systemSessionGuard.canActivateOverlay else {
            return
        }
        overlayManager.activate(settings: settingsStore.load())
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(store: settingsStore)
        }
        settingsWindowController?.show()
        postTriggerStatus()
    }

    private func showOnboarding() {
        if onboardingWindowController == nil {
            onboardingWindowController = OnboardingWindowController(
                loginItemStatus: loginItemSyncStatus,
                openLoginItemsSettings: { [weak self] in
                    Task { @MainActor in
                        self?.openLoginItemsSettings()
                    }
                },
                start: { [weak self] in
                    Task { @MainActor in
                        self?.completeOnboarding()
                    }
                }
            )
        }
        onboardingWindowController?.show(loginItemStatus: loginItemSyncStatus)
        postTriggerStatus()
    }

    private func completeOnboarding() {
        let shouldOpenSettings = !settingsStore.hasCompletedFirstLaunch

        settingsStore.markOnboardingCompleted()
        onboardingWindowController?.close()
        onboardingWindowController = nil

        if shouldOpenSettings {
            settingsStore.markFirstLaunchCompleted()
            showSettings()
        }
    }

    private func openLoginItemsSettings() {
        let urlStrings = [
            "x-apple.systempreferences:com.apple.LoginItems-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.general?LoginItems"
        ]

        guard let url = urlStrings.compactMap(URL.init(string:)).first else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func quitFromPanel() {
        closeStatusPanel()
        overlayManager.forceDeactivate()
        NSApp.terminate(nil)
    }

    @objc private func settingsDidChange() {
        syncTriggers()
        refreshStatusPanel()

        if overlayManager.isActive, systemSessionGuard.canActivateOverlay {
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
