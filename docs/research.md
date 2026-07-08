# Research: Native Finder Copy Path Utility

Last updated: 2026-07-08

## Short Answer

Yes, this is feasible as a native Swift macOS app. The app should be a small AppKit accessory/menu-bar style utility that:

1. Registers `Shift-Command-C` only while Finder is frontmost.
2. Reads Finder's current selection through in-process Apple Events.
3. Normalizes selected file URLs into POSIX paths in Swift.
4. Writes newline-separated paths to `NSPasteboard.general`.
5. Shows a borderless non-activating `NSPanel` toast without activating the app or Finder.

Estimated difficulty:

- Prototype: 0.5-1 day.
- Solid local utility with tests and `.app` bundle script: 1-2 days.
- Launch-at-login UI and polished packaging: +0.5-1 day.
- Signed/notarized distribution for other Macs: +0.5-1.5 days once certificates are available.

## Current Keyboard Maestro Failure Mode

The current AppleScript copy action is sound. The fragile part is the Custom HTML Prompt toast. Keyboard Maestro's HTML prompt is a window surface, and the working mitigation reactivates Finder from `KMDidShowWindow`. That can pull Finder's whole window stack forward, which is exactly the behavior we want to remove.

Keyboard Maestro documents that Custom HTML Prompt pages can run JavaScript lifecycle hooks such as `KMDidShowWindow()` and call `window.KeyboardMaestro.ProcessAppleScript(...)` or `window.KeyboardMaestro.Cancel(...)`. Keyboard Maestro also documents that hot key triggers are swallowed by the system, which explains why Keyboard Maestro can own the shortcut but also why its prompt/focus behavior matters.

Sources:

- Apple: `Shift-Command-C` is Finder's "Open the Computer window" shortcut: https://support.apple.com/en-us/102650
- Keyboard Maestro Custom HTML Prompt docs: https://wiki.keyboardmaestro.com/action/Custom_HTML_Prompt
- Keyboard Maestro Hot Key trigger docs: https://wiki.keyboardmaestro.com/trigger/Hot_Key

## Recommended Native Architecture

### Hotkey Ownership

Use Carbon/HIToolbox `RegisterEventHotKey` with `kEventHotKeyExclusive`, but register the hotkey only while Finder is frontmost:

- Observe `NSWorkspace.didActivateApplicationNotification`.
- Check `NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"`.
- Register `Shift-Command-C` when Finder becomes frontmost.
- Unregister it when Finder stops being frontmost.
- Re-check Finder inside the hotkey handler before copying.

There is no public macOS API for "register this shortcut only for Finder." Dynamic global registration is the narrowest practical approach.

Alternatives considered:

- AppKit/SwiftUI menu shortcuts: only work when this app is active.
- `NSEvent.addLocalMonitorForEvents`: only intercepts this app's events.
- `NSEvent.addGlobalMonitorForEvents`: observes events but cannot prevent delivery; key monitoring needs Accessibility trust.
- `CGEventTap`: can suppress keys based on frontmost app, but it requires Accessibility permission and is more invasive.
- `KeyboardShortcuts` package: good if user-configurable shortcuts become a requirement; current MVP can use first-party Carbon directly.

Sources:

- Apple `RegisterEventHotKey` SDK header: `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/.../CarbonEvents.h`
- Apple `NSEvent` local/global monitor docs: https://developer.apple.com/documentation/appkit/nsevent
- KeyboardShortcuts package: https://github.com/sindresorhus/KeyboardShortcuts

## Finder Selection

Use a fixed AppleScript through `NSAppleScript`, not shelling out to `osascript`. The app should keep TCC prompts/errors attached to its own bundle identity.

Preferred script shape:

```applescript
tell application "Finder"
  set selectedItems to selection
  set selectedURLs to {}
  repeat with selectedItem in selectedItems
    set end of selectedURLs to URL of selectedItem
  end repeat
  return selectedURLs
end tell
```

Swift should own all normalization:

- Reject non-`file:` URLs.
- Convert URLs to `URL.path`.
- Remove trailing `/` from non-root folders.
- Join displayed paths with `\n`.
- Keep `[URL]` internally so later richer pasteboard support is possible.

Permissions:

- Add `NSAppleEventsUsageDescription` to `Info.plist`.
- If using Hardened Runtime, include `com.apple.security.automation.apple-events`.
- For personal use, a signed non-sandboxed app should have less cross-app automation friction than a sandboxed App Store-style app.

Alternatives considered:

- ScriptingBridge: still Apple Events; more glue for little benefit.
- Raw `NSAppleEventDescriptor`: possible but too much four-character-code machinery for MVP.
- Accessibility: last resort; depends on Finder UI hierarchy and requires broader permission.
- Finder Sync extension: useful for Finder extension/menu workflows, not ideal for this hotkey utility.

Sources:

- Apple Mac Automation Scripting Guide: https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/HowMacScriptingWorks.html
- Apple file/path references guide: https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/ReferenceFilesandFolders.html
- Apple `NSAppleScript`: https://developer.apple.com/documentation/foundation/nsapplescript
- Apple `NSPasteboard`: https://developer.apple.com/documentation/appkit/nspasteboard

## Toast / Notification UI

Use a retained `NSPanel` subclass:

```swift
final class ToastPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
```

Recommended configuration:

```swift
styleMask: [.borderless, .nonactivatingPanel]
isOpaque = false
backgroundColor = .clear
ignoresMouseEvents = true
hidesOnDeactivate = false
level = .statusBar
collectionBehavior = [.transient, .ignoresCycle, .canJoinAllSpaces, .fullScreenAuxiliary]
animationBehavior = .none
```

The implementation uses `.statusBar` rather than `.floating` because screenshot verification showed the preview process could run and exit normally without the `.floating` panel appearing above the active app. `.statusBar` keeps the toast visible over ordinary app windows while preserving the non-activating behavior.

Show with `orderFront(nil)` or `orderFrontRegardless()`. Do not call `makeKeyAndOrderFront` and do not call `NSApp.activate()`.

Use `NSApplication.setActivationPolicy(.accessory)`. Do not use `.prohibited`, because the app still needs to own a visible toast window.

Sources:

- Apple `NSPanel`: https://developer.apple.com/documentation/appkit/nspanel
- Apple non-activating panel style mask: https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel
- Apple `NSWindow.canBecomeKey`: https://developer.apple.com/documentation/appkit/nswindow/canbecomekey
- Apple `NSWindow.ignoresMouseEvents`: https://developer.apple.com/documentation/appkit/nswindow/ignoresmouseevents
- AppKit panel risk note: https://philz.blog/nspanel-nonactivating-style-mask-flag/

## Packaging

Local facts from this Mac:

- `git init` has been run and the branch was renamed to `main`.
- Swift 6.3.3 is available.
- Full Xcode is not selected; `xcodebuild` reports Command Line Tools only.
- Escalated compile probes confirmed AppKit, Carbon, and ServiceManagement compile outside the Codex sandbox.
- `Scripts/package-app.sh` builds, ad-hoc signs, and packages `build/CopyFolderPath.app` into `build/CopyFolderPath-0.1.0.zip`.
- The selected app icon lives at `Resources/AppIconSource.png`; `Scripts/generate-app-icon.swift` creates `Resources/AppIcon.iconset` and `Resources/AppIcon.icns`.
- The app has been installed locally to `/Applications/Copy Folder Path.app` and launched from that installed path.

Packaging recommendation:

1. Start with SwiftPM core plus executable/AppKit app sources so `swift build` and the repo-owned test runner work with Command Line Tools.
2. Provide a script that assembles a local `.app` bundle with `Info.plist`, resources, and ad-hoc/local signing.
3. Provide a package script that creates a zip with `ditto --keepParent` while suppressing AppleDouble sidecar files.
4. Add an Xcode project later if richer signing/archive UI or notarized distribution becomes important.

Launch at login:

- Use `SMAppService.mainApp` for macOS 13+.
- `SMAppService` requires code signing.
- `SMAppService.mainApp.status` can report not registered, enabled, requires approval, or not found. The app should display `requiresApproval` distinctly and link the user to Login Items settings instead of repeatedly retrying registration.
- Default tests should use a protocol-backed fake service and must not mutate the user's real login-item state.

Sources:

- Apple `SMAppService`: https://developer.apple.com/documentation/servicemanagement/smappservice
- LaunchAtLogin package, optional UI wrapper: https://github.com/sindresorhus/LaunchAtLogin-Modern

## Key Risks

- Dynamic hotkey registration is not a true Finder-scoped OS contract. It is a narrow practical approximation.
- Another process can already own `Shift-Command-C` exclusively.
- Finder Automation permission can be denied or revoked.
- A malformed toast implementation can recreate the focus-steal bug.
- SwiftPM-only packaging must supply bundle identity and usage descriptions correctly for TCC prompts.

## Recommendation

Build this. The native version is the right shape for your use case because the problem is a focus/notification-surface problem, not a path-copying problem. The risky parts are bounded and testable enough for a small utility.
