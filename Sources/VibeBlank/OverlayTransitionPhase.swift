import SwiftUI

enum OverlayTransitionPhase: Equatable {
    case appearing
    case visible
    case disappearing
}

@MainActor
final class OverlayTransitionModel: ObservableObject {
    static let duration: TimeInterval = 0.32

    @Published private(set) var phase: OverlayTransitionPhase = .appearing
    @Published var coverage: CGFloat = 0

    func appear() {
        phase = .appearing
        coverage = 0

        withAnimation(.easeInOut(duration: Self.duration)) {
            coverage = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.duration) { [weak self] in
            guard let self, self.phase == .appearing else {
                return
            }
            self.phase = .visible
            self.coverage = 1
        }
    }

    func disappear(completion: @escaping () -> Void) {
        guard phase != .disappearing else {
            return
        }

        phase = .disappearing

        withAnimation(.easeInOut(duration: Self.duration)) {
            coverage = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.duration) { [weak self] in
            guard let self, self.phase == .disappearing else {
                return
            }
            completion()
        }
    }
}
