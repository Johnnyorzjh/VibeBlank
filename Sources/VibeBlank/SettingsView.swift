import SwiftUI
import VibeBlankCore

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            Form {
                Section(AppCopy.Settings.overlaySection) {
                    Picker(AppCopy.Settings.coverPicker, selection: $viewModel.settings.overlayScope) {
                        ForEach(OverlayScope.allCases) { scope in
                            Text(scope.displayName).tag(scope)
                        }
                    }

                    Picker(AppCopy.Settings.contentPicker, selection: $viewModel.settings.overlayContentMode) {
                        ForEach(OverlayContentMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    if viewModel.settings.overlayContentMode == .customText {
                        TextField(AppCopy.Settings.customTextPlaceholder, text: $viewModel.settings.customText)
                    }
                }

                Section(AppCopy.Settings.exitSection) {
                    Toggle(AppCopy.Settings.clickToExit, isOn: $viewModel.settings.clickToExitEnabled)
                    Toggle(AppCopy.Settings.keyToExit, isOn: $viewModel.settings.keyToExitEnabled)
                    Text(AppCopy.Settings.escapeHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(AppCopy.Settings.triggersSection) {
                    Toggle(AppCopy.Settings.enableHotkey, isOn: $viewModel.settings.globalHotkeyEnabled)
                    Text(AppCopy.Settings.triggersHint)
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
            Text(AppCopy.Settings.headline)
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            Text(AppCopy.Settings.subtitle)
                .foregroundStyle(.secondary)

            Text(AppCopy.Settings.safetyNotice)
                .font(.callout)
                .foregroundStyle(.orange)
        }
    }

    private var footer: some View {
        HStack {
            Button(AppCopy.Settings.restoreDefaults) {
                viewModel.resetToDefaults()
            }

            Spacer()

            Text(AppCopy.Settings.defaultsHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
