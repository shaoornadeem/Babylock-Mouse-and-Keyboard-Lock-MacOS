#!/bin/bash
# build.sh — Build BabyLock.app for macOS
# Creates a proper .app bundle that can be placed in /Applications
set -e

echo ""
echo "🍼 ══════════════════════════════════════════════"
echo "   BabyLock for macOS — Build Script"
echo "   ══════════════════════════════════════════════"
echo ""

# Check for Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

echo "🔨 Building BabyLock (Release mode)..."
swift build -c release 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Check the errors above."
    exit 1
fi

echo "✅ Compilation successful!"
echo ""

# Create .app bundle
APP_NAME="BabyLock"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Creating ${APP_DIR} bundle..."

# Clean previous build
rm -rf "${APP_DIR}"

# Create directory structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist and AppIcon
cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Create PkgInfo
echo -n "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Make binary executable
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Self-sign app bundle with entitlements (ad-hoc signing)
echo "🔏 Applying ad-hoc code signature..."
codesign --force --deep --sign - --entitlements "Resources/BabyLock.entitlements" "${APP_DIR}"

echo ""
echo "✅ ══════════════════════════════════════════════"
echo "   Build Complete!"
echo "   ══════════════════════════════════════════════"
echo ""
echo "   📁 Output: $(pwd)/${APP_DIR}"
echo ""
echo "   📌 To install:"
echo "      cp -r ${APP_DIR} /Applications/"
echo ""
echo "   ▶️  To run directly:"
echo "      open ${APP_DIR}"
echo ""
echo "   ⚠️  First run:"
echo "      Grant Accessibility permission in:"
echo "      System Settings → Privacy & Security → Accessibility"
echo ""
echo "   🔒 To lock: Click 🔓 in menu bar → Lock Now (⌘⌃L / ⌘⌥L)"
echo "   🔓 To unlock: Hold U+K for 3 seconds, or type 'baby'"
echo "   ⚙️ Settings: Click 🔓 in menu bar → Keyboard Shortcuts... (⌘,)"
echo ""
