# Copy Folder Path

Native macOS utility for copying selected Finder item paths with `Shift-Command-C`.

This repo contains a small Swift/AppKit menu-bar app that replaces the Keyboard Maestro HTML-toast workflow with a native non-activating toast.

## Install

Build and install the app into `/Applications`:

```sh
Scripts/package-app.sh
ditto --rsrc --extattr build/CopyFolderPath.app "/Applications/Copy Folder Path.app"
open "/Applications/Copy Folder Path.app"
```

When the app is running, it appears as a menu-bar item. It does not show a Dock icon.

## Build

```sh
swift run CopyFolderPathTests
Scripts/build-app.sh
```

The app bundle is written to:

```text
build/CopyFolderPath.app
```

To create a zipped app artifact:

```sh
Scripts/package-app.sh
```

The zip is written to `build/CopyFolderPath-0.1.0.zip`.

The selected app icon is stored in `Resources/AppIconSource.png`. The build script regenerates `Resources/AppIcon.icns` automatically when the source image is newer; to regenerate it manually:

```sh
swift Scripts/generate-app-icon.swift
```

## Use

Launch `/Applications/Copy Folder Path.app`, select one or more items in Finder, then press `Shift-Command-C`. The app copies one normalized POSIX path per line to the clipboard and shows a brief native toast without activating itself.

The menu-bar item provides:

- Current shortcut status.
- Test Toast.
- Launch at Login toggle.
- Open Login Items Settings.
- Open Automation Settings.
- About and Quit.

The first real Finder selection read may trigger the macOS Automation permission prompt for Finder.

See [SPEC.md](SPEC.md) for the build contract, [docs/research.md](docs/research.md) for research notes, and [docs/release.md](docs/release.md) for local release packaging.
