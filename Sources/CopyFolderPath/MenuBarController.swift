import AppKit
import CopyFolderPathCore

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let coordinator: HotKeyCoordinator
    private let launchAtLoginManager: LaunchAtLoginManaging
    private let toastPresenter: ToastPresenting
    private let settingsOpener: SettingsOpening

    private let statusMenuItem = NSMenuItem()
    private let shortcutMenuItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()
    private let launchAtLoginDetailItem = NSMenuItem()

    init(
        coordinator: HotKeyCoordinator,
        launchAtLoginManager: LaunchAtLoginManaging,
        toastPresenter: ToastPresenting,
        settingsOpener: SettingsOpening = SystemSettingsOpener()
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.coordinator = coordinator
        self.launchAtLoginManager = launchAtLoginManager
        self.toastPresenter = toastPresenter
        self.settingsOpener = settingsOpener

        super.init()

        configureStatusButton()
        configureMenu()
        refresh()
    }

    func refresh() {
        let state = MenuBarState.current(
            hotKeyState: coordinator.state,
            launchAtLoginStatus: launchAtLoginManager.status
        )

        statusMenuItem.title = state.statusTitle
        shortcutMenuItem.title = state.statusDetailTitle
        launchAtLoginItem.state = state.launchAtLoginState.controlStateValue
        launchAtLoginItem.isEnabled = launchAtLoginManager.status != .unavailable
        launchAtLoginDetailItem.title = state.launchAtLoginDetailTitle

        statusItem.button?.toolTip = state.statusTitle
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        if let image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "Copy Folder Path"
        ) {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "Path"
        }

        button.toolTip = "Copy Folder Path"
    }

    private func configureMenu() {
        let menu = NSMenu(title: "Copy Folder Path")
        menu.delegate = self

        statusMenuItem.isEnabled = false
        shortcutMenuItem.isEnabled = false
        launchAtLoginDetailItem.isEnabled = false

        launchAtLoginItem.title = "Launch at Login"
        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin)

        menu.addItem(statusMenuItem)
        menu.addItem(shortcutMenuItem)
        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Test Toast", action: #selector(testToast)))
        menu.addItem(launchAtLoginItem)
        menu.addItem(launchAtLoginDetailItem)
        menu.addItem(actionItem(title: "Open Login Items Settings...", action: #selector(openLoginItemsSettings)))
        menu.addItem(actionItem(title: "Open Automation Settings...", action: #selector(openAutomationSettings)))
        menu.addItem(.separator())
        menu.addItem(actionItem(title: "About Copy Folder Path", action: #selector(showAbout)))
        menu.addItem(actionItem(title: "Quit Copy Folder Path", action: #selector(quit)))

        statusItem.menu = menu
    }

    private func actionItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func testToast() {
        toastPresenter.show(.copied(pathCount: 1))
    }

    @objc private func toggleLaunchAtLogin() {
        let currentStatus = launchAtLoginManager.status

        if currentStatus == .requiresApproval {
            settingsOpener.openLoginItemsSettings()
            refresh()
            return
        }

        let shouldEnable = currentStatus != .enabled

        do {
            try launchAtLoginManager.setEnabled(shouldEnable)
            refresh()
        } catch {
            toastPresenter.show(.failed(String(describing: error)))
            refresh()
        }
    }

    @objc private func openLoginItemsSettings() {
        settingsOpener.openLoginItemsSettings()
    }

    @objc private func openAutomationSettings() {
        settingsOpener.openAutomationSettings()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

protocol SettingsOpening {
    func openLoginItemsSettings()
    func openAutomationSettings()
}

final class SystemSettingsOpener: SettingsOpening {
    func openLoginItemsSettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.LoginItems-Settings.extension")
    }

    func openAutomationSettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }

    private func openSystemSettings(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private extension MenuItemCheckState {
    var controlStateValue: NSControl.StateValue {
        switch self {
        case .off:
            return .off
        case .on:
            return .on
        case .mixed:
            return .mixed
        }
    }
}
