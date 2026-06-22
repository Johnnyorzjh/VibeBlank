import Foundation
import ServiceManagement

enum LoginItemSyncStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case notFound
    case failed(String)

    var displayName: String {
        switch self {
        case .enabled:
            return "登录时启动已开启"
        case .disabled:
            return "登录时启动已关闭"
        case .requiresApproval:
            return "需要在系统设置中允许登录项"
        case .notFound:
            return "未找到登录项服务"
        case .failed(let message):
            return "登录项同步失败：\(message)"
        }
    }
}

@MainActor
final class LoginItemController {
    func sync(isEnabled: Bool) -> LoginItemSyncStatus {
        let service = SMAppService.mainApp

        do {
            if isEnabled {
                switch service.status {
                case .enabled:
                    return .enabled
                case .requiresApproval:
                    return .requiresApproval
                default:
                    try service.register()
                    return status(for: service.status)
                }
            } else {
                if service.status != .notRegistered {
                    try service.unregister()
                }
                return .disabled
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func status() -> LoginItemSyncStatus {
        status(for: SMAppService.mainApp.status)
    }

    private func status(for serviceStatus: SMAppService.Status) -> LoginItemSyncStatus {
        switch serviceStatus {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            return .failed("未知状态")
        }
    }
}
