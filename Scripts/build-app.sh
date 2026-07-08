#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_DIR="$ROOT_DIR/build/CopyFolderPath.app"
EXECUTABLE="$ROOT_DIR/.build/$CONFIGURATION/CopyFolderPath"
ICON_FILE="$ROOT_DIR/Resources/AppIcon.icns"
ICON_SOURCE="$ROOT_DIR/Resources/AppIconSource.png"

if [[ ! -f "$ICON_FILE" || "$ICON_SOURCE" -nt "$ICON_FILE" ]]; then
  swift "$ROOT_DIR/Scripts/generate-app-icon.swift"
fi

swift build -c "$CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/CopyFolderPath"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ICON_FILE" "$APP_DIR/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
