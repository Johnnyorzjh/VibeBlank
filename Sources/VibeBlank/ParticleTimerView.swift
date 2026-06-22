import AppKit
import SwiftUI
import VibeBlankCore

struct ParticleTimerView: View {
    let text: String
    let placement: TimerPlacement
    let backgroundStyle: OverlayBackgroundStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        glyphRow
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .liquidGlassSurface(cornerRadius: 18, material: hudMaterial, prominence: .hud)
            .accessibilityLabel(Text("黑屏计时 \(text)"))
            .padding(.horizontal, 44)
            .padding(.vertical, 38)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: placement.alignment)
            .opacity(0.92)
            .onAppear {
                guard !reduceMotion else {
                    return
                }

                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }

    private var glyphRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(text.enumerated()), id: \.offset) { item in
                ParticleGlyph(
                    character: item.element,
                    color: particleColor,
                    inactiveColor: inactiveParticleColor,
                    pulseAmount: reduceMotion ? 0 : (pulse ? 1 : 0)
                )
            }
        }
    }

    private var particleColor: Color {
        switch backgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.76)
        case .pureBlack, .blackGlass:
            return Color.white.opacity(0.82)
        }
    }

    private var inactiveParticleColor: Color {
        switch backgroundStyle {
        case .whiteGlass:
            return Color.black.opacity(0.10)
        case .pureBlack, .blackGlass:
            return Color.white.opacity(0.13)
        }
    }

    private var hudMaterial: NSVisualEffectView.Material {
        switch backgroundStyle {
        case .whiteGlass:
            return .hudWindow
        case .pureBlack, .blackGlass:
            return .fullScreenUI
        }
    }
}

private struct ParticleGlyph: View {
    let character: Character
    let color: Color
    let inactiveColor: Color
    let pulseAmount: Double

    private let dotSize: CGFloat = 5.5
    private let dotSpacing: CGFloat = 3.3

    var body: some View {
        let pattern = ParticleGlyphPattern.pattern(for: character)

        VStack(spacing: dotSpacing) {
            ForEach(0..<pattern.rows.count, id: \.self) { row in
                HStack(spacing: dotSpacing) {
                    ForEach(0..<pattern.width, id: \.self) { column in
                        let isActive = pattern.rows[row][column]

                        Circle()
                            .fill(isActive ? color : inactiveColor)
                            .frame(width: dotSize, height: dotSize)
                            .opacity(opacity(row: row, column: column, isActive: isActive))
                    }
                }
            }
        }
        .frame(width: CGFloat(pattern.width) * dotSize + CGFloat(max(0, pattern.width - 1)) * dotSpacing)
    }

    private func opacity(row: Int, column: Int, isActive: Bool) -> Double {
        guard isActive else {
            return 1
        }

        let stagger = Double((row + column) % 4) * 0.035
        return 0.82 + min(0.18, pulseAmount * (0.12 + stagger))
    }
}

private struct ParticleGlyphPattern {
    let width: Int
    let rows: [[Bool]]

    static func pattern(for character: Character) -> ParticleGlyphPattern {
        let rawRows = rawPattern(for: character)
        return ParticleGlyphPattern(
            width: rawRows.first?.count ?? 0,
            rows: rawRows.map { row in row.map { $0 == "1" } }
        )
    }

    private static func rawPattern(for character: Character) -> [String] {
        switch character {
        case "0":
            return ["11111", "10001", "10011", "10101", "11001", "10001", "11111"]
        case "1":
            return ["00100", "01100", "00100", "00100", "00100", "00100", "01110"]
        case "2":
            return ["11111", "00001", "00001", "11111", "10000", "10000", "11111"]
        case "3":
            return ["11111", "00001", "00001", "01111", "00001", "00001", "11111"]
        case "4":
            return ["10001", "10001", "10001", "11111", "00001", "00001", "00001"]
        case "5":
            return ["11111", "10000", "10000", "11111", "00001", "00001", "11111"]
        case "6":
            return ["11111", "10000", "10000", "11111", "10001", "10001", "11111"]
        case "7":
            return ["11111", "00001", "00010", "00100", "01000", "01000", "01000"]
        case "8":
            return ["11111", "10001", "10001", "11111", "10001", "10001", "11111"]
        case "9":
            return ["11111", "10001", "10001", "11111", "00001", "00001", "11111"]
        case ":":
            return ["0", "0", "1", "0", "1", "0", "0"]
        default:
            return ["000", "000", "000", "000", "000", "000", "000"]
        }
    }
}

private extension TimerPlacement {
    var alignment: Alignment {
        switch self {
        case .topLeft:
            return .topLeading
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomRight:
            return .bottomTrailing
        }
    }
}
