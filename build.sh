#!/bin/bash
# BaifanYu (白饭鱼) — build script: SPM build + app bundle + resources + icon + ad-hoc sign.
set -e
cd "$(dirname "$0")"

APP_NAME="BaifanYu"
APP="$APP_NAME.app"
CONFIG="${1:-release}"

# ---------------------------------------------------------------- SDK selection
# With a Command Line Tools-only toolchain the newest SDK declares SwiftUI's
# property wrappers as macros, and libSwiftUIMacros.dylib lives only inside
# Xcode — so `swift build` fails for ANY SwiftUI project. Fall back to the
# newest installed SDK whose SwiftUICore declares no such macros.
if [ -z "$SDKROOT" ] && [ ! -f "$(xcode-select -p)/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib" ]; then
  for sdk in $(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk 2>/dev/null | sed 's#.*/##; s#\.sdk##' | sort -Vr); do
    iface="/Library/Developer/CommandLineTools/SDKs/$sdk.sdk/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-macos.swiftinterface"
    [ -f "$iface" ] || continue
    if ! grep -q "macro State" "$iface"; then
      export SDKROOT="/Library/Developer/CommandLineTools/SDKs/$sdk.sdk"
      echo "==> Building against SDK $sdk (SwiftUI macros unavailable in the default SDK)"
      break
    fi
  done
fi

echo "==> Building ($CONFIG)..."
swift build -c "$CONFIG"

echo "==> Bundling $APP..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

BIN=".build/$([ "$CONFIG" = "debug" ] && echo debug || echo release)/$APP_NAME"
cp "$BIN" "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"

# SPM stores .process()'d resources in a side bundle. It must be copied INTO the
# app as a bundle (not flattened): Bundle.module looks for a directory literally
# named <Target>_<Target>.bundle under Contents/Resources.
RES_BUNDLE=$(find .build -type d -name "$APP_NAME""_""$APP_NAME.bundle" 2>/dev/null | head -1)
if [ -n "$RES_BUNDLE" ]; then
    rm -rf "$APP/Contents/Resources/$APP_NAME""_""$APP_NAME.bundle"
    cp -R "$RES_BUNDLE" "$APP/Contents/Resources/"
else
    echo "!! resource bundle not found — the pet will have no artwork" >&2
fi

if [ -f "Sources/Resources/AppIcon.icns" ]; then
    cp "Sources/Resources/AppIcon.icns" "$APP/Contents/Resources/"
fi

# Ship the upstream MIT license + notice inside the bundle.
[ -f LICENSE ] && cp LICENSE "$APP/Contents/Resources/LICENSE.txt"

echo "==> Signing (ad-hoc)..."
codesign --force --deep --sign - "$APP"

echo "==> Done: $APP"
echo "    open \"$APP\"   — 白饭鱼 floats on your desktop, her icon sits in the menu bar."
