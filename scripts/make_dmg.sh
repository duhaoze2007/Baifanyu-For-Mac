#!/bin/bash
# Builds a distributable DMG: BaifanYu_V<version>.dmg with the app and a
# shortcut to /Applications.
set -e
cd "$(dirname "$0")/.."

APP_NAME="BaifanYu"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)
APP="$APP_NAME.app"
DMG="${APP_NAME}_V${VERSION}.dmg"
STAGE=$(mktemp -d)

[ -d "$APP" ] || ./build.sh

echo "==> Staging..."
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/LICENSE.txt" 2>/dev/null || true

echo "==> Creating $DMG..."
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "==> Done: $DMG ($(du -h "$DMG" | cut -f1))"
