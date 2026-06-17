# VibeBlank V1 Technical Solution

## 1. Goal

VibeBlank V1 is a native macOS 13+ menu bar app for short-away visual privacy. It covers selected displays with full-screen black overlay windows while the user's IDE, terminal, local services, and coding agents continue to run.

V1 is intentionally not a lock screen. It prevents casual visual exposure and accidental clicks/keystrokes on covered displays, but it does not provide authentication, system lock guarantees, monitor power control, or endpoint security.

## 2. Architecture

The project is implemented as a Swift Package:

- `VibeBlankCore`: pure Swift settings model and persistence. This target is covered by XCTest and does not import AppKit.
- `VibeBlank`: AppKit/SwiftUI executable. This target owns the menu bar item, settings window, overlay windows, hotkey registration, and packaging runtime behavior.
- `scripts/package_app.sh`: release build wrapper that creates `dist/VibeBlank.app` and `dist/VibeBlank.zip`.

This keeps the testable product rules separate from macOS windowing code, while still avoiding the weight of a full Xcode project.

## 3. Core Modules

### Settings

`AppSettings` stores the user-facing choices:

- `overlayScope`: external displays only, or all displays.
- `overlayContentMode`: blank, time, status text, or custom text.
- `customText`: text used when custom mode is selected.
- `clickToExitEnabled`: whether clicking the overlay exits black screen mode.
- `keyToExitEnabled`: whether pressing a key exits black screen mode.
- `globalHotkeyEnabled`: whether Control+Option+Command+B toggles the overlay.

`SettingsStore` persists settings as JSON data in `UserDefaults`. Corrupt or missing data falls back to PRD defaults.

### Menu Bar Controller

`AppDelegate` starts the app in `.accessory` activation policy so it behaves like a menu bar utility. It owns:

- `NSStatusItem` and menu commands.
- `SettingsStore`.
- `OverlayManager`.
- `SettingsWindowController`.
- Global hotkey registration.

The menu is rebuilt when overlay state or settings change, so labels always reflect the current mode.

### Overlay System

`OverlayManager` decides which screens to cover:

- For external-display scope, it selects screens whose `CGDirectDisplayID` is not built in.
- If no external display exists, it falls back to the main screen so the action still has visible feedback.
- For all-display scope, it covers every `NSScreen`.

For each target screen, it creates an `OverlayWindow`:

- Borderless full-screen frame equal to the screen frame.
- High window level to stay above ordinary app windows.
- `ignoresMouseEvents = false` so events do not pass through.
- Key/mouse overrides consume events and optionally request exit.
- Escape always exits overlay mode as a safety fallback, even when key-to-exit is disabled.

Overlay content is rendered with SwiftUI inside an `NSHostingView`.

### Settings UI

The settings window is a small SwiftUI form hosted by AppKit. It exposes only V1 settings and repeats the security boundary in user-facing language. Changes are saved immediately and notify `AppDelegate` to update the hotkey/menu state.

### Hotkey

The default global shortcut is Control+Option+Command+B. It uses Carbon `RegisterEventHotKey`, which avoids requiring broad input monitoring for the core toggle path. If registration fails, the menu path still works.

### Packaging

SwiftPM builds a release executable. The packaging script creates a minimal app bundle:

- `Contents/MacOS/VibeBlank`
- `Contents/Info.plist`
- `LSUIElement=true`
- `LSMinimumSystemVersion=13.0`

The script then zips the app for local sharing. Notarization and signing are intentionally out of scope for V1.

## 4. Data Flow

1. App launches.
2. `AppDelegate` loads settings from `SettingsStore`.
3. First launch opens settings so the user sees the purpose and safety boundary.
4. User triggers black screen mode from the menu or hotkey.
5. `OverlayManager` reads the current settings and creates overlay windows on target screens.
6. Overlay windows consume input until the user exits via menu, hotkey, click-to-exit, or key-to-exit.
7. When settings change, `SettingsStore` saves them and posts a settings-changed notification.

## 5. Error Handling

- Missing or corrupt settings: use defaults.
- No external display found: cover the main display as a visible fallback.
- Hotkey registration failure: continue running, show "Hotkey: Unavailable" in the menu, and rely on menu commands or Escape.
- Screen layout changes while active: rebuild overlays on the current screen list.
- Empty custom text: display `VibeBlank Active`.

## 6. Verification

Automated checks:

- `swift run VibeBlankCoreChecks`
- `swift build`
- `bash scripts/package_app.sh`

Manual checks on macOS:

- Launch `dist/VibeBlank.app`.
- Confirm no Dock icon is shown.
- Confirm menu bar item appears.
- With an external display connected, activate default mode and confirm only external displays are covered.
- Switch to all displays and confirm every display is covered.
- Confirm clicks and keypresses do not reach covered apps.
- Enable click-to-exit and key-to-exit and confirm the triggering event only exits the overlay.
- Confirm Control+Option+Command+B toggles when enabled.
