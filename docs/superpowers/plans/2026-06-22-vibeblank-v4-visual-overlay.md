# VibeBlank V4 Visual Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved V4 visual overlay: particle elapsed timer, fixed-corner placement, and pure black / white glass / black heavy-glass overlay styles.

**Architecture:** Keep V4 as a visual-layer expansion on the existing SwiftPM AppKit + SwiftUI menu-bar app. Persist new visual settings in `VibeBlankCore`, keep formatting logic testable outside UI, and keep overlay rendering split into focused SwiftUI views hosted by the existing `OverlayWindow`.

**Tech Stack:** Swift 5.9, Swift Package Manager, macOS 13+, AppKit, SwiftUI, `NSVisualEffectView` through the existing `NativeGlassSurface`, `UserDefaults`, custom `VibeBlankCoreChecks`.

## Global Constraints

- Preserve the current low-permission menu-bar utility model.
- Keep the default experience compatible with existing users: pure black overlay, no visible content.
- Let users opt into a visually distinctive elapsed timer that starts when the overlay activates.
- Let users place the timer in one of four screen corners.
- Add artistic privacy styles using native macOS blur materials without requiring screen-recording permission.
- Keep Esc, menu-bar activation, Command triple-tap, combo hotkey, hot corner, display scope, and existing exit behavior unchanged.
- Do not implement a countdown timer in V4.
- Do not let users drag the timer around the overlay.
- Do not connect to Codex, terminal, Feishu, local logs, or any other AI task-status source.
- Do not request Screen Recording permission for screenshot-based blur.
- Do not change the existing trigger system.

---

## File Structure

- Modify `Sources/VibeBlankCore/AppSettings.swift`
  - Add `OverlayBackgroundStyle`, `TimerPlacement`, and `OverlayContentMode.particleTimer`.
  - Persist `overlayBackgroundStyle` and `timerPlacement` with V4 defaults during decode.
- Create `Sources/VibeBlankCore/ElapsedTimerFormatter.swift`
  - Format elapsed seconds as `MM:SS` or `HH:MM:SS`.
- Modify `Checks/VibeBlankCoreChecks/main.swift`
  - Add checks for V4 defaults, V4 save/reload, V3 JSON migration, and elapsed timer formatting.
- Modify `Sources/VibeBlank/AppCopy.swift`
  - Add Chinese settings copy for background style and timer placement.
- Modify `Sources/VibeBlank/SettingsView.swift`
  - Add `背景样式` picker.
  - Add conditional `计时器位置` picker when `显示内容 == .particleTimer`.
- Create `Sources/VibeBlank/OverlayBackgroundView.swift`
  - Render pure black, white glass, and black heavy-glass backgrounds while preserving edge-collapse transition.
- Modify `Sources/VibeBlank/OverlayContentView.swift`
  - Track activation time.
  - Delegate background rendering to `OverlayBackgroundView`.
  - Render centered legacy text modes and corner-placed particle timer mode.
- Create `Sources/VibeBlank/ParticleTimerView.swift`
  - Render dot-matrix elapsed time and corner placement.
- Modify `README.md`
  - Refresh the feature list and usage notes for V4 visual overlay options.

---

### Task 1: Core Settings And Timer Formatting

**Files:**
- Modify: `Sources/VibeBlankCore/AppSettings.swift`
- Create: `Sources/VibeBlankCore/ElapsedTimerFormatter.swift`
- Modify: `Sources/VibeBlank/OverlayContentView.swift`
- Test: `Checks/VibeBlankCoreChecks/main.swift`

**Interfaces:**
- Produces: `public enum OverlayBackgroundStyle: String, Codable, CaseIterable, Equatable, Identifiable`
- Produces: `public enum TimerPlacement: String, Codable, CaseIterable, Equatable, Identifiable`
- Produces: `OverlayContentMode.particleTimer`
- Produces: `public enum ElapsedTimerFormatter { public static func string(elapsedSeconds: Int) -> String }`
- Consumes: existing `AppSettings`, `SettingsStore`, `OverlayContentView`, and `VibeBlankCoreChecks`.

- [ ] **Step 1: Write failing core checks**

In `Checks/VibeBlankCoreChecks/main.swift`, add these functions after `checkV2SettingsUpgradeToV3Defaults()`:

```swift
private func checkV4DefaultsMatchVisualOverlaySpec() throws {
    let settings = AppSettings.defaults

    try expect(settings.overlayBackgroundStyle == .pureBlack, "V4 default background should be pure black")
    try expect(settings.overlayContentMode == .blank, "V4 default content should remain blank")
    try expect(settings.timerPlacement == .bottomRight, "V4 default timer placement should be bottom right")
}

private func checkSaveAndReloadV4VisualSettings() throws {
    let context = makeStore()
    defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

    let settings = AppSettings(
        overlayScope: .allDisplays,
        overlayContentMode: .particleTimer,
        overlayBackgroundStyle: .blackGlass,
        timerPlacement: .topLeft,
        customText: "Focus",
        clickToExitEnabled: true,
        keyToExitEnabled: true,
        launchAtLoginEnabled: false,
        cornerTrigger: CornerTriggerSettings(isEnabled: true, corner: .bottomRight),
        modifierTapTrigger: ModifierTapTriggerSettings(isEnabled: true, commandSide: .left),
        comboHotKeyTrigger: ComboHotKeySettings(
            isEnabled: true,
            keyCode: 9,
            modifiers: 768,
            displayName: "Shift + Command + V"
        ),
        keyboardPermissionStatus: .granted,
        hotKeyConflictStatus: .available
    )

    context.store.save(settings)

    try expect(context.store.load() == settings, "saved V4 visual settings should reload exactly")
}

private func checkV3SettingsUpgradeToV4Defaults() throws {
    let context = makeStore()
    defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

    let v3JSON = """
    {
      "overlayScope": "externalDisplays",
      "overlayContentMode": "time",
      "customText": "",
      "clickToExitEnabled": false,
      "keyToExitEnabled": false,
      "launchAtLoginEnabled": true,
      "cornerTrigger": {
        "isEnabled": false,
        "corner": "topRight"
      },
      "modifierTapTrigger": {
        "isEnabled": true,
        "commandSide": "any",
        "tapCount": 3,
        "maxInterval": 0.8
      },
      "comboHotKeyTrigger": {
        "isEnabled": false,
        "keyCode": 11,
        "modifiers": 6400,
        "displayName": "Control + Option + Command + B"
      },
      "keyboardPermissionStatus": "unknown",
      "hotKeyConflictStatus": "unchecked"
    }
    """
    context.defaults.set(Data(v3JSON.utf8), forKey: "settings")

    let settings = context.store.load()
    try expect(settings.overlayBackgroundStyle == .pureBlack, "V3 settings should receive pure black V4 default")
    try expect(settings.timerPlacement == .bottomRight, "V3 settings should receive bottom-right timer placement")
    try expect(settings.overlayContentMode == .time, "V3 content mode should migrate")
}

private func checkElapsedTimerFormatting() throws {
    try expect(ElapsedTimerFormatter.string(elapsedSeconds: 0) == "00:00", "zero elapsed seconds should format as 00:00")
    try expect(ElapsedTimerFormatter.string(elapsedSeconds: 317) == "05:17", "317 seconds should format as 05:17")
    try expect(ElapsedTimerFormatter.string(elapsedSeconds: 3_599) == "59:59", "3599 seconds should format as 59:59")
    try expect(ElapsedTimerFormatter.string(elapsedSeconds: 3_600) == "01:00:00", "3600 seconds should format as 01:00:00")
    try expect(ElapsedTimerFormatter.string(elapsedSeconds: -10) == "00:00", "negative elapsed seconds should clamp to 00:00")
}
```

Add the new checks to the `checks` array:

```swift
    ("V4 defaults match visual overlay spec", checkV4DefaultsMatchVisualOverlaySpec),
    ("V4 visual settings save and reload", checkSaveAndReloadV4VisualSettings),
    ("V3 settings upgrade to V4 defaults", checkV3SettingsUpgradeToV4Defaults),
    ("elapsed timer formatting", checkElapsedTimerFormatting),
```

- [ ] **Step 2: Run checks to verify the failure**

Run:

```bash
swift run VibeBlankCoreChecks
```

Expected: FAIL at compile time because `overlayBackgroundStyle`, `TimerPlacement`, `.particleTimer`, and `ElapsedTimerFormatter` do not exist.

- [ ] **Step 3: Add the V4 core model**

In `Sources/VibeBlankCore/AppSettings.swift`, add these enums after `OverlayScope`:

```swift
public enum OverlayBackgroundStyle: String, Codable, CaseIterable, Equatable, Identifiable {
    case pureBlack
    case whiteGlass
    case blackGlass

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pureBlack:
            return "纯黑"
        case .whiteGlass:
            return "白色毛玻璃"
        case .blackGlass:
            return "黑色强毛玻璃"
        }
    }
}

public enum TimerPlacement: String, Codable, CaseIterable, Equatable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .topLeft:
            return "左上角"
        case .topRight:
            return "右上角"
        case .bottomLeft:
            return "左下角"
        case .bottomRight:
            return "右下角"
        }
    }
}
```

Update `OverlayContentMode`:

```swift
public enum OverlayContentMode: String, Codable, CaseIterable, Equatable, Identifiable {
    case blank
    case time
    case statusText
    case customText
    case particleTimer

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .blank:
            return "纯黑"
        case .time:
            return "时间"
        case .statusText:
            return "状态文字"
        case .customText:
            return "自定义文字"
        case .particleTimer:
            return "粒子计时"
        }
    }
}
```

Update `AppSettings` to include the new properties:

```swift
public struct AppSettings: Codable, Equatable {
    public var overlayScope: OverlayScope
    public var overlayContentMode: OverlayContentMode
    public var overlayBackgroundStyle: OverlayBackgroundStyle
    public var timerPlacement: TimerPlacement
    public var customText: String
    public var clickToExitEnabled: Bool
    public var keyToExitEnabled: Bool
    public var launchAtLoginEnabled: Bool
    public var cornerTrigger: CornerTriggerSettings
    public var modifierTapTrigger: ModifierTapTriggerSettings
    public var comboHotKeyTrigger: ComboHotKeySettings
    public var keyboardPermissionStatus: KeyboardPermissionStatus
    public var hotKeyConflictStatus: HotKeyConflictStatus

    public init(
        overlayScope: OverlayScope = .externalDisplays,
        overlayContentMode: OverlayContentMode = .blank,
        overlayBackgroundStyle: OverlayBackgroundStyle = .pureBlack,
        timerPlacement: TimerPlacement = .bottomRight,
        customText: String = "",
        clickToExitEnabled: Bool = false,
        keyToExitEnabled: Bool = false,
        launchAtLoginEnabled: Bool = true,
        cornerTrigger: CornerTriggerSettings = .defaults,
        modifierTapTrigger: ModifierTapTriggerSettings = .defaults,
        comboHotKeyTrigger: ComboHotKeySettings = .defaults,
        keyboardPermissionStatus: KeyboardPermissionStatus = .unknown,
        hotKeyConflictStatus: HotKeyConflictStatus = .unchecked
    ) {
        self.overlayScope = overlayScope
        self.overlayContentMode = overlayContentMode
        self.overlayBackgroundStyle = overlayBackgroundStyle
        self.timerPlacement = timerPlacement
        self.customText = customText
        self.clickToExitEnabled = clickToExitEnabled
        self.keyToExitEnabled = keyToExitEnabled
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.cornerTrigger = cornerTrigger
        self.modifierTapTrigger = modifierTapTrigger
        self.comboHotKeyTrigger = comboHotKeyTrigger
        self.keyboardPermissionStatus = keyboardPermissionStatus
        self.hotKeyConflictStatus = hotKeyConflictStatus
    }
```

Add the new coding keys:

```swift
    private enum CodingKeys: String, CodingKey {
        case overlayScope
        case overlayContentMode
        case overlayBackgroundStyle
        case timerPlacement
        case customText
        case clickToExitEnabled
        case keyToExitEnabled
        case launchAtLoginEnabled
        case cornerTrigger
        case modifierTapTrigger
        case comboHotKeyTrigger
        case keyboardPermissionStatus
        case hotKeyConflictStatus
    }
```

Decode the new fields with V4 defaults:

```swift
        overlayScope = try container.decodeIfPresent(OverlayScope.self, forKey: .overlayScope) ?? .externalDisplays
        overlayContentMode = try container.decodeIfPresent(OverlayContentMode.self, forKey: .overlayContentMode) ?? .blank
        overlayBackgroundStyle = try container.decodeIfPresent(
            OverlayBackgroundStyle.self,
            forKey: .overlayBackgroundStyle
        ) ?? .pureBlack
        timerPlacement = try container.decodeIfPresent(TimerPlacement.self, forKey: .timerPlacement) ?? .bottomRight
        customText = try container.decodeIfPresent(String.self, forKey: .customText) ?? ""
```

- [ ] **Step 4: Add elapsed timer formatter**

Create `Sources/VibeBlankCore/ElapsedTimerFormatter.swift`:

```swift
import Foundation

public enum ElapsedTimerFormatter {
    public static func string(elapsedSeconds: Int) -> String {
        let clampedSeconds = max(0, elapsedSeconds)
        let hours = clampedSeconds / 3_600
        let minutes = (clampedSeconds % 3_600) / 60
        let seconds = clampedSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

- [ ] **Step 5: Keep the app target compiling with a temporary text rendering path for particle timer**

In `Sources/VibeBlank/OverlayContentView.swift`, add activation tracking:

```swift
    @State private var now = Date()
    @State private var activationDate = Date()
```

Add an elapsed-seconds helper:

```swift
    private var elapsedSeconds: Int {
        max(0, Int(now.timeIntervalSince(activationDate)))
    }
```

Update `overlayText`:

```swift
    private var overlayText: String? {
        switch settings.overlayContentMode {
        case .blank:
            return nil
        case .time:
            return formattedTime
        case .statusText:
            return "黑码码已开启"
        case .customText:
            return settings.sanitizedCustomText
        case .particleTimer:
            return ElapsedTimerFormatter.string(elapsedSeconds: elapsedSeconds)
        }
    }
```

- [ ] **Step 6: Run core checks and product build**

Run:

```bash
swift run VibeBlankCoreChecks
swift build --product VibeBlank
```

Expected: both commands pass.

- [ ] **Step 7: Commit**

```bash
git add Sources/VibeBlankCore/AppSettings.swift Sources/VibeBlankCore/ElapsedTimerFormatter.swift Sources/VibeBlank/OverlayContentView.swift Checks/VibeBlankCoreChecks/main.swift
git commit -m "feat: add V4 visual overlay settings"
```

---

### Task 2: Settings UI For V4 Visual Controls

**Files:**
- Modify: `Sources/VibeBlank/AppCopy.swift`
- Modify: `Sources/VibeBlank/SettingsView.swift`

**Interfaces:**
- Consumes: `OverlayBackgroundStyle.allCases`, `TimerPlacement.allCases`, `OverlayContentMode.particleTimer`
- Produces: settings controls for `settings.overlayBackgroundStyle` and `settings.timerPlacement`.

- [ ] **Step 1: Build before edits to confirm the starting point**

Run:

```bash
swift build --product VibeBlank
```

Expected: PASS.

- [ ] **Step 2: Add V4 settings copy**

In `Sources/VibeBlank/AppCopy.swift`, inside `enum Settings`, add:

```swift
        static let backgroundStylePicker = "背景样式"
        static let backgroundStylePickerDetail = "纯黑最安静，毛玻璃让遮罩更有空间感。"
        static let timerPlacementPicker = "计时器位置"
        static let timerPlacementPickerDetail = "粒子计时显示在角落，默认右下角。"
```

Update the existing content picker detail:

```swift
        static let contentPickerDetail = "纯黑最安静，也可以显示时间、状态文字或粒子计时。"
```

- [ ] **Step 3: Add animations for V4 settings**

In `Sources/VibeBlank/SettingsView.swift`, add these animation lines in the root view modifier chain:

```swift
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.overlayBackgroundStyle)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.timerPlacement)
```

- [ ] **Step 4: Add the background style picker**

In `overlayContent`, insert this row after the coverage-range row and before the display-content row:

```swift
            SettingsRow(
                symbolName: "camera.filters",
                title: AppCopy.Settings.backgroundStylePicker,
                detail: AppCopy.Settings.backgroundStylePickerDetail
            ) {
                Picker(AppCopy.Settings.backgroundStylePicker, selection: $viewModel.settings.overlayBackgroundStyle) {
                    ForEach(OverlayBackgroundStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .labelsHidden()
                .frame(width: 178)
            }
```

- [ ] **Step 5: Add the conditional timer placement picker**

In `overlayContent`, insert this row after the display-content row and before the custom-text row:

```swift
            if viewModel.settings.overlayContentMode == .particleTimer {
                SettingsRow(
                    symbolName: "arrow.up.left.and.arrow.down.right",
                    title: AppCopy.Settings.timerPlacementPicker,
                    detail: AppCopy.Settings.timerPlacementPickerDetail
                ) {
                    Picker(AppCopy.Settings.timerPlacementPicker, selection: $viewModel.settings.timerPlacement) {
                        ForEach(TimerPlacement.allCases) { placement in
                            Text(placement.displayName).tag(placement)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
                .transition(.opacity)
            }
```

- [ ] **Step 6: Run product build**

Run:

```bash
swift build --product VibeBlank
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Sources/VibeBlank/AppCopy.swift Sources/VibeBlank/SettingsView.swift
git commit -m "feat: add V4 visual controls"
```

---

### Task 3: Overlay Background Styles

**Files:**
- Create: `Sources/VibeBlank/OverlayBackgroundView.swift`
- Modify: `Sources/VibeBlank/OverlayContentView.swift`

**Interfaces:**
- Consumes: `OverlayBackgroundStyle`, `OverlayTransitionModel.coverage`, `OverlayTransitionModel.phase`
- Produces: `OverlayBackgroundView(style:transition:)`.

- [ ] **Step 1: Run product build before extracting the background**

Run:

```bash
swift build --product VibeBlank
```

Expected: PASS.

- [ ] **Step 2: Create overlay background renderer**

Create `Sources/VibeBlank/OverlayBackgroundView.swift`:

```swift
import SwiftUI
import VibeBlankCore

struct OverlayBackgroundView: View {
    let style: OverlayBackgroundStyle
    @ObservedObject var transition: OverlayTransitionModel

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            backgroundLayer
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            EdgeCollapseShape(progress: min(1, transition.coverage + 0.045))
                .fill(edgeShadowColor, style: FillStyle(eoFill: true))
                .ignoresSafeArea()

            EdgeCollapseShape(progress: transition.coverage)
                .fill(primaryFillColor, style: FillStyle(eoFill: true))
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch style {
        case .pureBlack:
            Color.black
        case .whiteGlass:
            ZStack {
                NativeGlassSurface(material: .hudWindow, blendingMode: .behindWindow)
                Color.white.opacity(0.64)
                Color.black.opacity(0.10)
            }
        case .blackGlass:
            ZStack {
                NativeGlassSurface(material: .fullScreenUI, blendingMode: .behindWindow)
                Color.black.opacity(0.82)
                Color.white.opacity(0.035)
            }
        }
    }

    private var backgroundOpacity: Double {
        transition.phase == .visible ? 1 : Double(transition.coverage)
    }

    private var edgeShadowColor: Color {
        switch style {
        case .pureBlack:
            return Color.black.opacity(0.34)
        case .whiteGlass:
            return Color.white.opacity(0.30)
        case .blackGlass:
            return Color.black.opacity(0.42)
        }
    }

    private var primaryFillColor: Color {
        switch style {
        case .pureBlack:
            return .black
        case .whiteGlass:
            return Color.white.opacity(0.78)
        case .blackGlass:
            return Color.black.opacity(0.88)
        }
    }
}

private struct EdgeCollapseShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(1, max(0, progress))
        var path = Path()
        path.addRect(rect)

        guard clampedProgress < 0.995 else {
            return path
        }

        let hole = rect.insetBy(
            dx: rect.width * clampedProgress / 2,
            dy: rect.height * clampedProgress / 2
        )

        guard hole.width > 0, hole.height > 0 else {
            return path
        }

        path.addRoundedRect(
            in: hole,
            cornerSize: CGSize(
                width: min(rect.width, rect.height) * 0.04 * (1 - clampedProgress),
                height: min(rect.width, rect.height) * 0.04 * (1 - clampedProgress)
            )
        )
        return path
    }
}
```

- [ ] **Step 3: Delegate background rendering from overlay content**

In `Sources/VibeBlank/OverlayContentView.swift`, replace the three existing background shape layers in `body` with:

```swift
            OverlayBackgroundView(style: settings.overlayBackgroundStyle, transition: transition)
```

Remove the private `EdgeCollapseShape` type from `OverlayContentView.swift`; it now lives inside `OverlayBackgroundView.swift`.

- [ ] **Step 4: Run product build**

Run:

```bash
swift build --product VibeBlank
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/VibeBlank/OverlayBackgroundView.swift Sources/VibeBlank/OverlayContentView.swift
git commit -m "feat: add V4 overlay background styles"
```

---

### Task 4: Particle Timer Rendering And Corner Placement

**Files:**
- Create: `Sources/VibeBlank/ParticleTimerView.swift`
- Modify: `Sources/VibeBlank/OverlayContentView.swift`

**Interfaces:**
- Consumes: `ElapsedTimerFormatter.string(elapsedSeconds:)`, `TimerPlacement`, `OverlayBackgroundStyle`
- Produces: `ParticleTimerView(text:placement:backgroundStyle:)`.

- [ ] **Step 1: Run product build before adding particle rendering**

Run:

```bash
swift build --product VibeBlank
```

Expected: PASS.

- [ ] **Step 2: Create particle timer view**

Create `Sources/VibeBlank/ParticleTimerView.swift`:

```swift
import SwiftUI
import VibeBlankCore

struct ParticleTimerView: View {
    let text: String
    let placement: TimerPlacement
    let backgroundStyle: OverlayBackgroundStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack {
            if placement.isBottom {
                Spacer(minLength: 0)
            }

            HStack {
                if placement.isRight {
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                        ParticleGlyph(
                            character: character,
                            color: particleColor,
                            inactiveColor: inactiveParticleColor,
                            pulseAmount: reduceMotion ? 0 : (pulse ? 1 : 0)
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(containerFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(containerStroke, lineWidth: 0.8)
                }
                .shadow(color: shadowColor, radius: 18, x: 0, y: 8)
                .accessibilityLabel(Text("黑屏计时 \(text)"))

                if placement.isLeft {
                    Spacer(minLength: 0)
                }
            }

            if placement.isTop {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 38)
        .opacity(0.92)
        .onAppear {
            guard !reduceMotion else {
                return
            }

            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var particleColor: Color {
        switch backgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.76)
        case .pureBlack, .blackGlass:
            return Color.white.opacity(0.82)
        }
    }

    private var inactiveParticleColor: Color {
        switch backgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.10)
        case .pureBlack, .blackGlass:
            return Color.white.opacity(0.13)
        }
    }

    private var containerFill: Color {
        switch backgroundStyle {
        case .whiteGlass:
            return Color.white.opacity(0.28)
        case .pureBlack:
            return Color.white.opacity(0.055)
        case .blackGlass:
            return Color.white.opacity(0.075)
        }
    }

    private var containerStroke: Color {
        switch backgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.12)
        case .pureBlack, .blackGlass:
            return Color.white.opacity(0.14)
        }
    }

    private var shadowColor: Color {
        switch backgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.12)
        case .pureBlack, .blackGlass:
            return Color.black.opacity(0.30)
        }
    }
}

private struct ParticleGlyph: View {
    let character: Character
    let color: Color
    let inactiveColor: Color
    let pulseAmount: Double

    private let dotSize: CGFloat = 5.5
    private let dotSpacing: CGFloat = 3.3

    var body: some View {
        let pattern = ParticleGlyphPattern.pattern(for: character)

        VStack(spacing: dotSpacing) {
            ForEach(0..<pattern.rows.count, id: \.self) { row in
                HStack(spacing: dotSpacing) {
                    ForEach(0..<pattern.width, id: \.self) { column in
                        Circle()
                            .fill(pattern.rows[row][column] ? color : inactiveColor)
                            .frame(width: dotSize, height: dotSize)
                            .opacity(opacity(row: row, column: column, isActive: pattern.rows[row][column]))
                    }
                }
            }
        }
        .frame(width: CGFloat(pattern.width) * dotSize + CGFloat(max(0, pattern.width - 1)) * dotSpacing)
    }

    private func opacity(row: Int, column: Int, isActive: Bool) -> Double {
        guard isActive else {
            return 1
        }

        let stagger = Double((row + column) % 4) * 0.035
        return 0.82 + min(0.18, pulseAmount * (0.12 + stagger))
    }
}

private struct ParticleGlyphPattern {
    let width: Int
    let rows: [[Bool]]

    static func pattern(for character: Character) -> ParticleGlyphPattern {
        let rawRows = rawPattern(for: character)
        return ParticleGlyphPattern(
            width: rawRows.first?.count ?? 0,
            rows: rawRows.map { row in row.map { $0 == "1" } }
        )
    }

    private static func rawPattern(for character: Character) -> [String] {
        switch character {
        case "0":
            return ["11111", "10001", "10011", "10101", "11001", "10001", "11111"]
        case "1":
            return ["00100", "01100", "00100", "00100", "00100", "00100", "01110"]
        case "2":
            return ["11111", "00001", "00001", "11111", "10000", "10000", "11111"]
        case "3":
            return ["11111", "00001", "00001", "01111", "00001", "00001", "11111"]
        case "4":
            return ["10001", "10001", "10001", "11111", "00001", "00001", "00001"]
        case "5":
            return ["11111", "10000", "10000", "11111", "00001", "00001", "11111"]
        case "6":
            return ["11111", "10000", "10000", "11111", "10001", "10001", "11111"]
        case "7":
            return ["11111", "00001", "00010", "00100", "01000", "01000", "01000"]
        case "8":
            return ["11111", "10001", "10001", "11111", "10001", "10001", "11111"]
        case "9":
            return ["11111", "10001", "10001", "11111", "00001", "00001", "11111"]
        case ":":
            return ["0", "1", "1", "0", "1", "1", "0"]
        default:
            return ["000", "000", "000", "000", "000", "000", "000"]
        }
    }
}

private extension TimerPlacement {
    var isTop: Bool {
        self == .topLeft || self == .topRight
    }

    var isBottom: Bool {
        self == .bottomLeft || self == .bottomRight
    }

    var isLeft: Bool {
        self == .topLeft || self == .bottomLeft
    }

    var isRight: Bool {
        self == .topRight || self == .bottomRight
    }
}
```

- [ ] **Step 3: Render particle timer separately from centered text modes**

In `Sources/VibeBlank/OverlayContentView.swift`, add a content rendering helper:

```swift
    @ViewBuilder
    private var overlayContent: some View {
        switch settings.overlayContentMode {
        case .particleTimer:
            ParticleTimerView(
                text: ElapsedTimerFormatter.string(elapsedSeconds: elapsedSeconds),
                placement: settings.timerPlacement,
                backgroundStyle: settings.overlayBackgroundStyle
            )
            .opacity(transition.phase == .visible ? 1 : 0)
        case .blank, .time, .statusText, .customText:
            if let text = overlayText {
                Text(text)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(centeredTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(48)
                    .opacity(transition.phase == .visible ? 1 : 0)
            }
        }
    }
```

Replace the existing `if let text = overlayText { ... }` block in `body` with:

```swift
            overlayContent
```

Update `overlayText` so `.particleTimer` is not treated as centered fallback text:

```swift
    private var overlayText: String? {
        switch settings.overlayContentMode {
        case .blank, .particleTimer:
            return nil
        case .time:
            return formattedTime
        case .statusText:
            return "黑码码已开启"
        case .customText:
            return settings.sanitizedCustomText
        }
    }
```

Add centered text color:

```swift
    private var centeredTextColor: Color {
        switch settings.overlayBackgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.68)
        case .pureBlack, .blackGlass:
            return Color.white.opacity(0.72)
        }
    }
```

- [ ] **Step 4: Run product build**

Run:

```bash
swift build --product VibeBlank
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/VibeBlank/ParticleTimerView.swift Sources/VibeBlank/OverlayContentView.swift
git commit -m "feat: render V4 particle timer"
```

---

### Task 5: README And Final Verification

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: completed V4 app behavior.
- Produces: README feature descriptions that match V4.

- [ ] **Step 1: Update README feature table**

In `README.md`, update the display row in the core feature table:

```markdown
| 自定义显示 | 支持纯黑、时间、状态文字、自定义文字和粒子计时 |
| 毛玻璃遮罩 | 支持纯黑、白色毛玻璃和黑色强毛玻璃背景 |
```

Add a usage note after the custom display instruction:

```markdown
7. 如需更强视觉质感，在设置里选择「白色毛玻璃」或「黑色强毛玻璃」。
8. 如需查看离开时长，在「显示内容」里选择「粒子计时」，并选择计时器角落。
```

Renumber the following exit instruction if needed so the list stays sequential.

- [ ] **Step 2: Update non-goal wording**

In `README.md`, keep the existing AI-status boundary and make it match V4:

```markdown
| 不监听 agent 状态 | 飞书通知、任务完成提醒和真实 AI 状态读取属于后续方向 |
```

- [ ] **Step 3: Run final verification commands**

Run:

```bash
swift run VibeBlankCoreChecks
swift build --product VibeBlank
bash scripts/package_app.sh
```

Expected:

- `swift run VibeBlankCoreChecks` prints `All VibeBlank core checks passed.`
- `swift build --product VibeBlank` exits 0.
- `bash scripts/package_app.sh` creates `dist/VibeBlank.app`, `dist/VibeBlank.zip`, and `dist/VibeBlank.dmg`.

- [ ] **Step 4: Manual packaged-app visual acceptance**

Run the packaged app:

```bash
open dist/VibeBlank.app
```

Verify these cases:

- Existing pure black blank overlay still activates and exits with Esc.
- `粒子计时` starts at `00:00` and increments once per second.
- `左上角`, `右上角`, `左下角`, and `右下角` place the particle timer in the chosen corner.
- `白色毛玻璃` obscures screen content while staying bright.
- `黑色强毛玻璃` obscures screen content while staying dark.
- Esc exits from every background style.

On a multi-display setup, capture displays separately:

```bash
screencapture -D 1 /tmp/vibeblank-v4-display-1.png
screencapture -D 2 /tmp/vibeblank-v4-display-2.png
```

Expected:

- Each targeted display shows the configured V4 overlay.
- Untargeted displays remain visible when the scope is `仅外接显示器`.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: document VibeBlank V4 visuals"
```

---

## Plan Self-Review

- Spec coverage: Task 1 covers persisted V4 settings and elapsed timer formatting. Task 2 covers settings UI. Task 3 covers pure black, white glass, and black heavy-glass backgrounds. Task 4 covers particle numerals and corner placement. Task 5 covers README and verification.
- Scope check: The plan does not add countdowns, drag placement, screen recording, AI task-status connections, or trigger-system changes.
- Verification coverage: Core settings and formatter use `VibeBlankCoreChecks`; app integration uses `swift build --product VibeBlank`; packaged acceptance uses `bash scripts/package_app.sh` plus manual overlay checks.
- Type consistency: The same names are used throughout: `OverlayBackgroundStyle`, `TimerPlacement`, `overlayBackgroundStyle`, `timerPlacement`, `ElapsedTimerFormatter.string(elapsedSeconds:)`, and `OverlayContentMode.particleTimer`.
