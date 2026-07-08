# Implementation Plan

Status: complete
Date: 2026-07-08

## Tasks

### task-001 - SwiftPM Skeleton And Build Script

- Status: complete
- Type: `[implement]`
- Requirements: REQ-007
- Owned files: `Package.swift`, `.gitignore`, `Resources/Info.plist`, `Scripts/build-app.sh`, `Sources/CopyFolderPath/main.swift`
- Forbidden files: none
- Quality gate: `swift run CopyFolderPathTests && Scripts/build-app.sh`

### task-002 - Core Path And Clipboard Behavior

- Status: complete
- Type: `[implement]`
- Requirements: REQ-002, REQ-003, REQ-005, REQ-006
- Owned files: `Sources/CopyFolderPathCore/PathNormalizer.swift`, `PasteboardWriter.swift`, `FinderSelectionProvider.swift`, `CopyPathCommand.swift`, matching tests
- Forbidden files: `ToastPresenter.swift`, `HotKeyRegistrar.swift`
- Quality gates: `swift run CopyFolderPathTests --filter PathNormalizerTests`, `swift run CopyFolderPathTests --filter FinderSelectionCopyTests`, `swift run CopyFolderPathTests --filter EmptySelectionTests`, `swift run CopyFolderPathTests --filter AutomationPermissionTests`

### task-003 - Hotkey Coordination

- Status: complete
- Type: `[implement]`
- Requirements: REQ-001
- Owned files: `Sources/CopyFolderPathCore/HotKeyCoordinator.swift`, `HotKeyRegistrar.swift`, matching tests
- Forbidden files: command and toast files unless integration requires a small protocol adjustment
- Quality gate: `swift run CopyFolderPathTests --filter HotKeyRegistrarTests`

### task-004 - Non-Activating Toast

- Status: complete
- Type: `[implement]`
- Requirements: REQ-004
- Owned files: `Sources/CopyFolderPathCore/ToastPresenter.swift`, matching tests
- Forbidden files: hotkey files
- Quality gate: `swift run CopyFolderPathTests --filter ToastPanelTests`

### task-005 - Wire App And Verify

- Status: complete
- Type: `[implement]`
- Requirements: REQ-001 through REQ-007
- Owned files: `Sources/CopyFolderPath/main.swift`
- Forbidden files: tests unless final wiring exposes a missing edge case
- Quality gate: `swift run CopyFolderPathTests && Scripts/build-app.sh`

### task-006 - Menu Bar Utility Controls

- Status: complete
- Type: `[implement]`
- Requirements: REQ-010, REQ-011
- Owned files: `Sources/CopyFolderPath/main.swift`, `Sources/CopyFolderPath/MenuBarController.swift`, `Sources/CopyFolderPathCore/LaunchAtLogin.swift`, `Sources/CopyFolderPathCore/MenuBarState.swift`, `TestHarness/CopyFolderPathTests/main.swift`, `README.md`, `SPEC.md`, `progress/context.md`, `progress/plan.md`
- Forbidden files: path normalization, Finder selection, pasteboard, and hotkey registrar internals unless verification exposes a direct integration issue
- Quality gate: `swift run CopyFolderPathTests && Scripts/build-app.sh`

### task-007 - App Icon And Packaging

- Status: complete
- Type: `[implement]`
- Requirements: REQ-007
- Owned files: `Resources/AppIconSource.png`, `Resources/AppIcon.iconset`, `Resources/AppIcon.icns`, `Scripts/generate-app-icon.swift`, `Scripts/build-app.sh`, `Scripts/package-app.sh`, `Resources/Info.plist`, `README.md`, `docs/release.md`
- Forbidden files: Finder selection, pasteboard, hotkey, and toast behavior files
- Quality gate: `swift Scripts/generate-app-icon.swift && swift run CopyFolderPathTests && Scripts/package-app.sh`
