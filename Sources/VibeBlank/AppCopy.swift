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
        static let hotkeyAvailable = "快捷键：Control + Option + Command + B"
        static let hotkeyUnavailable = "快捷键：不可用（请使用菜单或 Esc）"
        static let hotkeyOff = "快捷键：已关闭（Esc 仍可退出遮罩）"
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
        static let enableHotkey = "启用 Control + Option + Command + B 快捷键"
        static let triggersHint = "菜单栏始终可用，且不需要敏感权限。触发角计划在后续版本支持。"
        static let headline = "黑码码"
        static let subtitle = "在智能体、构建、终端和本地服务继续运行时，遮住你的显示器。"
        static let safetyNotice = "黑码码是视觉隐私辅助工具，不是锁屏或身份验证工具。"
        static let restoreDefaults = "恢复默认设置"
        static let defaultsHint = "默认：仅外接显示器，纯黑遮罩。"
    }
}
