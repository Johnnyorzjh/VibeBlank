import SwiftUI
import VibeBlankCore

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            Form {
                Section("Overlay") {
                    Picker("Cover", selection: $viewModel.settings.overlayScope) {
                        ForEach(OverlayScope.allCases) { scope in
                            Text(scope.displayName).tag(scope)
                        }
                    }

                    Picker("Content", selection: $viewModel.settings.overlayContentMode) {
                        ForEach(OverlayContentMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    if viewModel.settings.overlayContentMode == .customText {
                        TextField("Custom text", text: $viewModel.settings.customText)
                    }
                }

                Section("Exit Behavior") {
                    Toggle("Click overlay to exit", isOn: $viewModel.settings.clickToExitEnabled)
                    Toggle("Press any key to exit", isOn: $viewModel.settings.keyToExitEnabled)
                    Text("Escape always exits black screen mode as a safety fallback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Triggers") {
                    Toggle("Enable Control-Option-Command-B hotkey", isOn: $viewModel.settings.globalHotkeyEnabled)
                    Text("Menu bar activation always works without sensitive permissions. Trigger corners are planned for a later version.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            footer
        }
        .padding(24)
        .frame(width: 520, height: 520)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VibeBlank")
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            Text("Cover your displays while agents, builds, terminals, and local services keep running.")
                .foregroundStyle(.secondary)

            Text("VibeBlank is a visual privacy helper, not a lock screen or authentication tool.")
                .font(.callout)
                .foregroundStyle(.orange)
        }
    }

    private var footer: some View {
        HStack {
            Button("Restore Defaults") {
                viewModel.resetToDefaults()
            }

            Spacer()

            Text("Default: external displays only, blank overlay.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
