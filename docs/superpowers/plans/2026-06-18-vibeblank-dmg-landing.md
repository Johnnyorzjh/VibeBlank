# VibeBlank DMG Landing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the V3 DMG window from a blank Finder folder into a polished illustrated install landing page using the approved high-resolution background artwork.

**Architecture:** Package the approved `assets/dmg-background.png` into `.background/` after resizing it for the Finder window. Build a read-write DMG first, use Finder AppleScript to save icon-view layout into `.DS_Store`, then convert the result to compressed UDZO for distribution.

**Tech Stack:** Bash, SwiftPM, `hdiutil`, `sips`, Finder AppleScript.

## Global Constraints

- Product display name remains `黑码码`.
- Technical executable/package name remains `VibeBlank`.
- App bundle version remains `0.3.0`.
- DMG contents include `黑码码.app` and an `Applications` symlink.
- Distribution remains unsigned/not notarized local DMG packaging.

---

### Task 1: Use Approved High-Resolution DMG Background

**Files:**
- Use: `assets/dmg-background.png`

**Interfaces:**
- Consumes: approved `1586x992` PNG artwork.
- Produces: `assets/dmg-background.png`, used as the Finder background.

- [x] Copy the approved artwork to `assets/dmg-background.png`.
- [x] Confirm `sips -g pixelWidth -g pixelHeight assets/dmg-background.png` reports `1586` by `992`.

### Task 2: Add Finder Layout Packaging

**Files:**
- Modify: `scripts/package_app.sh`

**Interfaces:**
- Consumes: `assets/dmg-background.png`.
- Produces: `dist/VibeBlank.dmg` with Finder icon view, large icons, hidden `.background`, and custom item positions.

- [x] Copy the approved background into `dist/dmg-staging/.background/dmg-background.png`.
- [x] Resize the background to the Finder window size before packaging.
- [x] Build a temporary read-write DMG.
- [x] Mount it, set Finder window bounds to `1180x738`, icon size to `164`, background picture, and item positions.
- [x] Detach and convert the read-write image into compressed `dist/VibeBlank.dmg`.

### Task 3: Package And Verify

**Files:**
- Update: `dist/VibeBlank.dmg`
- Update: `dist/VibeBlank.zip`

**Interfaces:**
- Consumes: updated package script.
- Produces: verified installer DMG in Downloads.

- [x] Run `swift run VibeBlankCoreChecks`.
- [x] Run `bash scripts/package_app.sh`.
- [x] Run `hdiutil verify dist/VibeBlank.dmg`.
- [x] Mount the DMG and verify `黑码码.app`, `Applications`, `.background/dmg-background.png`, and bundle version `0.3.0`.
- [x] Verify `dist/VibeBlank.zip` contains `VibeBlank.app/Contents/MacOS/VibeBlank`.
