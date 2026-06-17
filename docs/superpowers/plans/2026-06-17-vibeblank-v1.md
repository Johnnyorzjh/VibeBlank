# VibeBlank V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS 13+ menu bar privacy utility that covers external displays, or all displays, with a non-click-through black overlay while user work continues running.

**Architecture:** Use a Swift Package executable with AppKit for NSApplication, menu bar status item, global hotkey monitoring, and borderless overlay windows. Use SwiftUI only for the settings/about window content. Keep pure settings logic testable without AppKit.

**Tech Stack:** Swift 6.3 compatible source, Swift Package Manager, AppKit, SwiftUI, XCTest, shell packaging script.

## Global Constraints

- Minimum supported OS is macOS 13 Ventura.
- Default behavior covers external displays only.
- App is a visual privacy tool, not a system lock screen.
- Core black screen functionality must work from the menu bar without sensitive permissions.
- Package output is local `.app` and `.zip`; Apple notarization is out of scope.
- V1 excludes Feishu notifications, agent state detection, real monitor power-off, Touch ID/password unlock, per-display selection, automatic updates, accounts, payments, and team management.

---

### Task 1: Project Skeleton

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `Sources/VibeBlank/main.swift`
- Create: `Tests/VibeBlankTests/SettingsStoreTests.swift`

**Interfaces:**
- Produces executable product `VibeBlank`.
- Produces test target `VibeBlankTests`.

- [x] Create a Swift package with macOS 13 platform target.
- [x] Add an AppKit-compatible executable entrypoint.
- [x] Add a placeholder XCTest target so `swift test` proves the package is wired.
- [x] Run `swift test` and expect package discovery to pass.

### Task 2: Settings Model and Persistence

**Files:**
- Create: `Sources/VibeBlankCore/AppSettings.swift`
- Create: `Sources/VibeBlankCore/SettingsStore.swift`
- Modify: `Package.swift`
- Modify: `Tests/VibeBlankTests/SettingsStoreTests.swift`

**Interfaces:**
- `AppSettings`: Codable, Equatable settings value.
- `OverlayScope`: `externalDisplays` or `allDisplays`.
- `OverlayContent`: `blank`, `time`, `statusText`, `customText`.
- `SettingsStore`: loads/saves settings from injected `UserDefaults`.

- [x] Test default settings match PRD.
- [x] Test invalid persisted values fall back to defaults.
- [x] Test settings save and reload.
- [x] Implement minimal settings model and store.

### Task 3: Overlay Windows

**Files:**
- Create: `Sources/VibeBlank/OverlayWindow.swift`
- Create: `Sources/VibeBlank/OverlayManager.swift`

**Interfaces:**
- `OverlayManager.activate(settings: AppSettings)`
- `OverlayManager.deactivate()`
- `OverlayManager.toggle(settings: AppSettings)`
- `OverlayManager.isActive: Bool`

- [x] Create one borderless non-click-through window per target `NSScreen`.
- [x] Default target screens to external screens when present, otherwise main screen as safe fallback.
- [x] Support all-displays scope.
- [x] Render blank/time/status/custom text content.
- [x] Consume mouse/key events inside overlay windows.
- [x] Optional click-to-exit and key-to-exit call back into `OverlayManager`.

### Task 4: Menu Bar and Settings UI

**Files:**
- Create: `Sources/VibeBlank/AppDelegate.swift`
- Create: `Sources/VibeBlank/SettingsWindowController.swift`
- Create: `Sources/VibeBlank/SettingsView.swift`
- Modify: `Sources/VibeBlank/main.swift`

**Interfaces:**
- `AppDelegate` owns `SettingsStore`, `OverlayManager`, `NSStatusItem`, hotkey monitor, and settings window.
- `SettingsView` edits an observed `SettingsViewModel`.

- [x] App runs as accessory/menu bar style.
- [x] Menu supports activate/deactivate, current scope, open settings, and quit.
- [x] First launch opens settings window.
- [x] Settings UI exposes scope, overlay content, custom text, click-to-exit, key-to-exit, and global hotkey enablement.
- [x] Global hotkey defaults to Control+Option+Command+B and toggles overlay when enabled.

### Task 5: Packaging and Documentation

**Files:**
- Create: `scripts/package_app.sh`
- Create: `README.md`

**Interfaces:**
- `scripts/package_app.sh` builds release binary and writes `dist/VibeBlank.app` and `dist/VibeBlank.zip`.

- [x] Generate `.app` bundle with `Info.plist`, `LSUIElement=true`, minimum macOS 13, and executable copied into `Contents/MacOS`.
- [x] Zip the app for local sharing.
- [x] Document install, use, security boundary, permissions, and build/package commands.

### Task 6: Verification

**Files:**
- No source changes expected unless verification finds defects.

**Commands:**
- `swift run VibeBlankCoreChecks`
- `swift build`
- `bash scripts/package_app.sh`

- [x] Confirm core checks pass.
- [x] Confirm debug build succeeds.
- [x] Confirm package script creates `.app` and `.zip`.
