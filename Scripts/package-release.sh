#!/bin/sh
# Builds the editor and packages it for distribution (macOS and Linux; Windows is
# Scripts/package-release.ps1). The Release workflow runs this; it also works locally.
#
#   Scripts/package-release.sh [out-dir]       # default: Build/release
#
# Writes <out-dir>/Acro-<version>-<platform>-<arch>.zip (macOS) or .tar.gz (Linux) with README,
# LICENSE and CHANGELOG plus:
#   macOS: Editor.app, Metal only (no Homebrew Vulkan/GLFW to link).
#   Linux: the Editor executable, the engine's resource folder and the Swift runtime libraries
#          (found through $ORIGIN); Vulkan, GLFW, zlib and ALSA come from the system.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
OUT=${1:-"$ROOT/Build/release"}
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
VERSION=$(Scripts/version.sh)

case $(uname -s) in
    Darwin) PLATFORM=macos; export ENGINE_DISABLE_VULKAN=1 ;;
    Linux) PLATFORM=linux ;;
    *) echo "package-release.sh: unsupported platform $(uname -s) (Windows: package-release.ps1)" >&2; exit 1 ;;
esac
ARCH=$(uname -m)
[ "$ARCH" = aarch64 ] && ARCH=arm64
NAME="Acro-$VERSION-$PLATFORM-$ARCH"
STAGE="$OUT/$NAME"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp README.md LICENSE CHANGELOG.md "$STAGE/"

if [ "$PLATFORM" = macos ]; then
    # Builds the Editor and copies its resource bundles into the app.
    PORTABLE=1 Scripts/make-editor-app.sh "$STAGE/Editor.app" >/dev/null
    rm -f "$OUT/$NAME.zip"
    (cd "$OUT" && ditto -c -k --norsrc --noextattr --noacl --keepParent "$NAME" "$NAME.zip")
    echo "$OUT/$NAME.zip"
    exit 0
fi

swift build -c release --product Editor
BIN=$(swift build -c release --show-bin-path)
cp "$BIN/Editor" "$STAGE/"
# SwiftPM resource folders (shaders, fonts); the demo's isn't needed.
for bundle in "$BIN"/Acro_*.resources; do
    case $bundle in */Acro_Demo.resources) continue ;; esac
    [ -e "$bundle" ] && cp -R "$bundle" "$STAGE/"
done

# Swift runtime (libswiftCore, Foundation, dispatch, ICU, ...) from the toolchain.
ldd "$STAGE/Editor" | awk '/=> \// { print $3 }' | while read -r lib; do
    case $lib in
        */swift/linux/*) cp -L "$lib" "$STAGE/" ;;
    esac
done
if ldd "$STAGE/Editor" | grep -q "not found"; then
    echo "package-release.sh: Editor has unresolved libraries:" >&2
    ldd "$STAGE/Editor" | grep "not found" >&2
    exit 1
fi
tar -C "$OUT" -czf "$OUT/$NAME.tar.gz" "$NAME"
echo "$OUT/$NAME.tar.gz"
