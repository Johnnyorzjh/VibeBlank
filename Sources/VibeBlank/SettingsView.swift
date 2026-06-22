import AppKit
import SwiftUI
import Carbon.HIToolbox
import VibeBlankCore

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage: SettingsPage = .overlay

    var body: some View {
        ZStack {
            SettingsBackground()

            HStack(spacing: 16) {
                sidebar

                VStack(spacing: 14) {
                    header

                    ScrollView {
                        pageContent
                            .padding(.bottom, 18)
                    }
                    .scrollIndicators(.hidden)

                    footer
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)
        }
        .frame(width: 940, height: 720)
        .tint(GlassPalette.accent)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selectedPage)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.overlayBackgroundStyle)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.overlayContentMode)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.timerPlacement)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.cornerTrigger.isEnabled)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.modifierTapTrigger.isEnabled)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: viewModel.settings.comboHotKeyTrigger.isEnabled)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GlassPalette.accent)
                    .frame(width: 36, height: 36)
                    .glassControl(cornerRadius: 12, isActive: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppCopy.appName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(GlassPalette.primaryText)

                    Text("视觉隐私保护")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .accessibilityElement(children: .combine)

            VStack(spacing: 8) {
                ForEach(SettingsPage.allCases) { page in
                    SidebarItem(
                        page: page,
                        isSelected: selectedPage == page
                    ) {
                        selectedPage = page
                    }
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 10) {
                MiniStatusLine(
                    symbolName: "display",
                    title: viewModel.settings.overlayScope.displayName,
                    isActive: false
                )
                MiniStatusLine(
                    symbolName: viewModel.settings.modifierTapTrigger.isEnabled ? "command" : "command.circle",
                    title: primaryTriggerSummary,
                    isActive: viewModel.settings.modifierTapTrigger.isEnabled && primaryTriggerTone == .active
                )
                MiniStatusLine(
                    symbolName: viewModel.settings.launchAtLoginEnabled ? "power.circle.fill" : "power.circle",
                    title: loginSummary,
                    isActive: viewModel.settings.launchAtLoginEnabled
                )
            }
            .padding(.horizontal, 4)
        }
        .padding(.top, 54)
        .padding(.horizontal, 14)
        .padding(.bottom, 18)
        .frame(width: 210)
        .brightGlass(cornerRadius: 28, material: .sidebar, prominence: .sidebar)
    }

    private var header: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(selectedPage.title)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(GlassPalette.primaryText)

                Text(selectedPage.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            HeaderStat(
                symbolName: "rectangle.on.rectangle",
                title: "范围",
                value: viewModel.settings.overlayScope.displayName,
                tone: .neutral
            )
            HeaderStat(
                symbolName: "command",
                title: "主触发",
                value: primaryTriggerSummary,
                tone: primaryTriggerTone
            )
            HeaderStat(
                symbolName: "power",
                title: "启动",
                value: loginSummary,
                tone: viewModel.settings.launchAtLoginEnabled ? .active : .muted
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .brightGlass(cornerRadius: 24, material: .headerView, prominence: .header)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var pageContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch selectedPage {
            case .overlay:
                overlayContent
            case .exit:
                exitContent
            case .triggers:
                triggerContent
            case .about:
                aboutContent
            }
        }
    }

    private var overlayContent: some View {
        GlassSection(
            symbolName: "display",
            title: AppCopy.Settings.overlaySection,
            detail: AppCopy.Settings.overlaySectionDescription
        ) {
            SettingsRow(
                symbolName: "rectangle.on.rectangle",
                title: AppCopy.Settings.coverPicker,
                detail: AppCopy.Settings.coverPickerDetail
            ) {
                Picker(AppCopy.Settings.coverPicker, selection: $viewModel.settings.overlayScope) {
                    ForEach(OverlayScope.allCases) { scope in
                        Text(scope.displayName).tag(scope)
                    }
                }
                .labelsHidden()
                .frame(width: 178)
            }

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

            SettingsRow(
                symbolName: "textformat",
                title: AppCopy.Settings.contentPicker,
                detail: AppCopy.Settings.contentPickerDetail
            ) {
                Picker(AppCopy.Settings.contentPicker, selection: $viewModel.settings.overlayContentMode) {
                    ForEach(OverlayContentMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 178)
            }

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

            if viewModel.settings.overlayContentMode == .customText {
                SettingsRow(
                    symbolName: "quote.bubble",
                    title: AppCopy.Settings.customTextPlaceholder,
                    detail: viewModel.settings.sanitizedCustomText
                ) {
                    TextField(AppCopy.Settings.customTextPlaceholder, text: $viewModel.settings.customText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 240)
                }
                .transition(.opacity)
            }
        }
    }

    private var exitContent: some View {
        GlassSection(
            symbolName: "escape",
            title: AppCopy.Settings.exitSection,
            detail: AppCopy.Settings.exitSectionDescription
        ) {
            SettingsRow(
                symbolName: "cursorarrow.click",
                title: AppCopy.Settings.clickToExit,
                detail: AppCopy.Settings.clickToExitDetail,
                status: StatusPill(
                    text: viewModel.settings.clickToExitEnabled ? "已开启" : "已关闭",
                    tone: viewModel.settings.clickToExitEnabled ? .active : .muted
                ),
                isActive: viewModel.settings.clickToExitEnabled
            ) {
                Toggle(AppCopy.Settings.clickToExit, isOn: $viewModel.settings.clickToExitEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            SettingsRow(
                symbolName: "keyboard",
                title: AppCopy.Settings.keyToExit,
                detail: AppCopy.Settings.keyToExitDetail,
                status: StatusPill(
                    text: viewModel.settings.keyToExitEnabled ? "已开启" : "已关闭",
                    tone: viewModel.settings.keyToExitEnabled ? .active : .muted
                ),
                isActive: viewModel.settings.keyToExitEnabled
            ) {
                Toggle(AppCopy.Settings.keyToExit, isOn: $viewModel.settings.keyToExitEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            InlineNotice(
                symbolName: "checkmark.shield",
                text: AppCopy.Settings.escapeHint,
                tone: .neutral
            )
        }
    }

    private var triggerContent: some View {
        GlassSection(
            symbolName: "command",
            title: AppCopy.Settings.triggersSection,
            detail: AppCopy.Settings.triggersSectionDescription
        ) {
                SettingsRow(
                    symbolName: "power",
                    title: AppCopy.Settings.launchAtLogin,
                    detail: AppCopy.Settings.launchAtLoginDetail,
                    status: StatusPill(
                        text: viewModel.loginItemStatusText,
                        tone: viewModel.settings.launchAtLoginEnabled ? .active : .muted
                    ),
                    isActive: viewModel.settings.launchAtLoginEnabled
                ) {
                    Toggle(AppCopy.Settings.launchAtLogin, isOn: $viewModel.settings.launchAtLoginEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                SettingsRow(
                    symbolName: "arrow.up.left.and.arrow.down.right",
                    title: AppCopy.Settings.hotCorner,
                    detail: AppCopy.Settings.hotCornerDetail,
                    status: StatusPill(
                        text: viewModel.settings.cornerTrigger.isEnabled ? viewModel.settings.cornerTrigger.corner.displayName : "已关闭",
                        tone: viewModel.settings.cornerTrigger.isEnabled ? .active : .muted
                    ),
                    isActive: viewModel.settings.cornerTrigger.isEnabled
                ) {
                    HStack(spacing: 10) {
                        if viewModel.settings.cornerTrigger.isEnabled {
                            Picker(AppCopy.Settings.hotCornerPicker, selection: $viewModel.settings.cornerTrigger.corner) {
                                ForEach(ScreenCorner.allCases) { corner in
                                    Text(corner.displayName).tag(corner)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                            .transition(.opacity)
                        }

                        Toggle(AppCopy.Settings.hotCorner, isOn: $viewModel.settings.cornerTrigger.isEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }

                SettingsRow(
                    symbolName: "command",
                    title: AppCopy.Settings.enableModifierTap,
                    detail: AppCopy.Settings.enableModifierTapDetail,
                    status: StatusPill(text: viewModel.keyboardPermissionStatus.displayName, tone: keyboardPermissionTone),
                    isActive: viewModel.settings.modifierTapTrigger.isEnabled && viewModel.keyboardPermissionStatus != .needsAccessibilityPermission
                ) {
                    HStack(spacing: 10) {
                        if viewModel.settings.modifierTapTrigger.isEnabled {
                            Picker(AppCopy.Settings.commandSidePicker, selection: $viewModel.settings.modifierTapTrigger.commandSide) {
                                ForEach(CommandSide.allCases) { side in
                                    Text(side.displayName).tag(side)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 142)
                            .transition(.opacity)
                        }

                        Toggle(AppCopy.Settings.enableModifierTap, isOn: $viewModel.settings.modifierTapTrigger.isEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                } footer: {
                    if viewModel.keyboardPermissionStatus == .needsAccessibilityPermission {
                        InlineActionNotice(
                            symbolName: "exclamationmark.triangle",
                            text: viewModel.keyboardPermissionStatus.displayName,
                            buttonTitle: AppCopy.Settings.openAccessibilitySettings
                        ) {
                            viewModel.openAccessibilitySettings()
                        }
                    }
                }

                SettingsRow(
                    symbolName: "keyboard.badge.ellipsis",
                    title: AppCopy.Settings.enableComboHotkey,
                    detail: AppCopy.Settings.enableComboHotkeyDetail,
                    status: StatusPill(text: comboStatusText, tone: comboStatusTone),
                    isActive: viewModel.settings.comboHotKeyTrigger.isEnabled && comboStatusTone == .active
                ) {
                    Toggle(
                        AppCopy.Settings.enableComboHotkey,
                        isOn: Binding(
                            get: { viewModel.settings.comboHotKeyTrigger.isEnabled },
                            set: { viewModel.setComboHotKeyEnabled($0) }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                } footer: {
                    if viewModel.settings.comboHotKeyTrigger.isEnabled {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                if viewModel.isRecordingComboHotKey {
                                    HotKeyRecorderView { keyCode, modifiers, displayName in
                                        viewModel.saveComboHotKey(
                                            keyCode: keyCode,
                                            modifiers: modifiers,
                                            displayName: displayName
                                        )
                                    }
                                    .frame(height: 36)
                                } else {
                                    Text(viewModel.settings.comboHotKeyTrigger.displayName)
                                        .font(.system(.body, design: .monospaced).weight(.medium))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.76)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .glassControl(cornerRadius: 9, isActive: false)
                                }

                                Spacer()

                                if viewModel.isRecordingComboHotKey {
                                    Button(AppCopy.Settings.cancelRecording) {
                                        viewModel.cancelComboRecording()
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button {
                                        viewModel.isRecordingComboHotKey = true
                                    } label: {
                                        Label(AppCopy.Settings.recordComboHotkey, systemImage: "record.circle")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }

                            InlineNotice(
                                symbolName: comboStatusTone == .danger ? "exclamationmark.triangle" : "checkmark.circle",
                                text: comboStatusText,
                                tone: comboStatusTone == .danger ? .danger : .neutral
                            )
                        }
                    }
                }

                InlineNotice(
                    symbolName: "info.circle",
                    text: AppCopy.Settings.triggersHint,
                    tone: .neutral
                )
        }
    }

    private var aboutContent: some View {
        GlassSection(
            symbolName: "shield",
            title: "关于与安全",
            detail: AppCopy.Settings.safetyNotice
        ) {
            StaticInfoRow(
                symbolName: "eye.slash",
                title: AppCopy.appNameWithTechnicalName,
                detail: AppCopy.Settings.subtitle
            )

            StaticInfoRow(
                symbolName: "lock.open",
                title: "不是锁屏工具",
                detail: AppCopy.Settings.safetyNotice
            )

            StaticInfoRow(
                symbolName: "slider.horizontal.3",
                title: "默认配置",
                detail: AppCopy.Settings.defaultsHint
            )
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.resetToDefaults()
            } label: {
                Label(AppCopy.Settings.restoreDefaults, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("菜单栏和 Esc 始终保留为安全兜底。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .brightGlass(cornerRadius: 18, material: .popover, prominence: .footer)
    }

    private var primaryTriggerSummary: String {
        guard viewModel.settings.modifierTapTrigger.isEnabled else {
            return "Command 三连关闭"
        }
        return viewModel.keyboardPermissionStatus == .needsAccessibilityPermission ? "需授权" : "Command 三连"
    }

    private var primaryTriggerTone: StatusPill.Tone {
        guard viewModel.settings.modifierTapTrigger.isEnabled else {
            return .muted
        }
        return viewModel.keyboardPermissionStatus == .needsAccessibilityPermission ? .warning : .active
    }

    private var loginSummary: String {
        viewModel.settings.launchAtLoginEnabled ? "登录启动" : "手动启动"
    }

    private var keyboardPermissionTone: StatusPill.Tone {
        switch viewModel.keyboardPermissionStatus {
        case .granted:
            return .active
        case .needsAccessibilityPermission:
            return .warning
        case .disabled:
            return .muted
        case .unknown:
            return .neutral
        }
    }

    private var comboStatusText: String {
        if let comboHotKeyError = viewModel.comboHotKeyError {
            return comboHotKeyError
        }
        return viewModel.hotKeyConflictStatus.displayName
    }

    private var comboStatusTone: StatusPill.Tone {
        if viewModel.comboHotKeyError != nil || viewModel.hotKeyConflictStatus == .conflict {
            return .danger
        }
        if viewModel.settings.comboHotKeyTrigger.isEnabled && viewModel.hotKeyConflictStatus == .available {
            return .active
        }
        return .muted
    }
}

private enum SettingsPage: String, CaseIterable, Identifiable {
    case overlay
    case exit
    case triggers
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overlay:
            return AppCopy.Settings.overlaySection
        case .exit:
            return AppCopy.Settings.exitSection
        case .triggers:
            return AppCopy.Settings.triggersSection
        case .about:
            return "关于"
        }
    }

    var subtitle: String {
        switch self {
        case .overlay:
            return "管理黑屏覆盖与显示内容。"
        case .exit:
            return "选择恢复桌面的方式。"
        case .triggers:
            return "选择开启黑屏的入口。"
        case .about:
            return "视觉隐私辅助，不替代系统锁屏。"
        }
    }

    var symbolName: String {
        switch self {
        case .overlay:
            return "display"
        case .exit:
            return "escape"
        case .triggers:
            return "command"
        case .about:
            return "shield"
        }
    }
}

private struct SettingsBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            NativeGlassSurface(material: .underWindowBackground, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.020 : 0.040),
                    GlassPalette.accent.opacity(colorScheme == .dark ? 0.012 : 0.020),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    GlassPalette.accent.opacity(colorScheme == .dark ? 0.014 : 0.026)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private enum GlassPalette {
    static let accent = Color(nsColor: .systemBlue)
    static let primaryText = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)

    static func surfaceTint(_ colorScheme: ColorScheme, prominence: GlassProminence) -> Color {
        switch (colorScheme, prominence) {
        case (.dark, .sidebar):
            return Color.white.opacity(0.038)
        case (.dark, .header):
            return Color.white.opacity(0.034)
        case (.dark, .card):
            return Color.white.opacity(0.030)
        case (.dark, .control):
            return Color.white.opacity(0.052)
        case (.dark, .footer):
            return Color.white.opacity(0.032)
        case (_, .sidebar):
            return Color.white.opacity(0.045)
        case (_, .header):
            return Color.white.opacity(0.052)
        case (_, .card):
            return Color.white.opacity(0.042)
        case (_, .control):
            return Color.black.opacity(0.032)
        case (_, .footer):
            return Color.white.opacity(0.045)
        }
    }

    static func border(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.13)
            : Color.white.opacity(0.34)
    }

    static func hairline(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.080)
            : Color.black.opacity(0.050)
    }

    static func materialOpacity(_ colorScheme: ColorScheme, prominence: GlassProminence) -> Double {
        switch (colorScheme, prominence) {
        case (.dark, .control):
            return 0.82
        case (.dark, _):
            return 0.76
        case (_, .control):
            return 0.84
        case (_, .header), (_, .sidebar):
            return 0.78
        case (_, .card), (_, .footer):
            return 0.70
        }
    }
}

private struct SidebarItem: View {
    let page: SettingsPage
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: page.symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? GlassPalette.accent : .secondary)
                    .frame(width: 32, height: 32)

                Text(page.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? GlassPalette.primaryText : .primary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.22))
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(GlassPalette.border(colorScheme).opacity(0.75), lineWidth: 0.7)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MiniStatusLine: View {
    let symbolName: String
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? GlassPalette.accent : .secondary)
                .frame(width: 22, height: 22)
                .glassControl(cornerRadius: 8, isActive: isActive)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

private struct HeaderStat: View {
    let symbolName: String
    let title: String
    let value: String
    let tone: StatusPill.Tone

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tone == .active ? GlassPalette.accent : .secondary)
                .frame(width: 28, height: 28)
                .glassControl(cornerRadius: 9, isActive: tone == .active)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tone.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(width: 92, alignment: .leading)
        }
    }
}

private struct PageIntro: View {
    let symbolName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(GlassPalette.accent)
                .frame(width: 40, height: 40)
                .glassControl(cornerRadius: 13, isActive: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(GlassPalette.primaryText)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

private struct GlassSection<Content: View>: View {
    let symbolName: String
    let title: String
    let detail: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PageIntro(symbolName: symbolName, title: title, detail: detail)

            Rectangle()
                .fill(GlassPalette.hairline(colorScheme))
                .frame(height: 0.6)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding(18)
        .brightGlass(cornerRadius: 24, material: .popover, prominence: .card)
    }
}

private struct SettingsRow<Accessory: View, Footer: View>: View {
    let symbolName: String
    let title: String
    let detail: String
    let status: StatusPill?
    let isActive: Bool
    @ViewBuilder let accessory: Accessory
    @ViewBuilder let footer: Footer

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme

    init(
        symbolName: String,
        title: String,
        detail: String,
        status: StatusPill? = nil,
        isActive: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) where Footer == EmptyView {
        self.symbolName = symbolName
        self.title = title
        self.detail = detail
        self.status = status
        self.isActive = isActive
        self.accessory = accessory()
        self.footer = EmptyView()
    }

    init(
        symbolName: String,
        title: String,
        detail: String,
        status: StatusPill? = nil,
        isActive: Bool = false,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder footer: () -> Footer
    ) {
        self.symbolName = symbolName
        self.title = title
        self.detail = detail
        self.status = status
        self.isActive = isActive
        self.accessory = accessory()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isActive ? GlassPalette.accent : .secondary)
                    .frame(width: 32, height: 32)
                    .glassControl(cornerRadius: 10, isActive: isActive)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(GlassPalette.primaryText)

                        if let status {
                            status
                        }
                    }

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                accessory
                    .controlSize(.regular)
                    .frame(minWidth: 72, alignment: .trailing)
            }

            footer
                .padding(.leading, 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHovered ? hoverFill : Color.clear)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onHover { isHovered = $0 }
    }

    private var hoverFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.040)
            : Color.white.opacity(0.16)
    }
}

private struct StaticInfoRow: View {
    let symbolName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .glassControl(cornerRadius: 10, isActive: false)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GlassPalette.primaryText)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }
}

private struct StatusPill: View {
    enum Tone: Equatable {
        case active
        case muted
        case neutral
        case warning
        case danger

        var foreground: Color {
            switch self {
            case .active:
                return GlassPalette.accent
            case .danger:
                return .red
            case .muted, .neutral, .warning:
                return .secondary
            }
        }

        var isActive: Bool {
            self == .active
        }
    }

    let text: String
    let tone: Tone

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.74)
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(fill, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(stroke, lineWidth: 0.7)
            }
            .accessibilityLabel(text)
    }

    private var fill: Color {
        switch tone {
        case .active:
            return GlassPalette.accent.opacity(0.11)
        case .danger:
            return Color.red.opacity(0.08)
        case .muted, .neutral, .warning:
            return Color.secondary.opacity(0.08)
        }
    }

    private var stroke: Color {
        switch tone {
        case .active:
            return GlassPalette.accent.opacity(0.24)
        case .danger:
            return Color.red.opacity(0.20)
        case .muted, .neutral, .warning:
            return Color.secondary.opacity(0.15)
        }
    }
}

private struct InlineNotice: View {
    enum Tone: Equatable {
        case neutral
        case danger
    }

    let symbolName: String
    let text: String
    let tone: Tone
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tone == .danger ? Color.red : .secondary)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(noticeFill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(GlassPalette.hairline(colorScheme), lineWidth: 0.6)
        }
    }

    private var noticeFill: Color {
        switch tone {
        case .neutral:
            return colorScheme == .dark ? Color.white.opacity(0.034) : Color.white.opacity(0.16)
        case .danger:
            return Color.red.opacity(colorScheme == .dark ? 0.075 : 0.046)
        }
    }
}

private struct InlineActionNotice: View {
    let symbolName: String
    let text: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            InlineNotice(symbolName: symbolName, text: text, tone: .neutral)

            Button(buttonTitle, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

private extension View {
    func brightGlass(
        cornerRadius: CGFloat,
        material: NSVisualEffectView.Material,
        prominence: GlassProminence
    ) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, material: material, prominence: prominence))
    }

    func glassControl(cornerRadius: CGFloat, isActive: Bool) -> some View {
        modifier(GlassControlModifier(cornerRadius: cornerRadius, isActive: isActive))
    }
}

private enum GlassProminence {
    case sidebar
    case header
    case card
    case control
    case footer
}

private struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let material: NSVisualEffectView.Material
    let prominence: GlassProminence
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                NativeGlassSurface(material: material, blendingMode: .behindWindow)
                    .clipShape(shape)
                    .opacity(GlassPalette.materialOpacity(colorScheme, prominence: prominence))
            }
            .background {
                shape.fill(GlassPalette.surfaceTint(colorScheme, prominence: prominence))
            }
            .overlay {
                shape.stroke(GlassPalette.border(colorScheme), lineWidth: prominence == .control ? 0.55 : 0.8)
            }
            .overlay(alignment: .topLeading) {
                shape
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.075 : 0.20), lineWidth: 0.45)
                    .padding(0.5)
            }
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    private var shadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.16 : 0.060)
    }

    private var shadowRadius: CGFloat {
        switch prominence {
        case .sidebar:
            return 28
        case .header:
            return 22
        case .card:
            return 24
        case .control:
            return 10
        case .footer:
            return 18
        }
    }

    private var shadowY: CGFloat {
        switch prominence {
        case .sidebar:
            return 12
        case .header:
            return 7
        case .card:
            return 8
        case .control:
            return 3
        case .footer:
            return 6
        }
    }
}

private struct GlassControlModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isActive: Bool
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                shape.fill(fill)
            }
            .overlay {
                shape.stroke(GlassPalette.hairline(colorScheme), lineWidth: 0.6)
            }
    }

    private var fill: Color {
        if isActive {
            return GlassPalette.accent.opacity(colorScheme == .dark ? 0.15 : 0.12)
        }
        return colorScheme == .dark ? Color.white.opacity(0.052) : Color.black.opacity(0.040)
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
