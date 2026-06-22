import CoreGraphics
import Foundation

public struct ScreenFrameSnapshot: Equatable {
    public var id: UInt32
    public var frame: CGRect

    public init(id: UInt32, frame: CGRect) {
        self.id = id
        self.frame = frame
    }
}

public struct HotCornerPushPolicy: Equatable {
    public var approachSize: CGFloat
    public var activationSize: CGFloat
    public var cooldown: TimeInterval

    public init(
        approachSize: CGFloat = 72,
        activationSize: CGFloat = 6,
        cooldown: TimeInterval = 2
    ) {
        self.approachSize = approachSize
        self.activationSize = activationSize
        self.cooldown = cooldown
    }

    public static let `default` = HotCornerPushPolicy()
}

public struct HotCornerPushEvaluator {
    private enum State: Equatable {
        case idle
        case armed(screenID: UInt32)
    }

    private var policy: HotCornerPushPolicy
    private var state: State = .idle
    private var lastTriggerDate = Date.distantPast
    private var mustLeaveActivationZone = false

    public init(policy: HotCornerPushPolicy = .default) {
        self.policy = policy
    }

    public mutating func reset() {
        state = .idle
        mustLeaveActivationZone = false
    }

    public mutating func update(
        mouseLocation: CGPoint,
        screens: [ScreenFrameSnapshot],
        corner: ScreenCorner,
        timestamp: Date
    ) -> Bool {
        guard
            let target = screens.first(where: {
                isPoint(mouseLocation, inside: $0.frame)
                    && isCornerExposed(corner, of: $0.frame, among: screens)
            })
        else {
            reset()
            return false
        }

        let inActivationZone = isPoint(mouseLocation, inActivationZoneFor: corner, of: target.frame)

        if mustLeaveActivationZone {
            if inActivationZone {
                return false
            }
            mustLeaveActivationZone = false
            state = .idle
        }

        if inActivationZone {
            guard state == .armed(screenID: target.id) else {
                state = .idle
                return false
            }

            state = .idle
            mustLeaveActivationZone = true

            guard timestamp.timeIntervalSince(lastTriggerDate) >= policy.cooldown else {
                return false
            }

            lastTriggerDate = timestamp
            return true
        }

        if isPoint(mouseLocation, inInteriorApproachZoneFor: corner, of: target.frame) {
            state = .armed(screenID: target.id)
        } else {
            state = .idle
        }

        return false
    }

    private func isPoint(_ point: CGPoint, inside frame: CGRect) -> Bool {
        point.x >= frame.minX
            && point.x <= frame.maxX
            && point.y >= frame.minY
            && point.y <= frame.maxY
    }

    private func isPoint(_ point: CGPoint, inActivationZoneFor corner: ScreenCorner, of frame: CGRect) -> Bool {
        switch corner {
        case .topLeft:
            return point.x <= frame.minX + policy.activationSize
                && point.y >= frame.maxY - policy.activationSize
        case .topRight:
            return point.x >= frame.maxX - policy.activationSize
                && point.y >= frame.maxY - policy.activationSize
        case .bottomLeft:
            return point.x <= frame.minX + policy.activationSize
                && point.y <= frame.minY + policy.activationSize
        case .bottomRight:
            return point.x >= frame.maxX - policy.activationSize
                && point.y <= frame.minY + policy.activationSize
        }
    }

    private func isPoint(_ point: CGPoint, inInteriorApproachZoneFor corner: ScreenCorner, of frame: CGRect) -> Bool {
        switch corner {
        case .topLeft:
            return point.x > frame.minX + policy.activationSize
                && point.x <= frame.minX + policy.approachSize
                && point.y < frame.maxY - policy.activationSize
                && point.y >= frame.maxY - policy.approachSize
        case .topRight:
            return point.x < frame.maxX - policy.activationSize
                && point.x >= frame.maxX - policy.approachSize
                && point.y < frame.maxY - policy.activationSize
                && point.y >= frame.maxY - policy.approachSize
        case .bottomLeft:
            return point.x > frame.minX + policy.activationSize
                && point.x <= frame.minX + policy.approachSize
                && point.y > frame.minY + policy.activationSize
                && point.y <= frame.minY + policy.approachSize
        case .bottomRight:
            return point.x < frame.maxX - policy.activationSize
                && point.x >= frame.maxX - policy.approachSize
                && point.y > frame.minY + policy.activationSize
                && point.y <= frame.minY + policy.approachSize
        }
    }

    private func isCornerExposed(
        _ corner: ScreenCorner,
        of frame: CGRect,
        among screens: [ScreenFrameSnapshot]
    ) -> Bool {
        let epsilon: CGFloat = 0.5
        let outsidePoints: [CGPoint]

        switch corner {
        case .topLeft:
            outsidePoints = [
                CGPoint(x: frame.minX + epsilon, y: frame.maxY + epsilon),
                CGPoint(x: frame.minX - epsilon, y: frame.maxY - epsilon)
            ]
        case .topRight:
            outsidePoints = [
                CGPoint(x: frame.maxX - epsilon, y: frame.maxY + epsilon),
                CGPoint(x: frame.maxX + epsilon, y: frame.maxY - epsilon)
            ]
        case .bottomLeft:
            outsidePoints = [
                CGPoint(x: frame.minX + epsilon, y: frame.minY - epsilon),
                CGPoint(x: frame.minX - epsilon, y: frame.minY + epsilon)
            ]
        case .bottomRight:
            outsidePoints = [
                CGPoint(x: frame.maxX - epsilon, y: frame.minY - epsilon),
                CGPoint(x: frame.maxX + epsilon, y: frame.minY + epsilon)
            ]
        }

        return !outsidePoints.contains { point in
            screens.contains { screen in
                screen.frame != frame && isPoint(point, inside: screen.frame)
            }
        }
    }
}
