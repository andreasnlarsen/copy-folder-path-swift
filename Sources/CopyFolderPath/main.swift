import AppKit
import CopyFolderPathCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let previewToast: Bool
    private var toastPresenter: AppKitToastPresenter?
    private var coordinator: HotKeyCoordinator?
    private var menuBarController: MenuBarController?
    private var activationObserver: NSObjectProtocol?

    init(previewToast: Bool) {
        self.previewToast = previewToast
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let toastPresenter = AppKitToastPresenter(
            visibleDuration: previewToast
                ? AppKitToastPresenter.Timing.previewVisibleDuration
                : AppKitToastPresenter.Timing.defaultVisibleDuration
        )
        self.toastPresenter = toastPresenter

        if previewToast {
            toastPresenter.show(.copied(pathCount: 1))
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                NSApp.terminate(nil)
            }
            return
        }

        do {
            let command = CopyPathCommand(
                selectionProvider: try AppleScriptFinderSelectionProvider(),
                pasteboardWriter: SystemPasteboardWriter(),
                toastPresenter: toastPresenter
            )
            let coordinator = HotKeyCoordinator(
                frontmostApplicationProvider: WorkspaceFrontmostApplicationProvider(),
                hotKeyRegistrar: CarbonHotKeyRegistrar(),
                commandRunner: command
            )
            self.coordinator = coordinator

            let menuBarController = MenuBarController(
                coordinator: coordinator,
                launchAtLoginManager: MainAppLaunchAtLoginManager(),
                toastPresenter: toastPresenter
            )
            self.menuBarController = menuBarController

            activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak coordinator, weak menuBarController] _ in
                coordinator?.refresh()
                menuBarController?.refresh()
            }

            coordinator.refresh()
            menuBarController.refresh()
        } catch {
            toastPresenter.show(.failed(String(describing: error)))
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate(previewToast: CommandLine.arguments.contains("--preview-toast"))
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
