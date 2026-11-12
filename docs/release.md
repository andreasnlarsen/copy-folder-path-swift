# Local Release

This project ships as a local macOS menu-bar app.

## Build And Test

```sh
swift run CopyFolderPathTests
Scripts/package-app.sh
```

`Scripts/package-app.sh` rebuilds `build/CopyFolderPath.app`, ad-hoc signs it, and writes `build/CopyFolderPath-0.1.0.zip`.

## Install

```sh
ditto --rsrc --extattr build/CopyFolderPath.app "/Applications/Copy Folder Path.app"
open "/Applications/Copy Folder Path.app"
```

The installed app runs as an accessory/menu-bar app with no Dock icon.

## Verify

```sh
plutil -lint build/CopyFolderPath.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 build/CopyFolderPath.app
codesign --verify --deep --strict --verbose=2 "/Applications/Copy Folder Path.app"
```

Confirm the running process points at the installed app:

```sh
ps -axo pid,comm,args | rg 'CopyFolderPath|Copy Folder Path'
```

Manual smoke check:

1. Open the menu-bar item and choose `Test Toast`.
2. Select a Finder item.
3. Press `Shift-Command-C`.
4. Paste somewhere safe and confirm the clipboard contains one POSIX path per selected item.

The first Finder selection read can trigger the macOS Automation permission prompt.

## Icon

The editable source is `Resources/AppIconSource.png`.

Regenerate the iconset and `.icns` with:

```sh
swift Scripts/generate-app-icon.swift
```

The bundle uses `Resources/AppIcon.icns` through `CFBundleIconFile = AppIcon`.

## Public Release

A public release is signed with a Developer ID, notarized by Apple, and installed by others through Homebrew or a direct download.

The release uses the `notchfocus-notary` notarization profile, the same one the other apps signed on this Mac use. It already exists here. On a new Mac a person creates it in their own terminal, because it asks for an app-specific password:

```sh
xcrun notarytool store-credentials notchfocus-notary --apple-id <apple-id> --team-id D79LWN85PJ
```

For each release:

1. Raise `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. Run `Scripts/release.sh`. It runs the tests, builds, signs, notarizes, staples, and prints the zip path and its SHA-256.
3. Publish the zip: `gh release create v<version> build/CopyFolderPath-<version>.zip`.
4. Put the new version and SHA-256 in `Casks/copy-folder-path.rb` in the `andreasnlarsen/homebrew-tap` repository.

The signing identity is named in one place, at the top of `Scripts/release.sh`. Changing it resets the Finder permission users have granted, so treat that as a release of its own and say so in its notes.
