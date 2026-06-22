import Foundation

public enum OverlayScope: String, Codable, CaseIterable, Equatable, Identifiable {
    case externalDisplays
    case allDisplays

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .externalDisplays:
            return "仅外接显示器"
        case .allDisplays:
            return "所有显示器"
        }
    }
}

public enum OverlayBackgroundStyle: String, Codable, CaseIterable, Equatable, Identifiable {
    case pureBlack
    case whiteGlass
    case blackGlass

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pureBlack:
            return "纯黑"
        case .whiteGlass:
            return "白色毛玻璃"
        case .blackGlass:
            return "黑色强毛玻璃"
        }
    }
}

public enum TimerPlacement: String, Codable, CaseIterable, Equatable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .topLeft:
            return "左上角"
        case .topRight:
            return "右上角"
        case .bottomLeft:
            return "左下角"
        case .bottomRight:
            return "右下角"
        }
    }
}

public enum OverlayContentMode: String, Codable, CaseIterable, Equatable, Identifiable {
    case blank
    case time
    case statusText
    case customText
    case particleTimer

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .blank:
            return "纯黑"
        case .time:
            return "时间"
        case .statusText:
            return "状态文字"
        case .customText:
            return "自定义文字"
        case .particleTimer:
            return "粒子计时"
        }
    }
}

public enum ScreenCorner: String, Codable, CaseIterable, Equatable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .topLeft:
            return "左上角"
        case .topRight:
            return "右上角"
        case .bottomLeft:
            return "左下角"
        case .bottomRight:
            return "右下角"
        }
    }
}

public struct CornerTriggerSettings: Codable, Equatable {
    public var isEnabled: Bool
    public var corner: ScreenCorner

    public init(
        isEnabled: Bool = false,
        corner: ScreenCorner = .topRight
    ) {
        self.isEnabled = isEnabled
        self.corner = corner
    }

    public static let defaults = CornerTriggerSettings()
}

public enum CommandSide: String, Codable, CaseIterable, Equatable, Identifiable {
    case any
    case left
    case right

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .any:
            return "任意 Command"
        case .left:
            return "左 Command"
        case .right:
            return "右 Command"
        }
    }
}

public struct ModifierTapTriggerSettings: Codable, Equatable {
    public var isEnabled: Bool
    public var commandSide: CommandSide
    public var tapCount: Int
    public var maxInterval: TimeInterval

    public init(
        isEnabled: Bool = true,
        commandSide: CommandSide = .any,
        tapCount: Int = 3,
        maxInterval: TimeInterval = 0.8
    ) {
        self.isEnabled = isEnabled
        self.commandSide = commandSide
        self.tapCount = tapCount
        self.maxInterval = maxInterval
    }

    public static let defaults = ModifierTapTriggerSettings()
}

public struct ComboHotKeySettings: Codable, Equatable {
    public var isEnabled: Bool
    public var keyCode: UInt32
    public var modifiers: UInt32
    public var displayName: String

    public init(
        isEnabled: Bool = false,
        keyCode: UInt32 = 11,
        modifiers: UInt32 = 6_400,
        displayName: String = "Control + Option + Command + B"
    ) {
        self.isEnabled = isEnabled
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.displayName = displayName
    }

    public static let defaults = ComboHotKeySettings()
}

public enum KeyboardPermissionStatus: String, Codable, Equatable {
    case unknown
    case granted
    case needsAccessibilityPermission
    case disabled

    public var displayName: String {
        switch self {
        case .unknown:
            return "键盘监听状态未知"
        case .granted:
            return "Command 三连已可用"
        case .needsAccessibilityPermission:
            return "需要在系统设置中允许辅助功能"
        case .disabled:
            return "Command 三连已关闭"
        }
    }
}

public enum HotKeyConflictStatus: String, Codable, Equatable {
    case unchecked
    case available
    case conflict
    case disabled

    public var displayName: String {
        switch self {
        case .unchecked:
            return "组合键尚未检测"
        case .available:
            return "组合键已可用"
        case .conflict:
            return "组合键冲突，请重新录制"
        case .disabled:
            return "组合键已关闭"
        }
    }
}

public struct AppSettings: Codable, Equatable {
    public var overlayScope: OverlayScope
    public var overlayContentMode: OverlayContentMode
    public var overlayBackgroundStyle: OverlayBackgroundStyle
    public var timerPlacement: TimerPlacement
    public var customText: String
    public var clickToExitEnabled: Bool
    public var keyToExitEnabled: Bool
    public var launchAtLoginEnabled: Bool
    public var cornerTrigger: CornerTriggerSettings
    public var modifierTapTrigger: ModifierTapTriggerSettings
    public var comboHotKeyTrigger: ComboHotKeySettings
    public var keyboardPermissionStatus: KeyboardPermissionStatus
    public var hotKeyConflictStatus: HotKeyConflictStatus

    public init(
        overlayScope: OverlayScope = .externalDisplays,
        overlayContentMode: OverlayContentMode = .blank,
        overlayBackgroundStyle: OverlayBackgroundStyle = .pureBlack,
        timerPlacement: TimerPlacement = .bottomRight,
        customText: String = "",
        clickToExitEnabled: Bool = false,
        keyToExitEnabled: Bool = false,
        launchAtLoginEnabled: Bool = true,
        cornerTrigger: CornerTriggerSettings = .defaults,
        modifierTapTrigger: ModifierTapTriggerSettings = .defaults,
        comboHotKeyTrigger: ComboHotKeySettings = .defaults,
        keyboardPermissionStatus: KeyboardPermissionStatus = .unknown,
        hotKeyConflictStatus: HotKeyConflictStatus = .unchecked
    ) {
        self.overlayScope = overlayScope
        self.overlayContentMode = overlayContentMode
        self.overlayBackgroundStyle = overlayBackgroundStyle
        self.timerPlacement = timerPlacement
        self.customText = customText
        self.clickToExitEnabled = clickToExitEnabled
        self.keyToExitEnabled = keyToExitEnabled
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.cornerTrigger = cornerTrigger
        self.modifierTapTrigger = modifierTapTrigger
        self.comboHotKeyTrigger = comboHotKeyTrigger
        self.keyboardPermissionStatus = keyboardPermissionStatus
        self.hotKeyConflictStatus = hotKeyConflictStatus
    }

    public static let defaults = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case overlayScope
        case overlayContentMode
        case overlayBackgroundStyle
        case timerPlacement
        case customText
        case clickToExitEnabled
        case keyToExitEnabled
        case launchAtLoginEnabled
        case cornerTrigger
        case modifierTapTrigger
        case comboHotKeyTrigger
        case keyboardPermissionStatus
        case hotKeyConflictStatus
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overlayScope = try container.decodeIfPresent(OverlayScope.self, forKey: .overlayScope) ?? .externalDisplays
        overlayContentMode = try container.decodeIfPresent(OverlayContentMode.self, forKey: .overlayContentMode) ?? .blank
        overlayBackgroundStyle = try container.decodeIfPresent(
            OverlayBackgroundStyle.self,
            forKey: .overlayBackgroundStyle
        ) ?? .pureBlack
        timerPlacement = try container.decodeIfPresent(TimerPlacement.self, forKey: .timerPlacement) ?? .bottomRight
        customText = try container.decodeIfPresent(String.self, forKey: .customText) ?? ""
        clickToExitEnabled = try container.decodeIfPresent(Bool.self, forKey: .clickToExitEnabled) ?? false
        keyToExitEnabled = try container.decodeIfPresent(Bool.self, forKey: .keyToExitEnabled) ?? false
        launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? true
        cornerTrigger = try container.decodeIfPresent(CornerTriggerSettings.self, forKey: .cornerTrigger) ?? .defaults
        modifierTapTrigger = try container.decodeIfPresent(ModifierTapTriggerSettings.self, forKey: .modifierTapTrigger) ?? .defaults
        comboHotKeyTrigger = try container.decodeIfPresent(ComboHotKeySettings.self, forKey: .comboHotKeyTrigger) ?? .defaults
        keyboardPermissionStatus = try container.decodeIfPresent(
            KeyboardPermissionStatus.self,
            forKey: .keyboardPermissionStatus
        ) ?? .unknown
        hotKeyConflictStatus = try container.decodeIfPresent(
            HotKeyConflictStatus.self,
            forKey: .hotKeyConflictStatus
        ) ?? .unchecked
    }

    public var sanitizedCustomText: String {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "黑码码已开启" : trimmed
    }
}
