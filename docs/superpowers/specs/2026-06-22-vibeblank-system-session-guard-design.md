# VibeBlank System Session Guard Design

## Context

VibeBlank is a visual privacy overlay, not a system lock screen or authentication layer. The current trigger system can enter black-screen mode from the menu, Command triple-tap, a custom combo hotkey, or the built-in hot corner. The reported issue is that after macOS enters its own protected flow, such as screen saver or lock screen, unlocking can leave the external display black again. That makes the app feel like it is fighting macOS instead of stepping aside for it.

The desired behavior is: once macOS enters screen saver, lock screen, display sleep, or a closely related protected session state, VibeBlank must not remain in or automatically re-enter black-screen mode. After the user returns, black-screen mode should stay off until the user intentionally triggers it again.

## Goals

- Treat macOS protected session states as higher priority than VibeBlank black-screen mode.
- If VibeBlank is active when macOS enters a protected session state, deactivate it.
- Ignore menu, keyboard, and hot-corner activation attempts while macOS is protected.
- Ignore activation attempts for a short cooldown after unlock or wake, so stale input and hot-corner positions do not immediately re-open black-screen mode.
- Keep the change small and isolated from the current settings-window work.

## Non-Goals

- Do not turn VibeBlank into a lock-screen replacement.
- Do not add a user setting for this behavior.
- Do not use private macOS APIs.
- Do not change overlay visuals, settings layout, login-item behavior, or trigger configuration.
- Do not solve unrelated display arrangement or shortcut conflict issues.

## Recommended Approach

Add an AppKit-side `SystemSessionGuard` owned by `AppDelegate`.

The guard has one responsibility: track whether VibeBlank may currently activate the overlay. It listens to public system notifications for protected-session transitions and exposes a small interface:

- `canActivateOverlay: Bool`
- `onProtectedSessionStarted: (() -> Void)?`
- `markProtectedSessionStarted()`
- `markProtectedSessionEnded()`

`AppDelegate` wires `onProtectedSessionStarted` to `overlayManager.forceDeactivate()`. It also checks `canActivateOverlay` before every path that can create an overlay:

- menu toggle
- Command triple-tap
- custom combo hotkey
- built-in hot corner
- settings changes that rebuild an active overlay

This keeps `OverlayManager` focused on windows and screen selection. It also keeps trigger controllers focused on detecting user input rather than understanding macOS session state.

## Behavior

### Entering Protected Session

When macOS reports screen saver start, session lock, display sleep, system sleep, or an equivalent protected transition:

1. `SystemSessionGuard` enters protected state.
2. `AppDelegate` receives the guard callback.
3. If VibeBlank has overlay windows, `overlayManager.forceDeactivate()` closes them immediately.
4. Menu state is refreshed through the existing overlay state callback.

The immediate close is intentional. System screen saver and lock screen already provide the visible state; VibeBlank should not animate over or under them.

### While Protected

While protected, every activation entry point is ignored. If the user presses the hotkey, taps Command, moves the pointer through the hot corner, or picks the menu item during that period, VibeBlank remains off.

### Returning From Protected Session

When macOS reports unlock, screen saver stop, display wake, or system wake:

1. `SystemSessionGuard` exits protected state.
2. It starts a short activation cooldown, recommended at 1.5 seconds.
3. During cooldown, `canActivateOverlay` remains false.
4. After cooldown, normal activation behavior resumes.

The cooldown prevents the common awkward path: the pointer is still sitting in the hot corner, or a key event from unlock arrives late, and VibeBlank immediately opens again.

### Existing Manual Behavior

After the cooldown ends, all existing explicit triggers keep their current meaning:

- menu toggles the overlay
- Command triple-tap toggles the overlay
- custom combo hotkey toggles the overlay
- hot corner opens the overlay only
- Escape remains the reliable exit fallback while VibeBlank is active

## Components

### `SystemSessionGuard`

New file: `Sources/VibeBlank/SystemSessionGuard.swift`

Responsibilities:

- Subscribe to public `NSWorkspace.shared.notificationCenter` notifications that are present in the local SDK:
  - `NSWorkspaceSessionDidResignActiveNotification`
  - `NSWorkspaceSessionDidBecomeActiveNotification`
  - `NSWorkspaceScreensDidSleepNotification`
  - `NSWorkspaceScreensDidWakeNotification`
  - `NSWorkspaceWillSleepNotification`
  - `NSWorkspaceDidWakeNotification`
- During implementation, manually verify the screen-saver path. If the `NSWorkspace` notifications do not cover that path, add best-effort screen-saver-specific distributed notifications only if they do not require private frameworks or compile-time private API references.
- Maintain `isProtectedSessionActive`.
- Maintain `cooldownEndsAt`.
- Expose `canActivateOverlay`.
- Call `onProtectedSessionStarted` exactly when entering protected state.
- Invalidate any pending cooldown timer when protected state starts again.

The guard should be `@MainActor` because `AppDelegate` and overlay state are main-thread AppKit concerns.

### `AppDelegate`

Modify: `Sources/VibeBlank/AppDelegate.swift`

Responsibilities:

- Own `private let systemSessionGuard = SystemSessionGuard()`.
- Configure the guard callback in `configureCallbacks()`.
- Route all activation attempts through a helper, for example `guardCanActivateOverlay()`.
- Use the helper in `toggleOverlay()`, `activateOverlayIfNeeded()`, and the active-overlay settings rebuild path.

When a toggle request arrives while VibeBlank is already active, deactivation should still be allowed. The guard blocks only activation or rebuilds that would create overlay windows.

### `OverlayManager`

No new responsibility. It already has `forceDeactivate()` for immediate teardown and should remain focused on overlay windows.

## Data Flow

```text
macOS protected event
  -> SystemSessionGuard marks protected
  -> AppDelegate force-deactivates OverlayManager
  -> overlay windows close
  -> protected activation attempts are ignored
  -> macOS return event starts cooldown
  -> cooldown expires
  -> explicit VibeBlank triggers work again
```

## Error Handling

- If one notification does not fire for a specific macOS path, the guard still relies on the other session, screen-sleep, and system-sleep notifications.
- Repeated start notifications are idempotent.
- Repeated end notifications refresh the cooldown but do not activate VibeBlank.
- If activation is blocked, no alert is shown. The menu already remains available, and this behavior is a safety boundary rather than a user-facing error.

## Testing

Automated checks:

- Add a testable pure state machine, for example `SystemSessionActivationGate` in `VibeBlankCore`, to verify:
  - activation is allowed by default
  - activation is blocked in protected state
  - activation remains blocked during cooldown after protected state ends
  - activation is allowed after cooldown expires
  - deactivation is never blocked
- Run `swift run VibeBlankCoreChecks`.
- Run `swift build --product VibeBlank`.

Manual verification:

1. Launch the packaged or built app.
2. Activate black-screen mode on an external display.
3. Start macOS screen saver or lock the screen.
4. Confirm VibeBlank overlay closes when macOS protected state begins.
5. Unlock or wake the Mac.
6. Confirm the external display does not immediately become VibeBlank black.
7. Wait for cooldown, then use an explicit trigger and confirm black-screen mode still works.
8. Repeat with hot corner enabled and the pointer left near the configured corner.

## Acceptance Criteria

1. System screen saver, lock screen, display sleep, and system sleep cause active VibeBlank overlays to close.
2. Unlocking or waking does not automatically re-enter black-screen mode.
3. Activation attempts during protected state and the short return cooldown are ignored.
4. After cooldown, existing menu, keyboard, and hot-corner triggers still behave as before.
5. The implementation does not add settings UI or private API usage.
6. Existing dirty settings-window work remains untouched.
7. `swift run VibeBlankCoreChecks` and `swift build --product VibeBlank` pass after implementation.
