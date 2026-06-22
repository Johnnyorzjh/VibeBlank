# VibeBlank System Session Guard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent VibeBlank from remaining in or automatically re-entering black-screen mode when macOS enters screen saver, lock screen, display sleep, or system sleep.

**Architecture:** Add a pure `VibeBlankCore` activation gate so cooldown and protected-state behavior can be checked without AppKit. Add a small AppKit `SystemSessionGuard` owned by `AppDelegate`; it listens for macOS session, screen, sleep, screen-saver, and lock notifications, force-deactivates the overlay when protected state starts, and blocks only activation paths while protected or cooling down.

**Tech Stack:** Swift 5.9, SwiftPM, Foundation, AppKit, `NSWorkspace.shared.notificationCenter`, `DistributedNotificationCenter`, existing `VibeBlankCoreChecks`.

## Global Constraints

- Minimum supported OS remains macOS 13.
- VibeBlank remains a visual privacy overlay, not a system lock screen or authentication layer.
- Do not add settings UI for this behavior.
- Do not use private frameworks or compile-time private API references.
- Do not change overlay visuals, settings layout, login-item behavior, or trigger configuration.
- Keep the change isolated from existing dirty settings-window work in `Sources/VibeBlank/AppCopy.swift`, `Sources/VibeBlank/SettingsView.swift`, and `Sources/VibeBlank/SettingsWindowController.swift`.
- Activation attempts during protected state and the short return cooldown are ignored.
- Deactivation remains allowed while protected or cooling down.
- Run `swift run VibeBlankCoreChecks` and `swift build --product VibeBlank` after implementation.

---

## File Structure

- Create `Sources/VibeBlankCore/SystemSessionActivationGate.swift`: pure state machine for protected-session and cooldown activation rules.
- Modify `Checks/VibeBlankCoreChecks/main.swift`: add coverage for the state machine.
- Create `Sources/VibeBlank/SystemSessionGuard.swift`: AppKit notification adapter that converts macOS session events into gate transitions and overlay-deactivation callbacks.
- Modify `Sources/VibeBlank/AppDelegate.swift`: own the guard and route all activation paths through it.
- Leave `OverlayManager` unchanged; it already exposes `forceDeactivate()` for immediate teardown.

### Task 1: Core Activation Gate

**Files:**
- Create: `Sources/VibeBlankCore/SystemSessionActivationGate.swift`
- Modify: `Checks/VibeBlankCoreChecks/main.swift`

**Interfaces:**
- Produces: `public struct SystemSessionActivationGate`
- Produces: `SystemSessionActivationGate.defaultCooldown: TimeInterval`
- Produces: `SystemSessionActivationGate.allowsActivation(at now: Date) -> Bool`
- Produces: `SystemSessionActivationGate.allowsDeactivation: Bool`
- Produces: `mutating SystemSessionActivationGate.markProtectedSessionStarted()`
- Produces: `mutating SystemSessionActivationGate.markProtectedSessionEnded(at now: Date, cooldown: TimeInterval = defaultCooldown)`

- [ ] **Step 1: Create the state machine file**

Add this complete file:

```swift
import Foundation

public struct SystemSessionActivationGate: Equatable {
    public static let defaultCooldown: TimeInterval = 1.5

    public private(set) var isProtectedSessionActive: Bool
    public private(set) var cooldownEndsAt: Date?

    public init(
        isProtectedSessionActive: Bool = false,
        cooldownEndsAt: Date? = nil
    ) {
        self.isProtectedSessionActive = isProtectedSessionActive
        self.cooldownEndsAt = cooldownEndsAt
    }

    public var allowsDeactivation: Bool {
        true
    }

    public func allowsActivation(at now: Date) -> Bool {
        guard !isProtectedSessionActive else {
            return false
        }

        if let cooldownEndsAt, now < cooldownEndsAt {
            return false
        }

        return true
    }

    public mutating func markProtectedSessionStarted() {
        isProtectedSessionActive = true
        cooldownEndsAt = nil
    }

    public mutating func markProtectedSessionEnded(
        at now: Date,
        cooldown: TimeInterval = Self.defaultCooldown
    ) {
        isProtectedSessionActive = false
        cooldownEndsAt = now.addingTimeInterval(max(0, cooldown))
    }
}
```

- [ ] **Step 2: Add a failing core check**

In `Checks/VibeBlankCoreChecks/main.swift`, add this function before `checkFirstLaunchFlagPersists()`:

```swift
private func checkSystemSessionActivationGate() throws {
    let start = Date(timeIntervalSinceReferenceDate: 100)
    var gate = SystemSessionActivationGate()

    try expect(gate.allowsActivation(at: start) == true, "activation should be allowed by default")
    try expect(gate.allowsDeactivation == true, "deactivation should always be allowed")

    gate.markProtectedSessionStarted()
    try expect(gate.isProtectedSessionActive == true, "protected session should be tracked")
    try expect(gate.cooldownEndsAt == nil, "protected start should clear cooldown")
    try expect(gate.allowsActivation(at: start) == false, "activation should be blocked while protected")
    try expect(gate.allowsDeactivation == true, "deactivation should still be allowed while protected")

    gate.markProtectedSessionEnded(at: start, cooldown: 1.5)
    try expect(gate.isProtectedSessionActive == false, "protected session should end")
    try expect(
        gate.allowsActivation(at: start.addingTimeInterval(1.49)) == false,
        "activation should be blocked during return cooldown"
    )
    try expect(
        gate.allowsActivation(at: start.addingTimeInterval(1.5)) == true,
        "activation should resume after cooldown"
    )

    gate.markProtectedSessionStarted()
    try expect(gate.cooldownEndsAt == nil, "new protected start should invalidate pending cooldown")
}
```

Then add the check entry immediately before `"first launch flag persists"`:

```swift
("system session activation gate", checkSystemSessionActivationGate),
```

- [ ] **Step 3: Run the focused check and confirm it passes**

Run:

```bash
swift run VibeBlankCoreChecks
```

Expected output includes:

```text
PASS: system session activation gate
All VibeBlank core checks passed.
```

- [ ] **Step 4: Commit Task 1**

Stage only the core gate and check files:

```bash
git add Sources/VibeBlankCore/SystemSessionActivationGate.swift Checks/VibeBlankCoreChecks/main.swift
git commit -m "feat: add system session activation gate"
```

### Task 2: AppKit Session Guard Wiring

**Files:**
- Create: `Sources/VibeBlank/SystemSessionGuard.swift`
- Modify: `Sources/VibeBlank/AppDelegate.swift`

**Interfaces:**
- Consumes: `SystemSessionActivationGate`
- Produces: `@MainActor final class SystemSessionGuard`
- Produces: `SystemSessionGuard.canActivateOverlay: Bool`
- Produces: `SystemSessionGuard.onProtectedSessionStarted: (() -> Void)?`
- Produces: `SystemSessionGuard.markProtectedSessionStarted()`
- Produces: `SystemSessionGuard.markProtectedSessionEnded()`

- [ ] **Step 1: Create the AppKit guard**

Add this complete file:

```swift
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
```

- [ ] **Step 2: Wire the guard into AppDelegate**

In `Sources/VibeBlank/AppDelegate.swift`, add the guard property after `loginItemController`:

```swift
private let systemSessionGuard = SystemSessionGuard()
```

In `configureCallbacks()`, add this callback before the settings observer:

```swift
systemSessionGuard.onProtectedSessionStarted = { [weak self] in
    self?.overlayManager.forceDeactivate()
}
```

Replace `toggleOverlay()` with:

```swift
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
```

Replace `activateOverlayIfNeeded()` with:

```swift
private func activateOverlayIfNeeded() {
    guard !overlayManager.isActive else {
        return
    }

    guard systemSessionGuard.canActivateOverlay else {
        return
    }

    overlayManager.activate(settings: settingsStore.load())
}
```

Replace the active-overlay rebuild block in `settingsDidChange()` with:

```swift
if overlayManager.isActive, systemSessionGuard.canActivateOverlay {
    overlayManager.activate(settings: settingsStore.load())
}
```

- [ ] **Step 3: Build the app**

Run:

```bash
swift build --product VibeBlank
```

Expected: build completes without Swift compiler errors.

- [ ] **Step 4: Commit Task 2**

Stage only the guard and app delegate files:

```bash
git add Sources/VibeBlank/SystemSessionGuard.swift Sources/VibeBlank/AppDelegate.swift
git commit -m "feat: guard overlay during protected sessions"
```

### Task 3: Full Verification

**Files:**
- Verify: `Sources/VibeBlankCore/SystemSessionActivationGate.swift`
- Verify: `Sources/VibeBlank/SystemSessionGuard.swift`
- Verify: `Sources/VibeBlank/AppDelegate.swift`
- Verify: `Checks/VibeBlankCoreChecks/main.swift`

**Interfaces:**
- Consumes: all Task 1 and Task 2 interfaces.
- Produces: verified implementation against the accepted design spec.

- [ ] **Step 1: Confirm unrelated dirty files are untouched by staging**

Run:

```bash
git status --short
```

Expected: any pre-existing changes in these files may still be present, but they are not part of the Task 1 or Task 2 commits:

```text
 M Sources/VibeBlank/AppCopy.swift
 M Sources/VibeBlank/SettingsView.swift
 M Sources/VibeBlank/SettingsWindowController.swift
```

- [ ] **Step 2: Run core checks**

Run:

```bash
swift run VibeBlankCoreChecks
```

Expected output includes:

```text
PASS: system session activation gate
All VibeBlank core checks passed.
```

- [ ] **Step 3: Run product build**

Run:

```bash
swift build --product VibeBlank
```

Expected: build completes successfully.

- [ ] **Step 4: Review final diff against the spec**

Run:

```bash
git show --stat --oneline HEAD~2..HEAD
```

Expected: implementation commits include only:

```text
Sources/VibeBlankCore/SystemSessionActivationGate.swift
Checks/VibeBlankCoreChecks/main.swift
Sources/VibeBlank/SystemSessionGuard.swift
Sources/VibeBlank/AppDelegate.swift
```

- [ ] **Step 5: Manual verification on macOS**

Use the built or packaged app and verify:

1. Activate black-screen mode on an external display.
2. Start macOS screen saver or lock the screen.
3. Confirm VibeBlank closes its overlay when the protected state starts.
4. Unlock or wake the Mac.
5. Confirm the external display does not immediately become VibeBlank black.
6. Wait at least 1.5 seconds.
7. Use Command triple-tap or the menu and confirm black-screen mode still works.
8. Enable hot corner, leave the pointer near the configured corner, lock and unlock, and confirm it does not immediately re-open during the cooldown.

- [ ] **Step 6: Record verification result**

If automated checks pass but manual verification is not possible in the current turn, report that clearly with the exact automated commands that passed and the manual steps still needing real-device confirmation.
