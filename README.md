# VibeBlank

VibeBlank is a lightweight macOS menu bar privacy tool for short breaks during long-running coding-agent work. It covers external displays, or all displays, with a black overlay while your IDE, terminal, local services, builds, and agents keep running.

It is a visual privacy helper, not a lock screen. Use macOS Lock Screen when you need authentication or company security guarantees.

## Requirements

- macOS 13 Ventura or later.
- Swift command line tools for local builds.
- No Apple Developer account is required for local `.app`/`.zip` packaging.

## Features

- Menu bar app with no default Dock icon.
- Default scope: external displays only.
- Optional scope: all displays.
- Overlay content modes: blank, time, status text, or custom text.
- Overlay windows consume mouse and keyboard events.
- Optional click-to-exit and key-to-exit.
- Escape always exits black screen mode as a safety fallback.
- Global hotkey: Control-Option-Command-B.
- First-launch settings window with the safety boundary explained.
- Local `.app` and `.zip` packaging.

## Build and Verify

```bash
swift run VibeBlankCoreChecks
swift build --product VibeBlank
bash scripts/package_app.sh
```

The package command creates:

- `dist/VibeBlank.app`
- `dist/VibeBlank.zip`

## Run

Open `dist/VibeBlank.app`.

Because this V1 build is not notarized, macOS may require right-clicking the app and choosing **Open** the first time.

## Use

1. Launch VibeBlank.
2. Review the first-launch settings window.
3. Use the menu bar item to activate black screen mode.
4. Use the menu bar item again, or Control-Option-Command-B, to exit.
5. Press Escape if you need a guaranteed keyboard escape from the overlay.

Settings are saved automatically.

## Notes

- Trigger corners are planned as a later enhancement.
- If no external display is detected, external-display mode covers the main display as visible feedback.
- VibeBlank does not turn monitors off, lock macOS, require Touch ID, monitor coding agents, or send Feishu notifications in V1.
