#!/bin/sh
# Packages the Editor as a macOS app: Build/Editor.app (or the path given as $1).
#
#   Scripts/make-editor-app.sh                  # release build -> Build/Editor.app
#   CONFIG=debug Scripts/make-editor-app.sh     # debug build
#   Scripts/make-editor-app.sh ~/Applications/Editor.app
#
# The app is for this machine: it uses this checkout's sources (Info.plist sets
# ACRO_ENGINE to it, so Build Game, game modules and the Game Module template keep
# working from Finder, where the working directory is /), and with Vulkan enabled it links
# Homebrew's libvulkan / libglfw. Game modules are built in the app's configuration.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CONFIG=${CONFIG:-release}
APP=${1:-"$ROOT/Build/Editor.app"}
NAME=Editor
VERSION=$(sed -n 's/.*"\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)".*/\1/p' "$ROOT/Sources/Engine/Core/EngineVersion.swift" | head -n 1)
VERSION=${VERSION:-0.0.0}

cd "$ROOT"
swift build -c "$CONFIG" --product "$NAME"
BIN=$(swift build -c "$CONFIG" --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/$NAME" "$APP/Contents/MacOS/$NAME"
# SwiftPM resource bundles (shaders, fonts); Bundle.module finds them in Contents/Resources.
for bundle in "$BIN"/Acro_Engine.bundle "$BIN"/Acro_Editor*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done
[ -f "$ROOT/logos/AppIcon.icns" ] && cp "$ROOT/logos/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleExecutable</key><string>$NAME</string>
	<key>CFBundleIdentifier</key><string>dev.acro.editor</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>$NAME</string>
	<key>CFBundleDisplayName</key><string>Acro Editor</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>$VERSION</string>
	<key>CFBundleIconFile</key><string>AppIcon</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSPrincipalClass</key><string>NSApplication</string>
	<key>LSEnvironment</key>
	<dict>
		<key>ACRO_ENGINE</key><string>$ROOT</string>
		<key>EDITOR_SAMPLE_PROJECT</key><string>$ROOT/Projects/SampleGame</string>
		<key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
	</dict>
</dict>
</plist>
EOF

codesign --force --sign - "$APP" >/dev/null 2>&1 || echo "warning: ad-hoc signing failed" >&2
# Make Launch Services pick up the new Info.plist (LSEnvironment is cached per app).
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" 2>/dev/null || true

echo "$APP"
