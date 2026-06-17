import Foundation
import VibeBlankCore

extension Notification.Name {
    static let vibeBlankSettingsDidChange = Notification.Name("VibeBlankSettingsDidChange")
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            store.save(settings)
            NotificationCenter.default.post(name: .vibeBlankSettingsDidChange, object: nil)
        }
    }

    private let store: SettingsStore

    init(store: SettingsStore) {
        self.store = store
        self.settings = store.load()
    }

    func resetToDefaults() {
        settings = .defaults
    }
}
