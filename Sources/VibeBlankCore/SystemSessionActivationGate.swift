import Foundation

public struct SystemSessionActivationGate: Equatable {
    public static let defaultCooldown: TimeInterval = 1.5

    public private(set) var isProtectedSessionActive: Bool
    public private(set) var cooldownEndsAt: Date?

    public init(
        isProtectedSessionActive: Bool = false,
        cooldownEndsAt: Date? = nil
    ) {
        self.isProtectedSessionActive = isProtectedSessionActive
        self.cooldownEndsAt = cooldownEndsAt
    }

    public var allowsDeactivation: Bool {
        true
    }

    public func allowsActivation(at now: Date) -> Bool {
        guard !isProtectedSessionActive else {
            return false
        }

        if let cooldownEndsAt, now < cooldownEndsAt {
            return false
        }

        return true
    }

    public mutating func markProtectedSessionStarted() {
        isProtectedSessionActive = true
        cooldownEndsAt = nil
    }

    public mutating func markProtectedSessionEnded(
        at now: Date,
        cooldown: TimeInterval = Self.defaultCooldown
    ) {
        isProtectedSessionActive = false
        cooldownEndsAt = now.addingTimeInterval(max(0, cooldown))
    }
}
