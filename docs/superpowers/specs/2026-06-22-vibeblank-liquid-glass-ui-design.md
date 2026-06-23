# VibeBlank Liquid Glass UI Design

## Goal

Unify VibeBlank's user-facing UI around an Apple-style Liquid Glass system while preserving the product's privacy-first behavior. Glass is used for navigation, menus, controls, onboarding, and overlay HUD elements; the screen-covering layer must never reveal sensitive desktop content.

## Design

- Add shared UI primitives in the app target: `LiquidGlassPalette`, `LiquidGlassProminence`, `LiquidGlassInterfaceLayout`, `liquidGlassSurface`, `liquidGlassControl`, `glassHoverExpansion`, edge glow, and hover shimmer.
- Keep the implementation native and dependency-free by using the existing `NSVisualEffectView` bridge through `NativeGlassSurface`.
- Keep macOS 13+ compatibility. Newer Liquid Glass APIs are not required for this release.
- Make settings responsive at fixed breakpoints:
  - `>= 760pt`: full left sidebar.
  - `620-759pt`: compact icon rail that expands on hover.
  - `< 620pt`: top capsule navigation with single-column settings rows.
- Apply the same glass system to the menu-bar panel, onboarding window, settings shell, and overlay HUD.
- Use lighter tint and stronger native material opacity so surfaces read as transparent/refractive glass instead of opaque cards.
- Add a short hover light sweep to navigation, menu rows, onboarding surfaces, and other interactive glass controls. It is an enhancement only; all actions remain directly clickable without hover.
- Treat onboarding as versioned product education. Legacy installs that only have the old boolean onboarding flag should see the current onboarding once, then persist the current onboarding version after completion.
- Support accessibility preferences:
  - Reduce Motion disables hover/selection animation intensity.
  - Reduce Transparency increases opaque surface fill.
  - Increased Contrast strengthens borders and separation.

## Surface Rules

- Settings: navigation and cards float above the material background; rows remain readable and do not depend on hover to expose actions.
- Menu panel: sections and action rows use light glass, edge highlights, and hover feedback while preserving direct click targets.
- Onboarding: content scrolls when narrow, while the action footer stays pinned at the bottom.
- Onboarding completion: store the current onboarding version separately from the legacy boolean so new first-run education can be shown after major visual/product updates.
- Overlay: black/glass cover behavior remains privacy-safe; only timer and status HUD elements use the shared glass treatment.

## Acceptance

- `swift run VibeBlankCoreChecks` passes.
- `swift build --product VibeBlank` passes.
- `bash scripts/package_app.sh` creates `.app`, `.zip`, and `.dmg`.
- Existing users with only the legacy onboarding boolean see the current onboarding; users who finish the current onboarding version do not see it again.
- Hovering glass navigation/menu/onboarding controls produces a brief light sweep unless Reduce Motion or Reduce Transparency asks for a calmer UI.
- Settings can be resized through all three breakpoints without clipped primary controls.
- Menu-bar panel, onboarding, and overlay HUD use the shared glass primitives.
- Existing trigger and exit behavior remains unchanged.
