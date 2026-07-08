# Engineering Context

Status: complete
Date: 2026-07-08

## Scope

Implement P0 plus the menu-bar/launch-at-login Phase 2 slice from `SPEC.md`:

- REQ-001 Finder-scoped dynamic hotkey ownership.
- REQ-002 Copy selected Finder paths.
- REQ-003 Preserve path formatting behavior.
- REQ-004 Non-activating native toast.
- REQ-005 Empty selection leaves clipboard unchanged.
- REQ-006 Permission denial handling.
- REQ-007 Command Line Tools build and test path.
- REQ-010 Launch at login.
- REQ-011 Menu-bar status item.

## Planned Files

- `Package.swift`
- `Sources/CopyFolderPathCore/`
- `Sources/CopyFolderPath/main.swift`
- `Sources/CopyFolderPath/MenuBarController.swift`
- `Sources/CopyFolderPathCore/LaunchAtLogin.swift`
- `Sources/CopyFolderPathCore/MenuBarState.swift`
- `TestHarness/CopyFolderPathTests/`
- `Resources/Info.plist`
- `Resources/AppIconSource.png`
- `Resources/AppIcon.iconset`
- `Resources/AppIcon.icns`
- `Scripts/build-app.sh`
- `Scripts/generate-app-icon.swift`
- `Scripts/package-app.sh`

## Ownership Boundaries

| Requirement | Canonical owner files | Quality gate |
|-------------|-----------------------|--------------|
| REQ-001 | `HotKeyCoordinator.swift`, `HotKeyRegistrar.swift` | `swift run CopyFolderPathTests --filter HotKeyRegistrarTests` |
| REQ-002 | `FinderSelectionProvider.swift`, `CopyPathCommand.swift`, `PasteboardWriter.swift` | `swift run CopyFolderPathTests --filter FinderSelectionCopyTests` |
| REQ-003 | `PathNormalizer.swift` | `swift run CopyFolderPathTests --filter PathNormalizerTests` |
| REQ-004 | `ToastPresenter.swift` | `swift run CopyFolderPathTests --filter ToastPanelTests` |
| REQ-005 | `CopyPathCommand.swift` | `swift run CopyFolderPathTests --filter EmptySelectionTests` |
| REQ-006 | `FinderSelectionProvider.swift`, `CopyPathCommand.swift` | `swift run CopyFolderPathTests --filter AutomationPermissionTests` |
| REQ-007 | `Package.swift`, `Scripts/build-app.sh`, `Resources/Info.plist` | `swift run CopyFolderPathTests && Scripts/build-app.sh` |
| REQ-010 | `LaunchAtLogin.swift`, `MenuBarController.swift` | `swift run CopyFolderPathTests --filter LaunchAtLoginManagerTests` |
| REQ-011 | `MenuBarState.swift`, `MenuBarController.swift`, `main.swift` | `swift run CopyFolderPathTests --filter MenuBarStateTests` |
| REQ-013 | `Resources/AppIconSource.png`, `Resources/AppIcon.icns`, `Scripts/generate-app-icon.swift`, `Scripts/package-app.sh` | `Scripts/package-app.sh && codesign --verify --deep --strict build/CopyFolderPath.app` |

## Naming

- Finder selection: file URLs returned by Finder.
- Display path: normalized POSIX path written as text.
- Hotkey ownership: current registration state for `Shift-Command-C`.
- Toast: non-activating AppKit panel.
- Menu-bar status: current hotkey and launch-at-login projection displayed from the status item.
- Launch at login: `SMAppService.mainApp` wrapper behind protocol-backed tests.
- Local package: ad-hoc signed `.app` and zip generated under ignored `build/`.
- App icon: selected raster source plus generated `.icns` copied into the bundle.

## Verification Notes

Default tests should not mutate login items or require live Finder selection. OS integrations must have protocol-backed fakes for unit tests. This Mac's Command Line Tools do not expose `XCTest` or Swift `Testing`, so the repo uses `CopyFolderPathTests`, a small executable test runner. Generated build products and release zips stay ignored under `build/`.
