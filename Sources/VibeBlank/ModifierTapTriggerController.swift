import AppKit
import ApplicationServices
import Carbon.HIToolbox
import VibeBlankCore

@MainActor
final class ModifierTapTriggerController {
    var onPressed: (() -> Void)?

    private var settings: ModifierTapTriggerSettings = .defaults
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var tapTimes: [Date] = []

    deinit {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
    }

    @discardableResult
    func update(settings: ModifierTapTriggerSettings) -> KeyboardPermissionStatus {
        self.settings = settings
        tapTimes.removeAll()
        removeMonitors()

        guard settings.isEnabled else {
            return .disabled
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            self?.handle(event)
            return event
        }

        guard AXIsProcessTrusted() else {
            return .needsAccessibilityPermission
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            self?.handle(event)
        }

        return .granted
    }

    func requestAccessibilityPermission() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func removeMonitors() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func handle(_ event: NSEvent) {
        guard settings.isEnabled else {
            return
        }

        switch event.type {
        case .flagsChanged:
            handleFlagsChanged(event)
        case .keyDown:
            tapTimes.removeAll()
        default:
            break
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let keyCode = Int(event.keyCode)
        guard keyCode == kVK_Command || keyCode == kVK_RightCommand else {
            return
        }

        guard event.modifierFlags.contains(.command) else {
            return
        }

        let otherModifiers: NSEvent.ModifierFlags = [.shift, .control, .option]
        guard event.modifierFlags.intersection(otherModifiers).isEmpty else {
            tapTimes.removeAll()
            return
        }

        guard commandSideMatches(keyCode: keyCode) else {
            tapTimes.removeAll()
            return
        }

        let now = Date()
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) <= settings.maxInterval }
        tapTimes.append(now)

        if tapTimes.count >= settings.tapCount {
            tapTimes.removeAll()
            onPressed?()
        }
    }

    private func commandSideMatches(keyCode: Int) -> Bool {
        switch settings.commandSide {
        case .any:
            return true
        case .left:
            return keyCode == kVK_Command
        case .right:
            return keyCode == kVK_RightCommand
        }
    }
}
