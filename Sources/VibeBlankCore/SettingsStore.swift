import Foundation

public final class SettingsStore {
    private enum Keys {
        static let settings = "settings"
        static let hasCompletedFirstLaunch = "hasCompletedFirstLaunch"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let completedOnboardingVersion = "completedOnboardingVersion"
    }

    public static let currentOnboardingVersion = 2

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings) else {
            return .defaults
        }

        do {
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            return .defaults
        }
    }

    public func save(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else {
            return
        }
        defaults.set(data, forKey: Keys.settings)
    }

    public var hasCompletedFirstLaunch: Bool {
        defaults.bool(forKey: Keys.hasCompletedFirstLaunch)
    }

    public func markFirstLaunchCompleted() {
        defaults.set(true, forKey: Keys.hasCompletedFirstLaunch)
    }

    public var hasCompletedOnboarding: Bool {
        completedOnboardingVersion >= Self.currentOnboardingVersion
    }

    public func markOnboardingCompleted() {
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        defaults.set(Self.currentOnboardingVersion, forKey: Keys.completedOnboardingVersion)
    }

    public var completedOnboardingVersion: Int {
        defaults.integer(forKey: Keys.completedOnboardingVersion)
    }

    public func resetForTests() {
        defaults.removeObject(forKey: Keys.settings)
        defaults.removeObject(forKey: Keys.hasCompletedFirstLaunch)
        defaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        defaults.removeObject(forKey: Keys.completedOnboardingVersion)
    }
}
