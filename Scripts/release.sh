#!/usr/bin/env bash
# Builds a release others can run: signed with a Developer ID, notarized by Apple, stapled, zipped.
# Prints the zip path and its SHA-256, which the Homebrew cask needs.
#
# Uses the same notarization profile as the other apps signed on this Mac. To create it on a new Mac,
# a person runs this in their own terminal (it asks for an app-specific password):
#   xcrun notarytool store-credentials "$NOTARY_PROFILE" --apple-id <apple-id> --team-id <team-id>
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The one place that names who signs the app. Changing it resets the Finder
# permission users have granted, so treat a change as a release of its own.
export CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: LEAD MEDIA AS (D79LWN85PJ)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-notchfocus-notary}"

APP_DIR="$ROOT_DIR/build/CopyFolderPath.app"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$ROOT_DIR/Resources/Info.plist")"
ZIP_PATH="$ROOT_DIR/build/CopyFolderPath-$VERSION.zip"

zip_app() {
  rm -f "$ZIP_PATH"
  COPYFILE_DISABLE=1 ditto -c -k --keepParent --norsrc --noextattr "$APP_DIR" "$ZIP_PATH"
}

swift run CopyFolderPathTests
"$ROOT_DIR/Scripts/build-app.sh" >/dev/null
codesign --verify --deep --strict "$APP_DIR"

zip_app
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_DIR"

# The zip that ships must contain the stapled app, so it is made again.
zip_app
spctl --assess --type execute --verbose=2 "$APP_DIR"

echo "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" | cut -d' ' -f1
