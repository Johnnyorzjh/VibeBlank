import AppKit
import Carbon.HIToolbox
import VibeBlankCore

extension Notification.Name {
    static let vibeBlankSettingsDidChange = Notification.Name("VibeBlankSettingsDidChange")
    static let vibeBlankTriggerStatusDidChange = Notification.Name("VibeBlankTriggerStatusDidChange")
}

enum TriggerStatusUserInfoKey {
    static let keyboardPermission = "keyboardPermission"
    static let hotKeyConflict = "hotKeyConflict"
    static let loginItem = "loginItem"
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            store.save(settings)
            NotificationCenter.default.post(name: .vibeBlankSettingsDidChange, object: nil)
        }
    }
    @Published var keyboardPermissionStatus: KeyboardPermissionStatus
    @Published var hotKeyConflictStatus: HotKeyConflictStatus
    @Published var loginItemStatusText: String
    @Published var isRecordingComboHotKey = false
    @Published var comboHotKeyError: String?

    private let store: SettingsStore
    private var triggerStatusObserver: NSObjectProtocol?

    init(store: SettingsStore) {
        self.store = store
        let loadedSettings = store.load()
        self.settings = loadedSettings
        self.keyboardPermissionStatus = loadedSettings.keyboardPermissionStatus
        self.hotKeyConflictStatus = loadedSettings.hotKeyConflictStatus
        self.loginItemStatusText = "登录时启动状态待同步"

        triggerStatusObserver = NotificationCenter.default.addObserver(
            forName: .vibeBlankTriggerStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.applyTriggerStatus(notification)
            }
        }
    }

    deinit {
        if let triggerStatusObserver {
            NotificationCenter.default.removeObserver(triggerStatusObserver)
        }
    }

    func resetToDefaults() {
        settings = .defaults
    }

    func setComboHotKeyEnabled(_ isEnabled: Bool) {
        if !isEnabled {
            comboHotKeyError = nil
            hotKeyConflictStatus = .disabled
            settings.comboHotKeyTrigger.isEnabled = false
            settings.hotKeyConflictStatus = .disabled
            return
        }

        let status = HotKeyController.registrationStatus(for: settings.comboHotKeyTrigger)
        guard status == noErr else {
            hotKeyConflictStatus = .conflict
            settings.hotKeyConflictStatus = .conflict
            comboHotKeyError = AppCopy.Settings.comboConflict
            return
        }

        comboHotKeyError = nil
        hotKeyConflictStatus = .available
        settings.comboHotKeyTrigger.isEnabled = true
        settings.hotKeyConflictStatus = .available
    }

    func saveComboHotKey(keyCode: UInt32, modifiers: UInt32, displayName: String) {
        guard modifiers != 0 else {
            comboHotKeyError = AppCopy.Settings.comboNeedsModifier
            return
        }

        let current = settings.comboHotKeyTrigger
        let isSameAsCurrent = current.isEnabled && current.keyCode == keyCode && current.modifiers == modifiers
        let status = isSameAsCurrent ? noErr : HotKeyController.registrationStatus(keyCode: keyCode, modifiers: modifiers)

        guard status == noErr else {
            hotKeyConflictStatus = .conflict
            settings.hotKeyConflictStatus = .conflict
            comboHotKeyError = AppCopy.Settings.comboConflict
            return
        }

        comboHotKeyError = nil
        hotKeyConflictStatus = .available
        isRecordingComboHotKey = false
        settings.comboHotKeyTrigger = ComboHotKeySettings(
            isEnabled: true,
            keyCode: keyCode,
            modifiers: modifiers,
            displayName: displayName
        )
        settings.hotKeyConflictStatus = .available
    }

    func cancelComboRecording() {
        isRecordingComboHotKey = false
        comboHotKeyError = nil
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func applyTriggerStatus(_ notification: Notification) {
        if
            let rawValue = notification.userInfo?[TriggerStatusUserInfoKey.keyboardPermission] as? String,
            let status = KeyboardPermissionStatus(rawValue: rawValue)
        {
            keyboardPermissionStatus = status
        }

        if
            let rawValue = notification.userInfo?[TriggerStatusUserInfoKey.hotKeyConflict] as? String,
            let status = HotKeyConflictStatus(rawValue: rawValue)
        {
            hotKeyConflictStatus = status
        }

        if let loginItemStatusText = notification.userInfo?[TriggerStatusUserInfoKey.loginItem] as? String {
            self.loginItemStatusText = loginItemStatusText
        }
    }
}
