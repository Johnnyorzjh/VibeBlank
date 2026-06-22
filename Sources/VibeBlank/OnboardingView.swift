import AppKit
import SwiftUI

struct OnboardingView: View {
    let loginItemStatus: LoginItemSyncStatus
    let openLoginItemsSettings: () -> Void
    let start: () -> Void

    var body: some View {
        ZStack {
            NativeGlassSurface(material: .underPageBackground, blendingMode: .behindWindow, isEmphasized: false)
                .ignoresSafeArea()
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.72)
                .ignoresSafeArea()

            HStack(alignment: .center, spacing: 32) {
                copyColumn
                    .frame(width: 342, alignment: .leading)

                guideImage
                    .aspectRatio(16.0 / 10.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 44)
            .padding(.top, 40)
            .padding(.bottom, 32)
        }
        .foregroundStyle(.primary)
    }

    private var copyColumn: some View {
        VStack(alignment: .leading, spacing: 17) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppCopy.Onboarding.eyebrow)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.green)
                    .textCase(.uppercase)
                Text(AppCopy.Onboarding.title)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(AppCopy.Onboarding.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                OnboardingStepRow(
                    systemImage: "menubar.rectangle",
                    title: AppCopy.Onboarding.menuBarTitle,
                    detail: AppCopy.Onboarding.menuBarDetail
                )
                OnboardingStepRow(
                    systemImage: "command",
                    title: AppCopy.Onboarding.triggerTitle,
                    detail: AppCopy.Onboarding.triggerDetail
                )
                OnboardingStepRow(
                    systemImage: "timer",
                    title: AppCopy.Onboarding.timerTitle,
                    detail: AppCopy.Onboarding.timerDetail
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            loginItemCard

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                if loginItemStatus == .requiresApproval {
                    Button(AppCopy.Onboarding.openLoginItems) {
                        openLoginItemsSettings()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer(minLength: 0)

                Button(AppCopy.Onboarding.start) {
                    start()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var loginItemCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: loginItemIconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(loginItemAccentColor)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(loginItemAccentColor.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(AppCopy.Onboarding.launchStatusTitle)
                    .font(.system(size: 13, weight: .semibold))
                Text(loginItemStatus.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.055))
        )
    }

    private var guideImage: some View {
        ZStack {
            if let image = Self.loadGuideImage() {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                OnboardingGuideFallback()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 18)
    }

    private var loginItemIconName: String {
        switch loginItemStatus {
        case .enabled:
            return "checkmark"
        case .requiresApproval:
            return "exclamationmark"
        case .failed:
            return "xmark"
        case .disabled, .notFound:
            return "minus"
        }
    }

    private var loginItemAccentColor: Color {
        switch loginItemStatus {
        case .enabled:
            return .green
        case .requiresApproval:
            return .orange
        case .failed:
            return .red
        case .disabled, .notFound:
            return .secondary
        }
    }

    private static func loadGuideImage() -> NSImage? {
        if let image = NSImage(named: "onboarding-guide") {
            return image
        }
        guard let url = Bundle.main.url(forResource: "onboarding-guide", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

private struct OnboardingStepRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.green)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.green.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingGuideFallback: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.13),
                    Color(red: 0.02, green: 0.03, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.66))
                .padding(42)

            VStack(spacing: 14) {
                Image(systemName: "display")
                    .font(.system(size: 46, weight: .medium))
                Text("00:42")
                    .font(.system(size: 46, weight: .light, design: .monospaced))
            }
            .foregroundStyle(Color.green.opacity(0.78))
        }
    }
}
