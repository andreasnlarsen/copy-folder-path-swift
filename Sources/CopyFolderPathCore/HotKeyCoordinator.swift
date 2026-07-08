import AppKit
import Foundation

public protocol FrontmostApplicationProviding: AnyObject {
    var frontmostBundleIdentifier: String? { get }
}

public final class WorkspaceFrontmostApplicationProvider: FrontmostApplicationProviding {
    public init() {}

    public var frontmostBundleIdentifier: String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}

public final class HotKeyCoordinator {
    public enum State: Equatable {
        case inactive
        case active
        case failed(OSStatus)
    }

    public static let finderBundleIdentifier = "com.apple.finder"

    private let frontmostApplicationProvider: FrontmostApplicationProviding
    private let hotKeyRegistrar: HotKeyRegistering
    private let commandRunner: CopyPathRunning

    public private(set) var state: State = .inactive

    public init(
        frontmostApplicationProvider: FrontmostApplicationProviding,
        hotKeyRegistrar: HotKeyRegistering,
        commandRunner: CopyPathRunning
    ) {
        self.frontmostApplicationProvider = frontmostApplicationProvider
        self.hotKeyRegistrar = hotKeyRegistrar
        self.commandRunner = commandRunner
    }

    public func refresh() {
        update(frontmostBundleIdentifier: frontmostApplicationProvider.frontmostBundleIdentifier)
    }

    public func update(frontmostBundleIdentifier: String?) {
        guard frontmostBundleIdentifier == Self.finderBundleIdentifier else {
            hotKeyRegistrar.unregister()
            state = .inactive
            return
        }

        guard !hotKeyRegistrar.isRegistered else {
            state = .active
            return
        }

        do {
            try hotKeyRegistrar.register { [weak self] in
                self?.handleHotKey()
            }
            state = .active
        } catch let error as HotKeyRegistrationError {
            state = .failed(error.status)
        } catch {
            state = .failed(-1)
        }
    }

    public func handleHotKey() {
        guard frontmostApplicationProvider.frontmostBundleIdentifier == Self.finderBundleIdentifier else {
            return
        }

        commandRunner.run()
    }
}
