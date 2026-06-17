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

public enum OverlayContentMode: String, Codable, CaseIterable, Equatable, Identifiable {
    case blank
    case time
    case statusText
    case customText

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
        }
    }
}

public struct AppSettings: Codable, Equatable {
    public var overlayScope: OverlayScope
    public var overlayContentMode: OverlayContentMode
    public var customText: String
    public var clickToExitEnabled: Bool
    public var keyToExitEnabled: Bool
    public var globalHotkeyEnabled: Bool

    public init(
        overlayScope: OverlayScope = .externalDisplays,
        overlayContentMode: OverlayContentMode = .blank,
        customText: String = "",
        clickToExitEnabled: Bool = false,
        keyToExitEnabled: Bool = false,
        globalHotkeyEnabled: Bool = true
    ) {
        self.overlayScope = overlayScope
        self.overlayContentMode = overlayContentMode
        self.customText = customText
        self.clickToExitEnabled = clickToExitEnabled
        self.keyToExitEnabled = keyToExitEnabled
        self.globalHotkeyEnabled = globalHotkeyEnabled
    }

    public static let defaults = AppSettings()

    public var sanitizedCustomText: String {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "黑码码已开启" : trimmed
    }
}
