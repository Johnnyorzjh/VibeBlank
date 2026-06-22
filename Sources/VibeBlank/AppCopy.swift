enum AppCopy {
    static let appName = "黑码码"
    static let appNameWithTechnicalName = "黑码码（VibeBlank）"
    static let statusTooltip = "黑码码视觉隐私保护"
    static let overlayWindowTitle = "黑码码遮罩"
    static let settingsWindowTitle = "黑码码设置"
    static let residentUtilityReason = "黑码码是常驻菜单栏工具。"

    enum Menu {
        static let activate = "开启黑屏"
        static let deactivate = "退出黑屏"
        static let scopePrefix = "覆盖范围"
        static let primaryTriggerAvailable = "主触发：Command 三连"
        static let primaryTriggerNeedsPermission = "主触发：Command 三连需要辅助功能权限"
        static let primaryTriggerOff = "主触发：已关闭"
        static let comboHotkeyOff = "组合键：已关闭"
        static let comboHotkeyUnavailable = "组合键：不可用（请重新录制）"
        static func comboHotkeyAvailable(_ displayName: String) -> String {
            "组合键：\(displayName)"
        }
        static let cornerOff = "触发角：已关闭"
        static func cornerAvailable(_ displayName: String) -> String {
            "触发角：\(displayName)"
        }
        static let settings = "设置..."
        static let quit = "退出黑码码"
    }

    enum Settings {
        static let overlaySection = "遮罩"
        static let coverPicker = "覆盖范围"
        static let contentPicker = "显示内容"
        static let customTextPlaceholder = "自定义文字"
        static let exitSection = "退出方式"
        static let clickToExit = "点击遮罩退出"
        static let keyToExit = "按任意键退出"
        static let escapeHint = "Esc 始终可退出黑屏，作为安全兜底。"
        static let triggersSection = "触发方式"
        static let launchAtLogin = "登录时自动启动黑码码"
        static let hotCorner = "触发角开启黑屏"
        static let hotCornerPicker = "角落"
        static let enableModifierTap = "启用 Command 三连"
        static let commandSidePicker = "Command 按键"
        static let openAccessibilitySettings = "打开辅助功能设置"
        static let enableComboHotkey = "启用组合键"
        static let recordComboHotkey = "录制组合键"
        static let cancelRecording = "取消"
        static let recordingHint = "请按下新的组合键，例如 Control + Option + Command + B。"
        static let comboNeedsModifier = "组合键至少需要一个修饰键。"
        static let comboConflict = "这个组合键不可用，可能已被系统或其他应用占用。"
        static let triggersHint = "菜单栏和 Esc 始终可用。触发角只开启黑屏，键盘触发可开启或退出。"
        static let headline = "黑码码"
        static let subtitle = "让 AI 悄悄帮你干活。"
        static let safetyNotice = "黑码码是视觉隐私辅助工具，不是锁屏或身份验证工具。"
        static let restoreDefaults = "恢复默认设置"
        static let defaultsHint = "默认：登录启动，Command 三连，仅外接显示器。"
    }
}
