# VibeBlank New User Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add lightweight DMG guidance and first-launch onboarding so new users know what happened after installation and how to start using 黑码码.

**Architecture:** Keep the DMG as a Finder drag installer with the existing background and add deterministic text overlays to the background asset. Add a focused AppKit window controller and SwiftUI onboarding view that reads login-item status from the existing app delegate flow and marks a new onboarding flag in `SettingsStore`.

**Tech Stack:** SwiftPM, SwiftUI, AppKit, ServiceManagement, Bash, `hdiutil`, generated PNG assets.

## Global Constraints

- Product display name remains `黑码码`.
- Distribution remains DMG + `.app` + `.zip`; no `.pkg` installer.
- DMG drag does not run app code or claim automatic completion feedback.
- Onboarding copy is Chinese, concise, and native macOS glass styled.
- Generated guide image is used only inside onboarding.

---

### Task 1: Persist Onboarding Completion

**Files:**
- Modify: `Sources/VibeBlankCore/SettingsStore.swift`
- Modify: `Checks/VibeBlankCoreChecks/main.swift`

**Interfaces:**
- Produces: `SettingsStore.hasCompletedOnboarding: Bool`, `markOnboardingCompleted()`.

- [x] Add an independent `hasCompletedOnboarding` defaults key.
- [x] Add a core check that the flag defaults false, persists true, and resets in `resetForTests()`.

### Task 2: Add First-Launch Onboarding UI

**Files:**
- Modify: `Sources/VibeBlank/AppCopy.swift`
- Create: `Sources/VibeBlank/OnboardingWindowController.swift`
- Create: `Sources/VibeBlank/OnboardingView.swift`
- Modify: `Sources/VibeBlank/AppDelegate.swift`

**Interfaces:**
- Consumes: `LoginItemSyncStatus.displayName`, `SettingsStore.markOnboardingCompleted()`.
- Produces: first-launch onboarding before the existing settings window.

- [x] Add onboarding copy in `AppCopy`.
- [x] Add a glass AppKit window hosting a SwiftUI onboarding view.
- [x] Add start and settings actions that mark onboarding complete and open settings once.

### Task 3: Generate And Package Visual Assets

**Files:**
- Create: `assets/onboarding-guide.png`
- Modify: `assets/dmg-background.png`
- Modify: `scripts/package_app.sh`

**Interfaces:**
- Produces: `onboarding-guide.png` in app `Contents/Resources`.

- [x] Generate a guide image showing menu-bar entry, black overlay, corner timer, and shortcut trigger.
- [x] Overlay three short install steps onto the existing DMG background.
- [x] Copy the onboarding image into packaged app resources.

### Task 4: Verify Release Behavior

**Files:**
- Update: `dist/VibeBlank.app`
- Update: `dist/VibeBlank.zip`
- Update: `dist/VibeBlank.dmg`

**Interfaces:**
- Produces: verified local install artifacts for user testing.

- [x] Run `swift run VibeBlankCoreChecks`.
- [x] Run `swift build --product VibeBlank`.
- [x] Run `bash scripts/package_app.sh`.
- [x] Mount DMG and inspect contents.
- [x] Reset local defaults, launch packaged app, confirm onboarding appears once, then restore a clean app state.
