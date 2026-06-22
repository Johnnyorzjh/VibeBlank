# VibeBlank New User Onboarding Design

## Goal

Improve the first install experience for new users without replacing the existing DMG installer style. The DMG should explain what happened after dragging the app, and the first app launch should confirm that setup is complete, show where to start, and expose login-item status.

## Design

- Keep the existing DMG background artwork and Finder layout. Add only short Chinese guidance text over the artwork: drag `黑码码.app` to `Applications`, open it from Applications, then use the menu bar icon.
- Add a first-launch onboarding window before the existing settings window. It uses the same native glass direction as the settings UI, a generated guide image, concise Chinese copy, and one primary action to start using the app.
- Store onboarding completion separately from the legacy first-launch flag as `hasCompletedOnboarding`, so upgrades and tests can reason about the new flow directly.
- Continue using `SMAppService.mainApp` through `LoginItemController`. The app can sync and report login-item status after first launch, but the DMG drag step itself cannot run code or provide install-completion automation.

## User Flow

1. User opens `VibeBlank.dmg`.
2. DMG background shows the existing visual with three light text prompts.
3. User drags `黑码码.app` to `Applications`.
4. User opens 黑码码.
5. Onboarding appears, shows install completion, menu bar entry, black-screen trigger basics, and login-item status.
6. User clicks `开始使用`; the app marks onboarding complete and opens the existing settings window once.

## Acceptance

- DMG still contains only `黑码码.app`, `Applications`, and hidden background assets.
- First launch shows onboarding before settings.
- Completing onboarding prevents it from showing again.
- Core checks cover onboarding persistence and reset behavior.
- Packaging still creates `.app`, `.zip`, and `.dmg`.
