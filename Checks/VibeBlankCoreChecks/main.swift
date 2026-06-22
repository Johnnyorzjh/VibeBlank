import CoreGraphics
import Foundation
import VibeBlankCore

private struct CheckFailure: Error, CustomStringConvertible {
    let message: String

    var description: String {
        message
    }
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckFailure(message: message)
    }
}

private func makeStore() -> (suiteName: String, defaults: UserDefaults, store: SettingsStore) {
    let suiteName = "VibeBlankChecks-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (suiteName, defaults, SettingsStore(defaults: defaults))
}

private func checkDefaultSettingsMatchPRD() throws {
    let context = makeStore()
    defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

    try expect(context.store.load() == AppSettings.defaults, "missing settings should load defaults")
    try expect(context.store.load().overlayScope == .externalDisplays, "default scope should cover external displays")
    try expect(context.store.load().overlayContentMode == .blank, "default overlay content should be blank")
    try expect(context.store.load().clickToExitEnabled == false, "click-to-exit should be off by default")
    try expect(context.store.load().keyToExitEnabled == false, "key-to-exit should be off by default")
    try expect(context.store.load().launchAtLoginEnabled == true, "launch at login should be on by default")
    try expect(context.store.load().cornerTrigger.isEnabled == false, "hot corner should be off by default")
    try expect(context.store.load().cornerTrigger.corner == .topRight, "default hot corner should be top right")
    try expect(
        context.store.load().modifierTapTrigger == .defaults,
        "Command triple-tap should be the default keyboard trigger"
    )
    try expect(context.store.load().comboHotKeyTrigger.isEnabled == false, "combo hotkey should be off by default")
    try expect(
        context.store.load().comboHotKeyTrigger.displayName == "Control + Option + Command + B",
        "legacy combo should remain the default candidate"
    )
}

private func checkSaveAndReloadSettings() throws {
    let context = makeStore()
    defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

    let settings = AppSettings(
        overlayScope: .allDisplays,
        overlayContentMode: .customText,
        customText: "Back in 5",
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

    try expect(context.store.load() == settings, "saved settings should reload exactly")
}

private func checkCorruptSettingsFallBackToDefaults() throws {
    let context = makeStore()
    defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

    context.defaults.set(Data("not-json".utf8), forKey: "settings")

    try expect(context.store.load() == AppSettings.defaults, "corrupt settings should fall back to defaults")
}

private func checkV2SettingsUpgradeToV3Defaults() throws {
    let context = makeStore()
    defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

    let v2JSON = """
    {
      "overlayScope": "allDisplays",
      "overlayContentMode": "customText",
      "customText": "Focus",
      "clickToExitEnabled": true,
      "keyToExitEnabled": true,
      "globalHotkeyEnabled": true
    }
    """
    context.defaults.set(Data(v2JSON.utf8), forKey: "settings")

    let settings = context.store.load()
    try expect(settings.overlayScope == .allDisplays, "V2 scope should migrate")
    try expect(settings.overlayContentMode == .customText, "V2 content mode should migrate")
    try expect(settings.customText == "Focus", "V2 custom text should migrate")
    try expect(settings.clickToExitEnabled == true, "V2 click-to-exit should migrate")
    try expect(settings.keyToExitEnabled == true, "V2 key-to-exit should migrate")
    try expect(settings.launchAtLoginEnabled == true, "V3 launch at login should default on for upgrades")
    try expect(settings.modifierTapTrigger.isEnabled == true, "V3 Command triple-tap should default on for upgrades")
    try expect(settings.comboHotKeyTrigger.isEnabled == false, "legacy combo should default off for upgrades")
    try expect(settings.cornerTrigger.isEnabled == false, "hot corner should default off for upgrades")
}

private func checkHotCornerDirectEntryDoesNotTrigger() throws {
    var evaluator = HotCornerPushEvaluator()
    let screens = [
        ScreenFrameSnapshot(id: 1, frame: CGRect(x: 0, y: 0, width: 1_000, height: 800))
    ]

    let triggered = evaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10)
    )

    try expect(triggered == false, "direct entry into activation zone should not trigger")
}

private func checkHotCornerInteriorPushTriggersOnce() throws {
    var evaluator = HotCornerPushEvaluator()
    let screens = [
        ScreenFrameSnapshot(id: 1, frame: CGRect(x: 0, y: 0, width: 1_000, height: 800))
    ]

    let approach = evaluator.update(
        mouseLocation: CGPoint(x: 940, y: 740),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10)
    )
    let activation = evaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10.1)
    )
    let repeated = evaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10.2)
    )

    try expect(approach == false, "approach zone should only arm the hot corner")
    try expect(activation == true, "interior push into activation zone should trigger")
    try expect(repeated == false, "remaining in activation zone should not repeat trigger")
}

private func checkHotCornerEdgeSlidesDoNotTrigger() throws {
    let screens = [
        ScreenFrameSnapshot(id: 1, frame: CGRect(x: 0, y: 0, width: 1_000, height: 800))
    ]

    var topEdgeEvaluator = HotCornerPushEvaluator()
    _ = topEdgeEvaluator.update(
        mouseLocation: CGPoint(x: 940, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10)
    )
    let topEdgeTriggered = topEdgeEvaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10.1)
    )

    var rightEdgeEvaluator = HotCornerPushEvaluator()
    _ = rightEdgeEvaluator.update(
        mouseLocation: CGPoint(x: 998, y: 740),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10)
    )
    let rightEdgeTriggered = rightEdgeEvaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10.1)
    )

    try expect(topEdgeTriggered == false, "sliding along the top edge should not arm or trigger")
    try expect(rightEdgeTriggered == false, "sliding along the right edge should not arm or trigger")
}

private func checkHotCornerScreenSeamDoesNotTrigger() throws {
    var evaluator = HotCornerPushEvaluator()
    let screens = [
        ScreenFrameSnapshot(id: 1, frame: CGRect(x: 0, y: 0, width: 1_470, height: 956)),
        ScreenFrameSnapshot(id: 2, frame: CGRect(x: -538, y: 956, width: 2_560, height: 1_440))
    ]

    _ = evaluator.update(
        mouseLocation: CGPoint(x: 1_410, y: 900),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10)
    )
    let seamTriggered = evaluator.update(
        mouseLocation: CGPoint(x: 1_468, y: 954),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10.1)
    )

    _ = evaluator.update(
        mouseLocation: CGPoint(x: 1_960, y: 2_340),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 12.3)
    )
    let exposedCornerTriggered = evaluator.update(
        mouseLocation: CGPoint(x: 2_020, y: 2_394),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 12.4)
    )

    try expect(seamTriggered == false, "shared screen seam corner should not trigger")
    try expect(exposedCornerTriggered == true, "exposed external display corner should still trigger")
}

private func checkHotCornerCooldownRequiresLeavingActivationZone() throws {
    var evaluator = HotCornerPushEvaluator()
    let screens = [
        ScreenFrameSnapshot(id: 1, frame: CGRect(x: 0, y: 0, width: 1_000, height: 800))
    ]

    _ = evaluator.update(
        mouseLocation: CGPoint(x: 940, y: 740),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10)
    )
    let firstTrigger = evaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10.1)
    )
    _ = evaluator.update(
        mouseLocation: CGPoint(x: 940, y: 740),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 10.2)
    )
    let blockedByCooldown = evaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 11)
    )
    _ = evaluator.update(
        mouseLocation: CGPoint(x: 940, y: 740),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 12.2)
    )
    let secondTrigger = evaluator.update(
        mouseLocation: CGPoint(x: 998, y: 798),
        screens: screens,
        corner: .topRight,
        timestamp: Date(timeIntervalSinceReferenceDate: 12.3)
    )

    try expect(firstTrigger == true, "first push should trigger")
    try expect(blockedByCooldown == false, "second push inside cooldown should not trigger")
    try expect(secondTrigger == true, "push after leaving activation zone and cooldown should trigger")
}

private func checkFirstLaunchFlagPersists() throws {
    let context = makeStore()
    defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

    try expect(context.store.hasCompletedFirstLaunch == false, "first launch flag should default to false")
    context.store.markFirstLaunchCompleted()
    try expect(context.store.hasCompletedFirstLaunch == true, "first launch flag should persist true")
}

let checks: [(String, () throws -> Void)] = [
    ("default settings match PRD", checkDefaultSettingsMatchPRD),
    ("settings save and reload", checkSaveAndReloadSettings),
    ("corrupt settings fallback", checkCorruptSettingsFallBackToDefaults),
    ("V2 settings upgrade to V3 defaults", checkV2SettingsUpgradeToV3Defaults),
    ("hot corner direct entry does not trigger", checkHotCornerDirectEntryDoesNotTrigger),
    ("hot corner interior push triggers once", checkHotCornerInteriorPushTriggersOnce),
    ("hot corner edge slides do not trigger", checkHotCornerEdgeSlidesDoNotTrigger),
    ("hot corner screen seam does not trigger", checkHotCornerScreenSeamDoesNotTrigger),
    ("hot corner cooldown requires leaving activation zone", checkHotCornerCooldownRequiresLeavingActivationZone),
    ("first launch flag persists", checkFirstLaunchFlagPersists)
]

do {
    for (name, check) in checks {
        try check()
        print("PASS: \(name)")
    }
    print("All VibeBlank core checks passed.")
} catch {
    fputs("FAIL: \(error)\n", stderr)
    exit(1)
}
