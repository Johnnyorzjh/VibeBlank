import SwiftUI
import Carbon.HIToolbox
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
                    Toggle(AppCopy.Settings.launchAtLogin, isOn: $viewModel.settings.launchAtLoginEnabled)
                    Text(viewModel.loginItemStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle(AppCopy.Settings.hotCorner, isOn: $viewModel.settings.cornerTrigger.isEnabled)
                    if viewModel.settings.cornerTrigger.isEnabled {
                        Picker(AppCopy.Settings.hotCornerPicker, selection: $viewModel.settings.cornerTrigger.corner) {
                            ForEach(ScreenCorner.allCases) { corner in
                                Text(corner.displayName).tag(corner)
                            }
                        }
                    }

                    Toggle(AppCopy.Settings.enableModifierTap, isOn: $viewModel.settings.modifierTapTrigger.isEnabled)
                    if viewModel.settings.modifierTapTrigger.isEnabled {
                        Picker(AppCopy.Settings.commandSidePicker, selection: $viewModel.settings.modifierTapTrigger.commandSide) {
                            ForEach(CommandSide.allCases) { side in
                                Text(side.displayName).tag(side)
                            }
                        }

                        HStack {
                            Text(viewModel.keyboardPermissionStatus.displayName)
                                .font(.caption)
                                .foregroundStyle(
                                    viewModel.keyboardPermissionStatus == .needsAccessibilityPermission ? .orange : .secondary
                                )

                            Spacer()

                            if viewModel.keyboardPermissionStatus == .needsAccessibilityPermission {
                                Button(AppCopy.Settings.openAccessibilitySettings) {
                                    viewModel.openAccessibilitySettings()
                                }
                            }
                        }
                    }

                    Toggle(
                        AppCopy.Settings.enableComboHotkey,
                        isOn: Binding(
                            get: { viewModel.settings.comboHotKeyTrigger.isEnabled },
                            set: { viewModel.setComboHotKeyEnabled($0) }
                        )
                    )

                    if viewModel.settings.comboHotKeyTrigger.isEnabled {
                        HStack {
                            if viewModel.isRecordingComboHotKey {
                                HotKeyRecorderView { keyCode, modifiers, displayName in
                                    viewModel.saveComboHotKey(
                                        keyCode: keyCode,
                                        modifiers: modifiers,
                                        displayName: displayName
                                    )
                                }
                                .frame(height: 34)
                            } else {
                                Text(viewModel.settings.comboHotKeyTrigger.displayName)
                                    .font(.body.monospaced())
                            }

                            Spacer()

                            if viewModel.isRecordingComboHotKey {
                                Button(AppCopy.Settings.cancelRecording) {
                                    viewModel.cancelComboRecording()
                                }
                            } else {
                                Button(AppCopy.Settings.recordComboHotkey) {
                                    viewModel.isRecordingComboHotKey = true
                                }
                            }
                        }
                    }

                    if let comboHotKeyError = viewModel.comboHotKeyError {
                        Text(comboHotKeyError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text(viewModel.hotKeyConflictStatus.displayName)
                            .font(.caption)
                            .foregroundStyle(viewModel.hotKeyConflictStatus == .conflict ? .red : .secondary)
                    }

                    Text(AppCopy.Settings.triggersHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            footer
        }
        .padding(24)
        .frame(width: 560, height: 700)
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

private struct HotKeyRecorderView: NSViewRepresentable {
    let onCapture: (UInt32, UInt32, String) -> Void

    func makeNSView(context: Context) -> HotKeyRecorderNSView {
        let view = HotKeyRecorderNSView()
        view.onCapture = onCapture
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: HotKeyRecorderNSView, context: Context) {
        nsView.onCapture = onCapture
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class HotKeyRecorderNSView: NSView {
    var onCapture: ((UInt32, UInt32, String) -> Void)?
    private var monitor: Any?

    private let textField: NSTextField = {
        let field = NSTextField(labelWithString: "正在录制...")
        field.alignment = .center
        field.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        field.textColor = .secondaryLabelColor
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1
        addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installMonitorIfNeeded()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        capture(event)
    }

    private func installMonitorIfNeeded() {
        guard monitor == nil else {
            return
        }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window?.isKeyWindow == true else {
                return event
            }

            self.capture(event)
            return nil
        }
    }

    private func capture(_ event: NSEvent) {
        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else {
            NSSound.beep()
            return
        }

        let keyName = Self.keyName(from: event)
        let displayName = Self.displayName(modifiers: event.modifierFlags, keyName: keyName)
        textField.stringValue = displayName
        onCapture?(UInt32(event.keyCode), modifiers, displayName)
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        return modifiers
    }

    private static func keyName(from event: NSEvent) -> String {
        if let value = event.charactersIgnoringModifiers, !value.isEmpty {
            return value.uppercased()
        }
        return "Key \(event.keyCode)"
    }

    private static func displayName(modifiers flags: NSEvent.ModifierFlags, keyName: String) -> String {
        var parts: [String] = []
        if flags.contains(.control) {
            parts.append("Control")
        }
        if flags.contains(.option) {
            parts.append("Option")
        }
        if flags.contains(.shift) {
            parts.append("Shift")
        }
        if flags.contains(.command) {
            parts.append("Command")
        }
        parts.append(keyName)
        return parts.joined(separator: " + ")
    }
}
