import Foundation

public enum MenuItemCheckState: Equatable {
    case off
    case on
    case mixed
}

public struct MenuBarState: Equatable {
    public let statusTitle: String
    public let statusDetailTitle: String
    public let launchAtLoginState: MenuItemCheckState
    public let launchAtLoginDetailTitle: String

    public init(
        statusTitle: String,
        statusDetailTitle: String,
        launchAtLoginState: MenuItemCheckState,
        launchAtLoginDetailTitle: String
    ) {
        self.statusTitle = statusTitle
        self.statusDetailTitle = statusDetailTitle
        self.launchAtLoginState = launchAtLoginState
        self.launchAtLoginDetailTitle = launchAtLoginDetailTitle
    }

    public static func current(
        hotKeyState: HotKeyCoordinator.State,
        launchAtLoginStatus: LaunchAtLoginStatus
    ) -> MenuBarState {
        MenuBarState(
            statusTitle: statusTitle(for: hotKeyState),
            statusDetailTitle: "Shortcut: Shift-Command-C in Finder",
            launchAtLoginState: launchAtLoginCheckState(for: launchAtLoginStatus),
            launchAtLoginDetailTitle: launchAtLoginDetailTitle(for: launchAtLoginStatus)
        )
    }

    private static func statusTitle(for state: HotKeyCoordinator.State) -> String {
        switch state {
        case .active:
            return "Status: Ready in Finder"
        case .inactive:
            return "Status: Waiting for Finder"
        case .failed(let status):
            return "Status: Hotkey unavailable (\(status))"
        }
    }

    private static func launchAtLoginCheckState(for status: LaunchAtLoginStatus) -> MenuItemCheckState {
        switch status {
        case .enabled:
            return .on
        case .requiresApproval:
            return .mixed
        case .disabled, .unavailable:
            return .off
        }
    }

    private static func launchAtLoginDetailTitle(for status: LaunchAtLoginStatus) -> String {
        switch status {
        case .disabled:
            return "Launch at Login: Off"
        case .enabled:
            return "Launch at Login: On"
        case .requiresApproval:
            return "Launch at Login: Needs approval in System Settings"
        case .unavailable:
            return "Launch at Login: Unavailable"
        }
    }
}
