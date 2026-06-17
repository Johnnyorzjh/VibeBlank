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
    try expect(context.store.load().globalHotkeyEnabled == true, "global hotkey should be enabled by default")
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
        globalHotkeyEnabled: false
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
