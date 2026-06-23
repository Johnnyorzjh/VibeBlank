# VibeBlank UI Stability Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use inline execution in this session. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix onboarding deformation and settings hierarchy issues while preserving the current Apple-style Liquid Glass direction.

**Architecture:** Keep the existing SwiftUI/AppKit structure. Add one internal glass edge mode to tune structural versus floating surfaces, then adjust onboarding and settings layout constraints around stable content widths.

**Tech Stack:** SwiftUI, AppKit, SwiftPM, macOS 13+.

## Global Constraints

- Do not change `VibeBlankCore.AppSettings` or onboarding version semantics.
- Keep all UI primitives internal to the app target.
- Validate with packaged app screenshots, not debug binary only.

---

### Task 1: Liquid Glass Edge And Hover Modes

**Files:**
- Modify: `Sources/VibeBlank/LiquidGlassUI.swift`

**Interfaces:**
- Produces: `LiquidGlassEdgeMode` with `structural`, `floating`, and `interactive`.
- Produces: optional `edgeMode` parameters on `liquidGlassSurface` and `brightGlass`.
- Updates: `glassHoverExpansion` defaults to no scale unless explicitly requested.

- [ ] Add `LiquidGlassEdgeMode`.
- [ ] Thread `edgeMode` through surface modifiers.
- [ ] Disable diagonal edge glow on structural surfaces.
- [ ] Keep Reduce Motion and Reduce Transparency behavior intact.

### Task 2: Onboarding Layout Stability

**Files:**
- Modify: `Sources/VibeBlank/OnboardingWindowController.swift`
- Modify: `Sources/VibeBlank/OnboardingView.swift`

**Interfaces:**
- Consumes: existing `OnboardingView` inputs and `start` callbacks unchanged.
- Produces: regular layout with bounded text column, image, and footer widths.

- [ ] Set onboarding window initial size to `1120x680` and min size to `560x600`.
- [ ] Cap regular content width and image size.
- [ ] Make compact layout single column with bounded image height.
- [ ] Replace full-width heavy footer with content-width lightweight footer.
- [ ] Remove prominent scale from image/footer hover.

### Task 3: Settings Hierarchy And Width

**Files:**
- Modify: `Sources/VibeBlank/SettingsView.swift`

**Interfaces:**
- Consumes: existing `SettingsViewModel` and settings bindings unchanged.
- Produces: centered max-width content column and structural sidebar/footer glass.

- [ ] Add a content column width cap of `960pt`.
- [ ] Separate title and status summary into stable header rows.
- [ ] Reduce header/card spacing collisions.
- [ ] Make sidebar/footer structural glass to remove corner arc artifacts.
- [ ] Normalize type sizes for header, section intro, rows, and detail text.

### Task 4: Verification And Visual Evidence

**Files:**
- Create generated artifacts under `dist/visual-checks/`.

- [ ] Run `git diff --check`.
- [ ] Run `swift run VibeBlankCoreChecks`.
- [ ] Run `swift build --product VibeBlank`.
- [ ] Run `bash scripts/package_app.sh`.
- [ ] Run `codesign --verify --deep --strict dist/VibeBlank.app`.
- [ ] Run `hdiutil verify dist/VibeBlank.dmg`.
- [ ] Capture packaged-app screenshots for onboarding regular/compact and settings regular/rail/compact.
