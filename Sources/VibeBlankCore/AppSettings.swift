import Foundation

public enum OverlayScope: String, Codable, CaseIterable, Equatable, Identifiable {
    case externalDisplays
    case allDisplays

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .externalDisplays:
            return "External displays only"
        case .allDisplays:
            return "All displays"
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
            return "Blank"
        case .time:
            return "Time"
        case .statusText:
            return "Status text"
        case .customText:
            return "Custom text"
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
        return trimmed.isEmpty ? "VibeBlank Active" : trimmed
    }
}
