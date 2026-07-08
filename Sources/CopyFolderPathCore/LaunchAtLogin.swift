import Foundation
import ServiceManagement

public enum LaunchAtLoginStatus: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable

    public var isEnabled: Bool {
        self == .enabled
    }
}

public protocol LaunchAtLoginManaging: AnyObject {
    var status: LaunchAtLoginStatus { get }
    func setEnabled(_ isEnabled: Bool) throws
}

public protocol LaunchAtLoginService: AnyObject {
    var status: LaunchAtLoginStatus { get }
    func register() throws
    func unregister() throws
}

public final class MainAppLaunchAtLoginManager: LaunchAtLoginManaging {
    private let service: LaunchAtLoginService

    public var status: LaunchAtLoginStatus {
        service.status
    }

    public convenience init() {
        self.init(service: MainAppLaunchAtLoginService())
    }

    public init(service: LaunchAtLoginService) {
        self.service = service
    }

    public func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            guard status != .enabled else {
                return
            }

            try service.register()
            return
        }

        guard status != .disabled else {
            return
        }

        try service.unregister()
    }
}

public final class MainAppLaunchAtLoginService: LaunchAtLoginService {
    public init() {}

    public var status: LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    public func register() throws {
        try SMAppService.mainApp.register()
    }

    public func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}
