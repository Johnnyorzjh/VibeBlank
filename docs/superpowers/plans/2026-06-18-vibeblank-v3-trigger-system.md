# VibeBlank V3 Trigger System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade 黑码码 from a fixed menu-bar/hotkey utility into a configurable trigger system with login startup, Command triple-tap, custom combo hotkeys, and hot-corner fallback.

**Architecture:** Keep user settings and migration-safe defaults in `VibeBlankCore`. Add small AppKit-side controllers for login items, combo hotkeys, modifier triple-tap monitoring, and hot-corner polling; `AppDelegate` owns composition and maps all trigger callbacks to the existing overlay manager.

**Tech Stack:** Swift 5.9, AppKit, SwiftUI, Carbon HIToolbox, ServiceManagement, UserDefaults, SwiftPM.

## Global Constraints

- macOS minimum remains 13.0.
- No private Apple APIs and no direct writes to Dock or System Settings private configuration.
- Default keyboard trigger is any Command triple-tap within about 0.8 seconds.
- The legacy `Control + Option + Command + B` combo remains available but is disabled by default.
- Hot corner is disabled by default and only opens black-screen mode, never exits it.
- Login at launch defaults to enabled for new and upgraded users.
- User-facing feature name remains "黑屏模式"; headline copy uses "让 AI 悄悄帮你干活".

---

### Task 1: Settings Model And Checks

**Files:**
- Modify: `Sources/VibeBlankCore/AppSettings.swift`
- Modify: `Checks/VibeBlankCoreChecks/main.swift`

**Interfaces:**
- Produces: `ScreenCorner`, `CornerTriggerSettings`, `CommandSide`, `ModifierTapTriggerSettings`, `ComboHotKeySettings`, and new `AppSettings` fields.

- [x] Add V3 settings types with Codable/Equatable defaults.
- [x] Set `launchAtLoginEnabled = true`, `modifierTapTrigger.isEnabled = true`, and `comboHotkeyTrigger.isEnabled = false`.
- [x] Add checks for V3 defaults, custom save/reload, and corrupt fallback.
- [x] Run `swift run VibeBlankCoreChecks`.

### Task 2: Trigger Controllers

**Files:**
- Modify: `Sources/VibeBlank/HotKeyController.swift`
- Create: `Sources/VibeBlank/ModifierTapTriggerController.swift`
- Create: `Sources/VibeBlank/HotCornerTriggerController.swift`
- Create: `Sources/VibeBlank/LoginItemController.swift`

**Interfaces:**
- Consumes: `ComboHotKeySettings`, `ModifierTapTriggerSettings`, `CornerTriggerSettings`.
- Produces: reusable controller APIs for `AppDelegate`.

- [x] Update `HotKeyController` to register dynamic combo settings with exclusive conflict detection.
- [x] Implement Command triple-tap via local and global `.flagsChanged` monitors.
- [x] Implement built-in hot-corner fallback with a timer, all-screen corner detection, and 2s cooldown.
- [x] Implement login item sync through `SMAppService.mainApp`.

### Task 3: App Wiring And UI

**Files:**
- Modify: `Sources/VibeBlank/AppDelegate.swift`
- Modify: `Sources/VibeBlank/SettingsViewModel.swift`
- Modify: `Sources/VibeBlank/SettingsView.swift`
- Modify: `Sources/VibeBlank/AppCopy.swift`

**Interfaces:**
- Consumes: trigger controllers from Task 2.
- Produces: user-visible V3 trigger settings and menu status.

- [x] Wire all trigger callbacks to `toggleOverlay()` for keyboard and `activateOverlayIfNeeded()` for corners.
- [x] Sync login item, hot corner, Command triple-tap, and combo hotkey registration on launch and settings changes.
- [x] Add settings controls for login at startup, hot corner selection, Command side selection, combo enablement, combo recording, conflict errors, and permission guidance.
- [x] Update menu status to show primary trigger, combo availability, permission state, and hot-corner state.

### Task 4: Docs And Verification

**Files:**
- Modify: `README.md`
- Create: `docs/vibeblank-v3-requirements.md`

**Interfaces:**
- Documents V3 behavior and the official hot-corner spike conclusion.

- [x] Document that no stable public API was found for third-party direct registration into macOS official Hot Corners.
- [x] Document the built-in fallback behavior and permission expectations.
- [x] Run `swift run VibeBlankCoreChecks`.
- [x] Run `swift build --product VibeBlank`.
- [x] Run `bash scripts/package_app.sh`.
