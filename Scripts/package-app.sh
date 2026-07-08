#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/CopyFolderPath.app"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$ROOT_DIR/Resources/Info.plist")"
PACKAGE_PATH="$ROOT_DIR/build/CopyFolderPath-$VERSION.zip"

"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

rm -f "$PACKAGE_PATH"
COPYFILE_DISABLE=1 ditto -c -k --keepParent --norsrc --noextattr "$APP_DIR" "$PACKAGE_PATH"

echo "$PACKAGE_PATH"
