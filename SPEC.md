# SPEC.md

## Spec Metadata

- **Title:** Copy Folder Path macOS Utility
- **Project / Repo:** `/Users/andreas/Code/copy-folder-path-swift`
- **Status:** `Working local version packaged and installed`
- **Last Updated:** 2026-07-08
- **Active Artifact:** `SPEC.md`
- **Archive Location When Superseded:** `archive/specs/`
- **Historical Artifacts:** `archive/specs/` (historical only; not the active spec)

## 1. Goal

Build a native macOS Swift utility that copies the POSIX paths of selected Finder items with `Shift-Command-C` and shows a brief confirmation toast without stealing focus from Finder or bringing unrelated Finder windows forward.

## 2. Non-Goals

- No general-purpose Keyboard Maestro replacement.
- No Finder file operations beyond reading the current selection.
- No App Store distribution for MVP.
- No cloud sync, analytics, or telemetry.

## 3. Target Users

| User Type | Description | Primary Need |
|-----------|-------------|--------------|
| Primary user | Andreas using Finder-heavy local workflows | Copy selected file/folder paths quickly without Finder window disruption |

## 4. User Stories / Behaviors

- [x] US-1: As the primary user, I want `Shift-Command-C` in Finder to copy selected item paths so that I can paste paths into terminals, editors, and agent prompts.
- [x] US-2: As the primary user, I want a brief visual confirmation so that I know the copy happened.
- [x] US-3: As the primary user, I want the confirmation to avoid taking focus so that my frontmost Finder window stack stays unchanged.
- [x] US-4: As the primary user, I want no action when Finder is not frontmost so that the utility does not interfere with other apps.

## 5. Requirements

### P0 - Must Have

| ID | Requirement | Acceptance Criterion |
|----|-------------|---------------------|
| REQ-001 | Register `Shift-Command-C` only while Finder is frontmost. | When Finder is frontmost, the app owns the hotkey; when another app is frontmost, the app unregisters the hotkey within 250 ms. |
| REQ-002 | Copy selected Finder item paths to the system clipboard. | For one or more selected Finder items, the clipboard contains one normalized POSIX path per line within 250 ms of the hotkey handler starting. |
| REQ-003 | Preserve folder path formatting from the current macro. | Folder paths do not end with `/` unless the selected item is `/`; file paths are unchanged. |
| REQ-004 | Show a native toast without activating the utility or Finder. | The toast appears for 450-900 ms and the frontmost application remains Finder before, during, and after the toast. |
| REQ-005 | Handle no selection without corrupting clipboard contents. | If Finder selection is empty, the existing clipboard string remains unchanged and the app emits a non-activating no-selection toast or no toast, per implementation decision. |
| REQ-006 | Report Finder Automation permission denial clearly. | If macOS denies Finder Apple Events, the app does not modify the clipboard and logs or displays a non-activating permission-denied state. |
| REQ-007 | Build and test with local Command Line Tools. | `swift run CopyFolderPathTests` and the local app-bundle/package scripts run without requiring full Xcode. |

### P1 - Should Have

| ID | Requirement | Acceptance Criterion |
|----|-------------|---------------------|
| REQ-010 | Provide launch-at-login support through `SMAppService.mainApp`. | A user-controlled setting registers/unregisters the main app as a login item and reflects `SMAppService` status. |
| REQ-011 | Provide a menu-bar status item. | The utility has a status item with Quit, About, and permission/help actions. |
| REQ-013 | Provide local app icon and packaging artifacts. | The built `.app` includes `AppIcon.icns`, and `Scripts/package-app.sh` creates `build/CopyFolderPath-0.1.0.zip`. |
| REQ-012 | Include rich pasteboard file URL items. | Apps that accept file URLs can paste selected items as URLs while plain text paste remains newline-separated POSIX paths. |

### P2 - Nice to Have

| ID | Requirement | Acceptance Criterion |
|----|-------------|---------------------|
| REQ-020 | User-configurable shortcut. | User can set a replacement shortcut in settings without editing source code. |
| REQ-021 | Signed and notarized release artifact. | A Developer ID signed `.app` passes `spctl --assess --type exec` and notarization stapling checks. |

## 6. Quality Gates

| REQ-ID | Command | Expected Output |
|--------|---------|-----------------|
| REQ-001 | `swift run CopyFolderPathTests --filter HotKeyRegistrarTests` | Test runner exits 0 and prints `All HotKeyRegistrarTests tests passed` |
| REQ-002 | `swift run CopyFolderPathTests --filter FinderSelectionCopyTests` | Test runner exits 0 and prints `All FinderSelectionCopyTests tests passed` |
| REQ-003 | `swift run CopyFolderPathTests --filter PathNormalizerTests` | Test runner exits 0 and prints `All PathNormalizerTests tests passed` |
| REQ-004 | `swift run CopyFolderPathTests --filter ToastPanelTests` | Test runner exits 0 and prints `All ToastPanelTests tests passed` |
| REQ-005 | `swift run CopyFolderPathTests --filter EmptySelectionTests` | Test runner exits 0 and prints `All EmptySelectionTests tests passed` |
| REQ-006 | `swift run CopyFolderPathTests --filter AutomationPermissionTests` | Test runner exits 0 and prints `All AutomationPermissionTests tests passed` |
| REQ-007 | `swift run CopyFolderPathTests && Scripts/package-app.sh` | Both commands exit 0; `build/CopyFolderPath.app/Contents/MacOS/CopyFolderPath` and `build/CopyFolderPath-0.1.0.zip` exist |
| REQ-010 | `swift run CopyFolderPathTests --filter LaunchAtLoginManagerTests` | Test runner exits 0 and prints `All LaunchAtLoginManagerTests tests passed` |
| REQ-011 | `swift run CopyFolderPathTests --filter MenuBarStateTests` | Test runner exits 0 and prints `All MenuBarStateTests tests passed` |
| REQ-013 | `test -f build/CopyFolderPath.app/Contents/Resources/AppIcon.icns && codesign --verify --deep --strict build/CopyFolderPath.app` | The app includes `AppIcon.icns` and passes ad-hoc signature verification |

## 7. Non-Functional Requirements

| Category | Requirement | Metric |
|----------|-------------|--------|
| Latency | Hotkey-to-clipboard path completes quickly enough for repeated Finder use. | p95 handler time under 250 ms in 100 local invocations against a prepared Finder selection. |
| Focus behavior | Toast does not change the frontmost app. | 100 consecutive toast presentations keep `NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"`. |
| Permissions | Permission failures are bounded. | Denied Automation test exits 0 with an explicit permission error and no clipboard write. |
| Footprint | Utility stays lightweight while idle. | Idle CPU below 1% over a 60-second sample; resident memory below 80 MB after startup. |

## 8. Constraints

- **Tech stack:** Swift 6, SwiftPM, AppKit, Foundation `NSAppleScript`, Carbon/HIToolbox hotkey API, ServiceManagement launch-at-login, CoreGraphics/ImageIO icon generation.
- **Timeline:** MVP should fit in 1-2 focused implementation days after spec approval.
- **Budget:** No paid third-party dependencies for MVP.
- **Other:** MVP must build with Command Line Tools because full Xcode is not selected on this Mac.
- **macOS target:** macOS 13+ hard cutover, allowing `SMAppService.mainApp` in Phase 2.

## 9. Build vs Buy Decisions

| Capability | Decision | Rationale | Changeability / Maintenance Note |
|-----------|----------|-----------|----------------------------------|
| Global hotkey | Build: direct Carbon `RegisterEventHotKey` wrapper | Fixed shortcut and Finder-scoped behavior do not need a settings UI in MVP. | Keep `HotKeyRegistrar` small so `KeyboardShortcuts` can replace it if configurable shortcuts become P0. |
| User-configurable shortcuts | Buy later: `KeyboardShortcuts` package | The package provides native recorder UI and user defaults storage. | Add only if REQ-020 is promoted. |
| Finder selection | Build: fixed `NSAppleScript` provider | It matches the known-working workflow and keeps TCC identity with the app. | Isolate behind `FinderSelectionProviding`; raw Apple Events can replace it if script execution proves brittle. |
| Toast UI | Build: AppKit `NSPanel` | Native panel directly fixes the focus issue that Keyboard Maestro HTML prompt causes. | Keep toast rendering in one presenter class. |
| Launch at login | Build: `SMAppService.mainApp` | First-party API is available on the target macOS range. | Optional `LaunchAtLogin` package only if a SwiftUI settings screen becomes valuable. |
| App icon packaging | Build: repo-owned Swift generator plus manual `.icns` packing | `iconutil` can read the generated `.icns` locally, but failed to create one from a valid iconset in this environment. | Keep `Resources/AppIconSource.png` as the editable source and regenerate with `Scripts/generate-app-icon.swift`. |

## 10. Architecture & Tech Decisions

### Decision: App Shape

- **Choice:** AppKit menu-bar utility, started as SwiftPM core plus executable/AppKit target and local `.app` bundle script.
- **Alternatives considered:** Keyboard Maestro-only repair, Finder Sync extension, CGEventTap-based utility, Xcode-only app target.
- **Rationale:** AppKit is enough for hotkey observation, pasteboard writes, Finder Apple Events, and a non-activating toast. SwiftPM keeps MVP buildable on this Mac.

### Decision: Hotkey Strategy

- **Choice:** Dynamically register an exclusive Carbon hotkey only while Finder is frontmost.
- **Alternatives considered:** Global event monitor, local event monitor, CGEventTap, app menu shortcut.
- **Rationale:** Carbon hotkeys avoid Accessibility permission and can suppress Finder's built-in `Shift-Command-C` while active. Dynamic registration limits interference outside Finder.

### Decision: Finder Selection Strategy

- **Choice:** `NSAppleScript` returns Finder selection URLs; Swift normalizes paths and writes the pasteboard.
- **Alternatives considered:** ScriptingBridge, raw Apple Events, Accessibility, Finder Sync.
- **Rationale:** This keeps the proven AppleScript selection behavior while moving formatting and clipboard policy into testable Swift code.

### Decision: Toast Strategy

- **Choice:** Retained borderless `NSPanel` subclass using `.nonactivatingPanel`, `canBecomeKey == false`, `canBecomeMain == false`, and `ignoresMouseEvents == true`.
- **Alternatives considered:** macOS notifications, sound-only feedback, Keyboard Maestro HTML prompt.
- **Rationale:** Native non-activating panel addresses the observed focus-steal behavior directly.

### Decision: Packaging Strategy

- **Choice:** `Scripts/build-app.sh` assembles and ad-hoc signs `build/CopyFolderPath.app`; `Scripts/package-app.sh` creates `build/CopyFolderPath-0.1.0.zip`.
- **Alternatives considered:** Xcode archive, notarized Developer ID release, committing generated app bundles.
- **Rationale:** The utility is for local use on this Mac today. SwiftPM plus repo-owned scripts keep the release path repeatable without full Xcode.

### Changeability / Replacement Strategy

- **Next likely change:** Add rich file URL pasteboard items after hotkey/copy/toast/menu-bar behavior is proven.
- **What makes that change local:** Hotkey registration, Finder selection, pasteboard writing, and toast presentation are separate types with protocols around OS-facing behavior.
- **Replaceable seam for uncertain areas:** `HotKeyRegistrar` can be swapped for `KeyboardShortcuts` or a CGEventTap implementation if Carbon registration fails in local testing.
- **Speculative abstractions explicitly avoided:** No plugin system, no multi-app selection framework, no generic automation engine.
- **Oversized active code decision:** Greenfield - no existing code to refactor.
- **Fallback / degradation strategy:** No silent fallback for clipboard writes. If Finder Automation is denied or hotkey registration fails, report the specific failure and do not write clipboard content.

### Domain Vocabulary / Canonical Terms

| Term | Meaning | Where it should appear |
|------|---------|------------------------|
| Finder selection | URLs returned by Finder for currently selected items | `FinderSelectionProvider`, tests, docs |
| Display path | POSIX path string written to text clipboard | `PathNormalizer`, `PasteboardWriter` |
| Toast | Non-activating AppKit confirmation panel | `ToastPresenter`, UI tests |
| Hotkey ownership | Whether the utility currently owns `Shift-Command-C` | `HotKeyRegistrar`, lifecycle tests |

### Canonical Owners

| Rule / concern | Canonical owner | Allowed readers/callers | Duplication exception |
|----------------|-----------------|-------------------------|-----------------------|
| Finder-frontmost gating | `FrontmostApplicationObserver` | `HotKeyCoordinator` | None |
| Hotkey registration | `HotKeyRegistrar` | `HotKeyCoordinator` | None |
| Finder selection retrieval | `FinderSelectionProvider` | `CopyPathCommand` | None |
| Path normalization | `PathNormalizer` | `CopyPathCommand`, tests | None |
| Clipboard write policy | `PasteboardWriter` | `CopyPathCommand` | None |
| Toast presentation | `ToastPresenter` | `CopyPathCommand`, permission handlers | None |

### Authority Map

| Business state / side effect | System of record | Authoritative mutator / finalizing path | Allowed non-authoritative paths | Exception / boundary reason |
|------------------------------|------------------|-----------------------------------------|---------------------------------|-----------------------------|
| Current Finder selection | Finder | Finder Apple Events queried by `FinderSelectionProvider` | Tests may inject fixtures | Tests must not call Finder |
| Clipboard text | macOS general pasteboard | `PasteboardWriter.write(paths:)` | Tests use fake pasteboard | None |
| Hotkey ownership | macOS Carbon hotkey registry | `HotKeyRegistrar.register/unregister` | Observer reads registration state | None |
| Toast visibility | AppKit window server | `ToastPresenter.show(...)` | Tests inspect panel properties | None |

### Boundary Rules

- **Centralize here:** Finder gating, hotkey registration, path normalization, pasteboard writes, toast presentation.
- **Keep local here:** Visual layout constants for the toast remain inside `ToastPresenter`.
- **System of record for mutable business data:** Finder owns selection; macOS pasteboard owns clipboard contents; the app owns no durable user data in MVP.
- **Split-authority prevention rule:** Only `CopyPathCommand` coordinates selection retrieval, path normalization, clipboard write, and toast result.

## 11. Lifecycle / State Model

### Lifecycle Objects / Processes

| Object / process | Why it matters | Canonical name |
|------------------|----------------|----------------|
| Hotkey ownership | Prevents shortcut interference outside Finder | HotkeyOwnership |
| Copy command | Coordinates Finder selection, clipboard write, and toast result | CopyPathCommand |
| Toast presentation | Must avoid app activation and order out after the dismiss timer | ToastPresentation |

### States

| Object / process | State | Meaning | Terminal? |
|------------------|-------|---------|-----------|
| HotkeyOwnership | inactive | Finder is not frontmost or registration has not started | No |
| HotkeyOwnership | active | Finder is frontmost and hotkey is registered | No |
| HotkeyOwnership | failed | Registration failed because of conflict or OS error | No |
| CopyPathCommand | idle | No copy command is running | No |
| CopyPathCommand | copying | Finder selection is being read and normalized | No |
| CopyPathCommand | copied | Clipboard was written | Yes |
| CopyPathCommand | noSelection | Finder returned zero selected items | Yes |
| CopyPathCommand | permissionDenied | Finder Automation permission failed | Yes |
| CopyPathCommand | failed | Non-permission error occurred | Yes |
| ToastPresentation | hidden | Panel is ordered out | No |
| ToastPresentation | visible | Panel is ordered front without key status | No |
| ToastPresentation | dismissing | Fade-out timer is running | No |

### Transitions

| Object / process | From state | To state | Trigger | Authoritative transition owner / finalizing path | Idempotency requirement | Notes |
|------------------|------------|----------|---------|-----------------------------------------------|-------------------------|-------|
| HotkeyOwnership | inactive | active | Finder becomes frontmost | `HotKeyCoordinator` calls `HotKeyRegistrar.register` | Re-registering an active hotkey is a no-op | Re-check frontmost app before registering |
| HotkeyOwnership | active | inactive | Non-Finder app becomes frontmost | `HotKeyCoordinator` calls `HotKeyRegistrar.unregister` | Unregistering inactive state is a no-op | Must complete within 250 ms |
| HotkeyOwnership | inactive | failed | Registration error | `HotKeyRegistrar` returns OSStatus | Same error should not loop-register continuously | Report conflict |
| CopyPathCommand | idle | copying | Hotkey handler fires while Finder is frontmost | `CopyPathCommand.run` | Ignore concurrent duplicate command while copying | Avoid overlapping clipboard writes |
| CopyPathCommand | copying | copied | One or more file URLs normalize successfully | `PasteboardWriter.write` | Clipboard write happens once per command | Then show success toast |
| CopyPathCommand | copying | noSelection | Finder returns empty selection | `CopyPathCommand.run` | Clipboard unchanged | Toast choice remains implementation detail |
| CopyPathCommand | copying | permissionDenied | Apple Events return permission denial | `FinderSelectionProvider` | Clipboard unchanged | Report permission state |
| ToastPresentation | hidden | visible | Copy command result requests toast | `ToastPresenter.show` | Existing toast timer resets | Never activate app |
| ToastPresentation | visible | dismissing | Hold timer expires | `ToastPresenter` timer | Timer reset is allowed | Fade duration under 200 ms |
| ToastPresentation | dismissing | hidden | Fade completes | `ToastPresenter.orderOut` | Repeated order-out is harmless | Panel retained for reuse |

### Forbidden / Invalid Transitions

| Object / process | Invalid transition | Why invalid | Expected behavior |
|------------------|--------------------|-------------|-------------------|
| CopyPathCommand | idle -> copied | Clipboard write without confirmed selection would duplicate authority | Command must enter `copying` first |
| CopyPathCommand | permissionDenied -> copied | Permission failure cannot still mutate clipboard | Clipboard remains unchanged |
| ToastPresentation | hidden -> keyWindow | Toast must never take focus | Test fails if panel can become key |
| HotkeyOwnership | active while non-Finder frontmost | Shortcut would interfere with other apps | Unregister immediately |

### Retry / Recovery Paths

| Object / process | Failure or recovery case | Authoritative path | Observational / non-authoritative path | Notes |
|------------------|--------------------------|--------------------|----------------------------------------|-------|
| HotkeyOwnership | Another app owns the hotkey | `HotKeyRegistrar` returns failure and coordinator logs state | Status menu may display failure later | No alternate key in MVP |
| CopyPathCommand | Automation denied | `FinderSelectionProvider` returns permission error | Toast/status menu can explain | User fixes in System Settings |
| ToastPresentation | New toast requested while visible | `ToastPresenter.show` resets timer and content | Tests inspect state | No stacked toasts |

### Read Models / Projections

| Read/display path | Reads from | Why it must stay non-authoritative |
|-------------------|------------|------------------------------------|
| Status menu state | Hotkey registration state and permission state | It displays status but does not own registration or permissions |
| Logs | Command results | Logs must not mutate clipboard, hotkeys, or Finder |

## 12. Data Model

```text
SelectedFinderItem
|-- url: URL (must be file URL)
|-- displayPath: String (normalized POSIX path)

CopyPathResult
|-- copied(paths: [String])
|-- noSelection
|-- permissionDenied(message: String)
|-- failed(message: String)

HotKeyState
|-- inactive
|-- active
|-- failed(osStatus: Int32)
```

## 13. Integrations

| Integration | Purpose | Auth Method | Rate Limits |
|-------------|---------|-------------|-------------|
| Finder Apple Events | Read current Finder selection | macOS Automation/TCC; `NSAppleEventsUsageDescription` required | User-mediated OS permission; no network rate limit |
| Carbon/HIToolbox | Register `Shift-Command-C` hotkey | Process-level macOS API | One active registration per app/shortcut |
| AppKit | Pasteboard and non-activating toast | Local process APIs | No network rate limit |
| ServiceManagement | Launch at login | Code-signed app using `SMAppService.mainApp` | User/system approval status |
| CoreGraphics/ImageIO | Generate PNG icon slots and `.icns` bundle icon | Local process APIs | No network rate limit |

## 14. Design System

N/A - no web UI or Tailwind design system. The app UI is a native AppKit menu-bar item plus a native AppKit toast.

App icon requirements:

- Source asset: `Resources/AppIconSource.png`.
- Generated iconset: `Resources/AppIcon.iconset`.
- Bundle icon: `Resources/AppIcon.icns`, referenced by `CFBundleIconFile = AppIcon`.
- Current concept: dark rounded square, blue Finder folder, white path slash, copy badge, green check.

Toast visual requirements:

- Window frame: approximately `268 x 44`.
- Visible toast: approximately `260 x 38`.
- Shape: pill with full-radius corners.
- Background: dark translucent neutral.
- Text: `Path copied`.
- Icon: checkmark or SF Symbol equivalent.
- Duration: visible for 450-900 ms.
- Focus: panel cannot become key or main.

## 15. MVP Scope & Milestones

> **Codebase Health Scan**
> Greenfield - no existing code to scan. The repo was empty before this spec and research pass.

### MVP (Phase 1)

- [x] REQ-001: Finder-scoped dynamic hotkey ownership.
- [x] REQ-002: Copy selected Finder paths.
- [x] REQ-003: Preserve path formatting behavior.
- [x] REQ-004: Non-activating native toast.
- [x] REQ-005: Empty selection leaves clipboard unchanged.
- [x] REQ-006: Permission denial handling.
- [x] REQ-007: Command Line Tools build and test path.

### Phase 2

- [x] REQ-010: Launch at login.
- [x] REQ-011: Menu-bar status item.
- [x] REQ-013: App icon and local packaging.
- [ ] REQ-012: Rich file URL pasteboard items.

### Later

- [ ] REQ-020: User-configurable shortcut.
- [x] REQ-021: Developer ID signing and notarization (`Scripts/release.sh`; 0.1.0 accepted by Apple on 2026-11-12).

## 16. Risks & Unknowns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Carbon hotkey registration conflict on `Shift-Command-C` | Med | High | Detect OSStatus, report conflict, keep Finder shortcut neutralization documented |
| Dynamic registration race when app focus changes | Low | Med | Observe activation notifications and re-check Finder inside handler |
| Finder Automation permission denied | Med | High | Add usage description, handle denial without clipboard write |
| Toast accidentally activates app | Med | High | Use `NSPanel` subclass tests and forbid `makeKeyAndOrderFront`/`NSApp.activate` in presenter |
| SwiftPM bundle script misses TCC metadata | Med | High | Build `.app` with explicit `Info.plist` before testing Automation prompts |
| Full Xcode unavailable locally | High | Med | Keep MVP SwiftPM/CLT build path |
| Manual local install can drift from repo build | Low | Med | Reinstall from `build/CopyFolderPath.app` after `Scripts/package-app.sh` |

| Unknown | Impact if Wrong | Plan to Resolve |
|---------|-----------------|-----------------|
| Whether exclusive Carbon registration suppresses Finder's built-in Computer shortcut in all tested states | Could require CGEventTap or continued Finder shortcut neutralization | Prototype first and run GUI smoke test |
| Whether returning Finder `URL` values handles all selected item classes | Could require POSIX-path AppleScript fallback | Add fixtures and test aliases, folders, volumes, and iCloud items |
| Whether rich file URL pasteboard items are needed soon | Could change clipboard writer design | Keep `PasteboardWriter` as the owner and promote REQ-012 when needed |

## 17. Testing Strategy

### Test Framework & Runner

| Level | Framework | Command |
|-------|-----------|---------|
| Unit | Repo-owned Swift test runner through SwiftPM | `swift run CopyFolderPathTests` |
| Integration | Test runner with fakes plus bundle checks | `swift run CopyFolderPathTests && Scripts/package-app.sh` |
| Manual GUI smoke | Installed macOS app after package/install | Launch `/Applications/Copy Folder Path.app`, choose `Test Toast`, then test `Shift-Command-C` in Finder |

### Coverage Targets

| Level | Target | Measurement |
|-------|--------|-------------|
| Unit | At least 90% of path normalization and command coordination logic | Test runner covers every branch in `PathNormalizer` and `CopyPathCommand` |
| Integration | All P0 command result paths covered | Named test runner suites in section 6 |
| Manual GUI smoke | Finder hotkey and toast path exercised once per release candidate | User confirms the toast appears and the clipboard contains selected POSIX paths |

### Test-First Mandate

Every P0 requirement must have a failing test before implementation begins. P1/P2 requirements may use test-alongside.

### What NOT to Test

- AppKit drawing pixels in unit tests.
- Apple's Finder implementation.
- Carbon internals beyond wrapper behavior and OSStatus handling.
- `SMAppService.register/unregister` in default tests because it mutates user login-item state.

## Sources

- Research synthesis: [docs/research.md](docs/research.md)
- Apple Mac keyboard shortcuts: https://support.apple.com/en-us/102650
- Keyboard Maestro Custom HTML Prompt: https://wiki.keyboardmaestro.com/action/Custom_HTML_Prompt
- Keyboard Maestro Hot Key trigger: https://wiki.keyboardmaestro.com/trigger/Hot_Key
- KeyboardShortcuts package: https://github.com/sindresorhus/KeyboardShortcuts
- LaunchAtLogin package: https://github.com/sindresorhus/LaunchAtLogin-Modern
