import AppKit
import CopyFolderPathCore
import Foundation

struct TestCase {
    let suite: String
    let name: String
    let run: () throws -> Void

    var fullName: String {
        "\(suite).\(name)"
    }
}

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure.failed(message)
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw TestFailure.failed("\(message). Expected \(expected), got \(actual)")
    }
}

let tests: [TestCase] = [
    TestCase(suite: "PathNormalizerTests", name: "leavesFilePathUnchanged") {
        let normalizer = PathNormalizer()
        let url = URL(fileURLWithPath: "/Users/andreas/Desktop/file.txt")

        try expectEqual(
            try normalizer.displayPath(for: url),
            "/Users/andreas/Desktop/file.txt",
            "File path should be unchanged"
        )
    },
    TestCase(suite: "PathNormalizerTests", name: "removesTrailingSlashFromNonRootFolder") {
        let normalizer = PathNormalizer()
        let url = URL(string: "file:///Users/andreas/Desktop/Folder/")!

        try expectEqual(
            try normalizer.displayPath(for: url),
            "/Users/andreas/Desktop/Folder",
            "Folder path should not keep trailing slash"
        )
    },
    TestCase(suite: "PathNormalizerTests", name: "keepsRootSlash") {
        let normalizer = PathNormalizer()

        try expectEqual(
            try normalizer.displayPath(for: URL(fileURLWithPath: "/")),
            "/",
            "Root path should stay slash"
        )
    },
    TestCase(suite: "PathNormalizerTests", name: "rejectsNonFileURL") {
        let normalizer = PathNormalizer()

        do {
            _ = try normalizer.displayPath(for: URL(string: "https://example.com/file")!)
            throw TestFailure.failed("Expected non-file URL to throw")
        } catch PathNormalizationError.nonFileURL("https://example.com/file") {
        }
    },
    TestCase(suite: "FinderSelectionCopyTests", name: "copiesNewlineSeparatedFinderPaths") {
        let provider = StubSelectionProvider(result: .success([
            URL(fileURLWithPath: "/tmp/a.txt"),
            URL(string: "file:///tmp/Folder/")!
        ]))
        let pasteboard = SpyPasteboardWriter()
        let toast = SpyToastPresenter()
        let command = CopyPathCommand(
            selectionProvider: provider,
            pasteboardWriter: pasteboard,
            toastPresenter: toast
        )

        let result = command.run()

        try expectEqual(result, .copied(paths: ["/tmp/a.txt", "/tmp/Folder"]), "Copy result mismatch")
        try expectEqual(pasteboard.writtenString, "/tmp/a.txt\n/tmp/Folder", "Pasteboard text mismatch")
        try expectEqual(toast.shownKinds, [.copied(pathCount: 2)], "Toast mismatch")
    },
    TestCase(suite: "EmptySelectionTests", name: "emptySelectionLeavesClipboardUnchanged") {
        let provider = StubSelectionProvider(result: .success([]))
        let pasteboard = SpyPasteboardWriter()
        let toast = SpyToastPresenter()
        let command = CopyPathCommand(
            selectionProvider: provider,
            pasteboardWriter: pasteboard,
            toastPresenter: toast
        )

        let result = command.run()

        try expectEqual(result, .noSelection, "Empty selection result mismatch")
        try expect(pasteboard.writtenString == nil, "Clipboard should not be written")
        try expectEqual(pasteboard.writeCount, 0, "Pasteboard write count mismatch")
        try expectEqual(toast.shownKinds, [.noSelection], "Toast mismatch")
    },
    TestCase(suite: "AutomationPermissionTests", name: "automationDeniedLeavesClipboardUnchanged") {
        let provider = StubSelectionProvider(result: .failure(
            FinderSelectionError.automationDenied(message: "Not authorized to send Apple events to Finder.")
        ))
        let pasteboard = SpyPasteboardWriter()
        let toast = SpyToastPresenter()
        let command = CopyPathCommand(
            selectionProvider: provider,
            pasteboardWriter: pasteboard,
            toastPresenter: toast
        )

        let result = command.run()

        try expectEqual(
            result,
            .permissionDenied("Not authorized to send Apple events to Finder."),
            "Permission result mismatch"
        )
        try expect(pasteboard.writtenString == nil, "Clipboard should not be written")
        try expectEqual(pasteboard.writeCount, 0, "Pasteboard write count mismatch")
        try expectEqual(toast.shownKinds, [.permissionDenied], "Toast mismatch")
    },
    TestCase(suite: "HotKeyRegistrarTests", name: "registersOnlyWhenFinderIsFrontmost") {
        let frontmost = FakeFrontmostApplicationProvider()
        let registrar = FakeHotKeyRegistrar()
        let runner = SpyCommandRunner()
        let coordinator = HotKeyCoordinator(
            frontmostApplicationProvider: frontmost,
            hotKeyRegistrar: registrar,
            commandRunner: runner
        )

        frontmost.frontmostBundleIdentifier = HotKeyCoordinator.finderBundleIdentifier
        coordinator.refresh()

        try expectEqual(coordinator.state, .active, "Coordinator should be active")
        try expectEqual(registrar.registerCallCount, 1, "Register call count mismatch")

        frontmost.frontmostBundleIdentifier = "com.apple.TextEdit"
        coordinator.refresh()

        try expectEqual(coordinator.state, .inactive, "Coordinator should be inactive")
        try expectEqual(registrar.unregisterCallCount, 1, "Unregister call count mismatch")
    },
    TestCase(suite: "HotKeyRegistrarTests", name: "hotKeyHandlerRechecksFinderBeforeRunningCommand") {
        let frontmost = FakeFrontmostApplicationProvider()
        let registrar = FakeHotKeyRegistrar()
        let runner = SpyCommandRunner()
        let coordinator = HotKeyCoordinator(
            frontmostApplicationProvider: frontmost,
            hotKeyRegistrar: registrar,
            commandRunner: runner
        )

        frontmost.frontmostBundleIdentifier = HotKeyCoordinator.finderBundleIdentifier
        coordinator.refresh()
        frontmost.frontmostBundleIdentifier = "com.apple.TextEdit"
        registrar.trigger()

        try expectEqual(runner.runCount, 0, "Command should not run outside Finder")

        frontmost.frontmostBundleIdentifier = HotKeyCoordinator.finderBundleIdentifier
        registrar.trigger()

        try expectEqual(runner.runCount, 1, "Command should run in Finder")
    },
    TestCase(suite: "HotKeyRegistrarTests", name: "registrationFailureIsReported") {
        let frontmost = FakeFrontmostApplicationProvider()
        let registrar = FakeHotKeyRegistrar()
        registrar.errorToThrow = HotKeyRegistrationError(status: -9876)
        let runner = SpyCommandRunner()
        let coordinator = HotKeyCoordinator(
            frontmostApplicationProvider: frontmost,
            hotKeyRegistrar: registrar,
            commandRunner: runner
        )

        frontmost.frontmostBundleIdentifier = HotKeyCoordinator.finderBundleIdentifier
        coordinator.refresh()

        try expectEqual(coordinator.state, .failed(-9876), "Failure state mismatch")
        try expectEqual(runner.runCount, 0, "Command should not run")
    },
    TestCase(suite: "MenuBarStateTests", name: "activeFinderShowsReadyAndLaunchAtLoginEnabled") {
        let state = MenuBarState.current(
            hotKeyState: .active,
            launchAtLoginStatus: .enabled
        )

        try expectEqual(state.statusTitle, "Status: Ready in Finder", "Status title mismatch")
        try expectEqual(state.statusDetailTitle, "Shortcut: Shift-Command-C in Finder", "Status detail mismatch")
        try expectEqual(state.launchAtLoginState, .on, "Launch at login check state mismatch")
        try expectEqual(state.launchAtLoginDetailTitle, "Launch at Login: On", "Launch detail mismatch")
    },
    TestCase(suite: "MenuBarStateTests", name: "inactiveFinderShowsWaitingAndLaunchAtLoginDisabled") {
        let state = MenuBarState.current(
            hotKeyState: .inactive,
            launchAtLoginStatus: .disabled
        )

        try expectEqual(state.statusTitle, "Status: Waiting for Finder", "Status title mismatch")
        try expectEqual(state.launchAtLoginState, .off, "Launch at login check state mismatch")
        try expectEqual(state.launchAtLoginDetailTitle, "Launch at Login: Off", "Launch detail mismatch")
    },
    TestCase(suite: "MenuBarStateTests", name: "failureAndApprovalNeedAreVisible") {
        let state = MenuBarState.current(
            hotKeyState: .failed(-9876),
            launchAtLoginStatus: .requiresApproval
        )

        try expectEqual(state.statusTitle, "Status: Hotkey unavailable (-9876)", "Status title mismatch")
        try expectEqual(state.launchAtLoginState, .mixed, "Launch at login check state mismatch")
        try expectEqual(
            state.launchAtLoginDetailTitle,
            "Launch at Login: Needs approval in System Settings",
            "Launch detail mismatch"
        )
    },
    TestCase(suite: "MenuBarStateTests", name: "unavailableLaunchAtLoginIsVisible") {
        let state = MenuBarState.current(
            hotKeyState: .active,
            launchAtLoginStatus: .unavailable
        )

        try expectEqual(state.launchAtLoginState, .off, "Launch at login check state mismatch")
        try expectEqual(state.launchAtLoginDetailTitle, "Launch at Login: Unavailable", "Launch detail mismatch")
    },
    TestCase(suite: "LaunchAtLoginManagerTests", name: "enableRegistersOnlyWhenDisabled") {
        let service = FakeLaunchAtLoginService(status: .disabled)
        let manager = MainAppLaunchAtLoginManager(service: service)

        try manager.setEnabled(true)

        try expectEqual(service.registerCallCount, 1, "Register call count mismatch")
        try expectEqual(service.unregisterCallCount, 0, "Unregister call count mismatch")
    },
    TestCase(suite: "LaunchAtLoginManagerTests", name: "enableNoopsWhenAlreadyEnabled") {
        let service = FakeLaunchAtLoginService(status: .enabled)
        let manager = MainAppLaunchAtLoginManager(service: service)

        try manager.setEnabled(true)

        try expectEqual(service.registerCallCount, 0, "Register call count mismatch")
        try expectEqual(service.unregisterCallCount, 0, "Unregister call count mismatch")
    },
    TestCase(suite: "LaunchAtLoginManagerTests", name: "disableUnregistersOnlyWhenEnabled") {
        let service = FakeLaunchAtLoginService(status: .enabled)
        let manager = MainAppLaunchAtLoginManager(service: service)

        try manager.setEnabled(false)

        try expectEqual(service.registerCallCount, 0, "Register call count mismatch")
        try expectEqual(service.unregisterCallCount, 1, "Unregister call count mismatch")
    },
    TestCase(suite: "LaunchAtLoginManagerTests", name: "disableNoopsWhenAlreadyDisabled") {
        let service = FakeLaunchAtLoginService(status: .disabled)
        let manager = MainAppLaunchAtLoginManager(service: service)

        try manager.setEnabled(false)

        try expectEqual(service.registerCallCount, 0, "Register call count mismatch")
        try expectEqual(service.unregisterCallCount, 0, "Unregister call count mismatch")
    },
    TestCase(suite: "LaunchAtLoginManagerTests", name: "serviceErrorsPropagate") {
        let service = FakeLaunchAtLoginService(status: .disabled)
        service.registerError = TestFailure.failed("register failed")
        let manager = MainAppLaunchAtLoginManager(service: service)

        do {
            try manager.setEnabled(true)
            throw TestFailure.failed("Expected register failure")
        } catch TestFailure.failed("register failed") {
        }
    },
    TestCase(suite: "ToastPanelTests", name: "toastPanelCannotBecomeKeyOrMain") {
        let panel = AppKitToastPresenter.makePanelForTesting()

        try expect(!panel.canBecomeKey, "Panel should not become key")
        try expect(!panel.canBecomeMain, "Panel should not become main")
        try expect(panel.styleMask.contains(.nonactivatingPanel), "Panel should be non-activating")
        try expect(panel.ignoresMouseEvents, "Panel should ignore mouse events")
        try expect(!panel.hidesOnDeactivate, "Panel should not hide on deactivate")
        try expectEqual(panel.level, .statusBar, "Panel should appear above the active app")
    }
]

let filter = commandLineFilter()
let selectedTests = tests.filter { test in
    guard let filter else {
        return true
    }

    return test.suite.contains(filter) || test.name.contains(filter) || test.fullName.contains(filter)
}

if selectedTests.isEmpty {
    print("No tests matched filter \(filter ?? "")")
    exit(1)
}

var failureCount = 0

for test in selectedTests {
    do {
        try test.run()
        print("PASS \(test.fullName)")
    } catch {
        failureCount += 1
        print("FAIL \(test.fullName): \(error)")
    }
}

if failureCount > 0 {
    print("\(failureCount) test(s) failed")
    exit(1)
}

if let filter {
    print("All \(filter) tests passed")
} else {
    print("All \(selectedTests.count) tests passed")
}

private func commandLineFilter() -> String? {
    let arguments = CommandLine.arguments

    guard let filterIndex = arguments.firstIndex(of: "--filter") else {
        return nil
    }

    let valueIndex = arguments.index(after: filterIndex)
    guard valueIndex < arguments.endIndex else {
        return nil
    }

    return arguments[valueIndex]
}

private final class StubSelectionProvider: FinderSelectionProviding {
    private let result: Result<[URL], Error>

    init(result: Result<[URL], Error>) {
        self.result = result
    }

    func selectedFileURLs() throws -> [URL] {
        try result.get()
    }
}

private final class SpyPasteboardWriter: PasteboardWriting {
    private(set) var writtenString: String?
    private(set) var writeCount = 0

    func writeString(_ string: String) throws {
        writeCount += 1
        writtenString = string
    }
}

private final class SpyToastPresenter: ToastPresenting {
    private(set) var shownKinds: [ToastKind] = []

    func show(_ kind: ToastKind) {
        shownKinds.append(kind)
    }
}

private final class FakeFrontmostApplicationProvider: FrontmostApplicationProviding {
    var frontmostBundleIdentifier: String?
}

private final class FakeHotKeyRegistrar: HotKeyRegistering {
    private(set) var isRegistered = false
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    var errorToThrow: Error?

    private var handler: (() -> Void)?

    func register(handler: @escaping () -> Void) throws {
        registerCallCount += 1

        if let errorToThrow {
            throw errorToThrow
        }

        self.handler = handler
        isRegistered = true
    }

    func unregister() {
        unregisterCallCount += 1
        handler = nil
        isRegistered = false
    }

    func trigger() {
        handler?()
    }
}

private final class SpyCommandRunner: CopyPathRunning {
    private(set) var runCount = 0

    func run() -> CopyPathResult {
        runCount += 1
        return .noSelection
    }
}

private final class FakeLaunchAtLoginService: LaunchAtLoginService {
    var status: LaunchAtLoginStatus
    var registerError: Error?
    var unregisterError: Error?
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1

        if let registerError {
            throw registerError
        }

        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1

        if let unregisterError {
            throw unregisterError
        }

        status = .disabled
    }
}
