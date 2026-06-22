import AppKit
import SwiftUI
import VibeBlankCore

struct StatusPanelView: View {
    let settings: AppSettings
    let isOverlayActive: Bool
    let keyboardPermissionStatus: KeyboardPermissionStatus
    let hotKeyConflictStatus: HotKeyConflictStatus
    let loginItemStatus: LoginItemSyncStatus
    let toggleOverlay: () -> Void
    let openSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            NativeGlassSurface(material: .popover, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.060),
                    Color.clear,
                    PanelPalette.accent.opacity(0.026)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            VStack(spacing: 14) {
                header

                PanelSection {
                    PanelInfoRow(
                        symbolName: "rectangle.on.rectangle",
                        title: AppCopy.Menu.scopePrefix,
                        value: settings.overlayScope.displayName,
                        isActive: false
                    )

                    PanelInfoRow(
                        symbolName: "command",
                        title: "主触发",
                        value: primaryTriggerText,
                        isActive: settings.modifierTapTrigger.isEnabled && keyboardPermissionStatus != .needsAccessibilityPermission
                    )

                    PanelInfoRow(
                        symbolName: "keyboard.badge.ellipsis",
                        title: "组合键",
                        value: comboTriggerText,
                        tone: hotKeyConflictStatus == .conflict ? .danger : .neutral
                    )

                    PanelInfoRow(
                        symbolName: "power",
                        title: "登录项",
                        value: loginItemStatus.displayName,
                        isActive: settings.launchAtLoginEnabled
                    )
                }

                PanelSection {
                    PanelActionRow(
                        symbolName: isOverlayActive ? "rectangle.slash" : "rectangle.fill",
                        title: isOverlayActive ? AppCopy.Menu.deactivate : AppCopy.Menu.activate,
                        detail: isOverlayActive ? "恢复桌面显示" : "按当前设置开启黑屏",
                        isPrimary: true,
                        action: toggleOverlay
                    )

                    PanelActionRow(
                        symbolName: "gearshape",
                        title: AppCopy.Menu.settings,
                        detail: "打开完整设置窗口",
                        action: openSettings
                    )

                    PanelActionRow(
                        symbolName: "xmark",
                        title: AppCopy.Menu.quit,
                        detail: "退出常驻菜单栏工具",
                        tone: .neutral,
                        action: quit
                    )
                }

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PanelPalette.accent)

                    Text(AppCopy.Settings.escapeHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(14)
        }
        .frame(width: 360, height: 610, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 0.8)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 10)
        .tint(PanelPalette.accent)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(PanelPalette.accent)
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.038), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(AppCopy.appName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(PanelPalette.primaryText)

                Text(isOverlayActive ? "黑屏正在保护显示内容" : "菜单栏常驻，随时开启黑屏")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Toggle(
                AppCopy.appName,
                isOn: Binding(
                    get: { isOverlayActive },
                    set: { _ in toggleOverlay() }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 0.7)
        }
    }

    private var primaryTriggerText: String {
        guard settings.modifierTapTrigger.isEnabled else {
            return AppCopy.Menu.primaryTriggerOff
        }
        return keyboardPermissionStatus == .needsAccessibilityPermission
            ? AppCopy.Menu.primaryTriggerNeedsPermission
            : AppCopy.Menu.primaryTriggerAvailable
    }

    private var comboTriggerText: String {
        guard settings.comboHotKeyTrigger.isEnabled else {
            return AppCopy.Menu.comboHotkeyOff
        }
        return hotKeyConflictStatus == .available
            ? AppCopy.Menu.comboHotkeyAvailable(settings.comboHotKeyTrigger.displayName)
            : AppCopy.Menu.comboHotkeyUnavailable
    }
}

private enum PanelPalette {
    static let accent = Color(nsColor: .systemBlue)
    static let primaryText = Color(nsColor: .labelColor)
}

private enum PanelTone {
    case neutral
    case danger

    var foreground: Color {
        switch self {
        case .neutral:
            return .secondary
        case .danger:
            return .red
        }
    }
}

private struct PanelSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(10)
        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.30), lineWidth: 0.7)
        }
    }
}

private struct PanelInfoRow: View {
    let symbolName: String
    let title: String
    let value: String
    var isActive = false
    var tone: PanelTone = .neutral

    var body: some View {
        HStack(spacing: 10) {
            PanelIcon(symbolName: symbolName, isActive: isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(PanelPalette.primaryText)

                Text(value)
                    .font(.caption)
                    .foregroundStyle(tone.foreground)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
    }
}

private struct PanelActionRow: View {
    let symbolName: String
    let title: String
    let detail: String
    var isPrimary = false
    var tone: PanelTone = .neutral
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                PanelIcon(symbolName: symbolName, isActive: isPrimary, tone: tone)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(PanelPalette.primaryText)

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            if isPrimary {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(PanelPalette.accent.opacity(0.10))
            }
        }
    }
}

private struct PanelIcon: View {
    let symbolName: String
    var isActive = false
    var tone: PanelTone = .neutral

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 14, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(foreground)
            .frame(width: 30, height: 30)
            .background(fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var foreground: Color {
        if tone == .danger {
            return .red
        }
        return isActive ? PanelPalette.accent : .secondary
    }

    private var fill: Color {
        if tone == .danger {
            return Color.red.opacity(0.08)
        }
        return isActive ? PanelPalette.accent.opacity(0.11) : Color.black.opacity(0.040)
    }
}
