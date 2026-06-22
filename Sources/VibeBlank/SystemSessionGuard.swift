import AppKit
import VibeBlankCore

@MainActor
final class SystemSessionGuard {
    private enum DistributedNames {
        static let screenSaverDidStart = Notification.Name("com.apple.screensaver.didstart")
        static let screenSaverDidStop = Notification.Name("com.apple.screensaver.didstop")
        static let screenDidLock = Notification.Name("com.apple.screenIsLocked")
        static let screenDidUnlock = Notification.Name("com.apple.screenIsUnlocked")
    }

    var onProtectedSessionStarted: (() -> Void)?

    private var gate = SystemSessionActivationGate()
    private var cooldownTimer: Timer?
    private let workspaceNotificationCenter: NotificationCenter
    private let distributedNotificationCenter: DistributedNotificationCenter

    var canActivateOverlay: Bool {
        gate.allowsActivation(at: Date())
    }

    init(
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        distributedNotificationCenter: DistributedNotificationCenter = .default()
    ) {
        self.workspaceNotificationCenter = workspaceNotificationCenter
        self.distributedNotificationCenter = distributedNotificationCenter
        registerForNotifications()
    }

    deinit {
        workspaceNotificationCenter.removeObserver(self)
        distributedNotificationCenter.removeObserver(self)
        cooldownTimer?.invalidate()
    }

    func markProtectedSessionStarted() {
        let wasProtected = gate.isProtectedSessionActive
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        gate.markProtectedSessionStarted()

        if !wasProtected {
            onProtectedSessionStarted?()
        }
    }

    func markProtectedSessionEnded() {
        gate.markProtectedSessionEnded(at: Date())
        scheduleCooldownCleanup()
    }

    private func registerForNotifications() {
        let protectedStartNotifications: [Notification.Name] = [
            NSWorkspace.sessionDidResignActiveNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.willSleepNotification
        ]

        let protectedEndNotifications: [Notification.Name] = [
            NSWorkspace.sessionDidBecomeActiveNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.didWakeNotification
        ]

        for name in protectedStartNotifications {
            workspaceNotificationCenter.addObserver(
                self,
                selector: #selector(protectedSessionDidStart),
                name: name,
                object: nil
            )
        }

        for name in protectedEndNotifications {
            workspaceNotificationCenter.addObserver(
                self,
                selector: #selector(protectedSessionDidEnd),
                name: name,
                object: nil
            )
        }

        let distributedStartNotifications: [Notification.Name] = [
            DistributedNames.screenSaverDidStart,
            DistributedNames.screenDidLock
        ]

        let distributedEndNotifications: [Notification.Name] = [
            DistributedNames.screenSaverDidStop,
            DistributedNames.screenDidUnlock
        ]

        for name in distributedStartNotifications {
            distributedNotificationCenter.addObserver(
                self,
                selector: #selector(protectedSessionDidStart),
                name: name,
                object: nil
            )
        }

        for name in distributedEndNotifications {
            distributedNotificationCenter.addObserver(
                self,
                selector: #selector(protectedSessionDidEnd),
                name: name,
                object: nil
            )
        }
    }

    private func scheduleCooldownCleanup() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(
            withTimeInterval: SystemSessionActivationGate.defaultCooldown,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.cooldownTimer = nil
            }
        }
    }

    @objc private func protectedSessionDidStart() {
        markProtectedSessionStarted()
    }

    @objc private func protectedSessionDidEnd() {
        markProtectedSessionEnded()
    }
}
