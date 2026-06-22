# VibeBlank V4 Visual Overlay Design

## Summary

V4 upgrades 黑码码 from a simple black privacy overlay into a more expressive visual privacy surface. The release focuses on three user-facing additions:

- A particle-style elapsed timer inspired by Nothing Phone-style dot-matrix numerals.
- A fixed-corner timer placement option so the timer can sit quietly in a small part of the screen.
- Native white glass and black heavy-glass overlay styles, in addition to the existing pure black style.

The release does not connect to real AI task status. It leaves a clear V5 path where the same corner widget can display task progress or completion state after a separate data-source design.

## Goals

- Preserve the current low-permission menu-bar utility model.
- Keep the default experience compatible with existing users: pure black overlay, no visible content.
- Let users opt into a visually distinctive elapsed timer that starts when the overlay activates.
- Let users place the timer in one of four screen corners.
- Add artistic privacy styles using native macOS blur materials without requiring screen-recording permission.
- Keep Esc, menu-bar activation, Command triple-tap, combo hotkey, hot corner, display scope, and existing exit behavior unchanged.

## Non-Goals

- Do not implement a countdown timer in V4.
- Do not let users drag the timer around the overlay.
- Do not connect to Codex, terminal, Feishu, local logs, or any other AI task-status source.
- Do not request Screen Recording permission for screenshot-based blur.
- Do not replace macOS lock screen, authentication, or system screen saver behavior.
- Do not change the existing trigger system.

## User Experience

### Overlay Content

V4 adds a new overlay content mode named `粒子计时`. When selected, the overlay shows an elapsed timer that starts from `00:00` each time the overlay is activated.

The timer format is:

- `MM:SS` before one hour, for example `00:00`, `05:17`, `59:59`.
- `HH:MM:SS` from one hour onward, for example `01:00:00`.

The timer resets on each activation. Deactivating and reactivating the overlay starts a new elapsed session.

### Particle Numerals

The particle timer is rendered as fixed dot-matrix numerals:

- Digits use a stable 5 by 7 matrix.
- Colon separators use two vertically aligned dots.
- Particles do not drift or scatter; the look should feel precise, calm, and device-like.
- Particles may use subtle opacity variation or breathing while visible, but the animation must not make the time hard to read.
- The timer should be readable on both dark and light glass styles.

### Position

V4 adds a timer position setting with four options:

- 左上角
- 右上角
- 左下角
- 右下角

The default is `右下角`. The timer sits inside the safe area with fixed padding from the selected edges. It should never be centered by default, because V4 is meant to keep the overlay quiet and leave the screen feeling intentionally blank.

The setting applies only to `粒子计时`. Existing `时间`, `状态文字`, and `自定义文字` modes continue to render centered.

### Overlay Style

V4 adds a background style setting with three options:

- `纯黑`: the existing full black overlay.
- `白色毛玻璃`: a bright native visual-effect surface with a light tint.
- `黑色强毛玻璃`: a dark native visual-effect surface with a heavy black tint.

The default is `纯黑`.

The glass styles should use `NSVisualEffectView` through the existing `NativeGlassSurface` bridge. They may add SwiftUI tint layers on top, but must not use screenshot capture or screen-recording permission.

### Settings

The existing settings window keeps the same high-level page structure. The `遮罩` page gains:

- A new `背景样式` picker for the overlay style.
- The existing `显示内容` picker includes `粒子计时`.
- A `计时器位置` picker appears only when `显示内容` is `粒子计时`.

The copy stays short and Chinese-facing, matching the current 黑码码 UI.

## Architecture

### Core Settings

`VibeBlankCore` owns new persisted settings:

- `OverlayBackgroundStyle`
  - `pureBlack`
  - `whiteGlass`
  - `blackGlass`
- `TimerPlacement`
  - `topLeft`
  - `topRight`
  - `bottomLeft`
  - `bottomRight`

`AppSettings` gains:

- `overlayBackgroundStyle: OverlayBackgroundStyle`
- `timerPlacement: TimerPlacement`

Defaults:

- `overlayBackgroundStyle = .pureBlack`
- `timerPlacement = .bottomRight`

`OverlayContentMode` gains:

- `particleTimer`

Older saved settings must decode successfully and receive the V4 defaults.

### Overlay Rendering

`OverlayContentView` remains the root SwiftUI overlay content. It should delegate V4-specific rendering into small focused views:

- `OverlayBackgroundView`
  - Renders pure black, white glass, or black glass.
  - Keeps the existing edge-collapse transition behavior.
- `ParticleTimerView`
  - Displays elapsed time using dot-matrix glyphs.
  - Owns visual spacing, particle size, and animation.
- `ParticleDigit`
  - Renders a single digit or colon from a static matrix definition.

The overlay activation time should be captured when each `OverlayContentView` instance is created. The timer display derives elapsed seconds from that activation timestamp and the existing one-second timer tick.

### Data Flow

1. User changes `背景样式`, `显示内容`, or `计时器位置` in settings.
2. `SettingsViewModel` saves updated `AppSettings`.
3. `AppDelegate.settingsDidChange()` resyncs triggers and, if the overlay is active, asks `OverlayManager` to reactivate with the latest settings.
4. `OverlayManager` creates one `OverlayWindow` per target display.
5. Each `OverlayWindow` hosts `OverlayContentView(settings:transition:)`.
6. `OverlayContentView` renders the selected background and selected content mode.

### Error Handling

- If native glass material is unavailable or renders differently across macOS variants, the overlay still includes tint layers so content remains visually obscured.
- If older saved settings omit new V4 fields, decoding falls back to V4 defaults.
- If a future enum value cannot be decoded, the existing settings decode fallback still returns `AppSettings.defaults`.
- Esc and menu-bar exit remain independent of the visual style.

## Testing

### Core Checks

Extend `VibeBlankCoreChecks` to cover:

- V4 defaults are pure black background, blank content, and bottom-right timer placement.
- Saving and reloading settings preserves `overlayBackgroundStyle`, `overlayContentMode = .particleTimer`, and `timerPlacement`.
- V2/V3-style saved JSON without V4 fields decodes with V4 defaults.
- Particle timer formatting returns `00:00`, `05:17`, `59:59`, and `01:00:00` for representative elapsed durations.

Timer formatting should live in `VibeBlankCore` so it can be checked without UI tests.

### Build Checks

Run:

```bash
swift run VibeBlankCoreChecks
swift build --product VibeBlank
```

### Manual Visual Acceptance

After implementation, package and run the app, then verify:

- Existing pure black blank overlay still works.
- `粒子计时` starts at `00:00` and increments once per second.
- Each timer corner option places the timer in the chosen corner.
- White glass obscures screen content while feeling bright and soft.
- Black heavy glass obscures screen content while retaining the darker privacy feel.
- Esc exits from every background style.
- Per-display verification still uses packaged app screenshots with `screencapture -D 1` and `screencapture -D 2` when multiple displays are available.

## V5 Outlook

V4 deliberately keeps the corner widget local and timer-only. V5 can reuse the same placement, particle rendering language, and settings surface to display AI task status, such as:

- `AI 任务进行中`
- elapsed run time
- completion state
- a subtle success pulse when a task finishes

That future work needs a separate design for trusted task-state sources, failure modes, privacy boundaries, and how the app learns whether a task is actually complete.
