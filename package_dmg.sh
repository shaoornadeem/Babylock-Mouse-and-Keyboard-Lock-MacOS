#!/bin/bash
# package_dmg.sh — Create professional drag-and-drop installer DMG for BabyLock
set -e

APP_NAME="BabyLock"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGING_DIR=".dmg_staging"

echo ""
echo "📦 ══════════════════════════════════════════════"
echo "   Creating ${DMG_NAME} Installer..."
echo "   ══════════════════════════════════════════════"
echo ""

# Ensure BabyLock.app is built
if [ ! -d "${APP_NAME}.app" ]; then
    echo "🔨 Building app first..."
    ./build.sh
fi

# Clean up any existing staging or DMG
rm -rf "${STAGING_DIR}" "${DMG_NAME}"
mkdir -p "${STAGING_DIR}"

# Copy app to staging
echo "📂 Staging ${APP_NAME}.app..."
cp -R "${APP_NAME}.app" "${STAGING_DIR}/"

# Create symlink to /Applications
echo "🔗 Creating /Applications link..."
ln -s /Applications "${STAGING_DIR}/Applications"

# Create disk image
echo "💿 Building disk image with hdiutil..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

# Clean up staging
rm -rf "${STAGING_DIR}"

echo ""
echo "✅ ══════════════════════════════════════════════"
echo "   DMG Installer Created Successfully!"
echo "   ══════════════════════════════════════════════"
echo ""
echo "   📁 File: $(pwd)/${DMG_NAME}"
echo "   📊 Size: $(ls -lh "${DMG_NAME}" | awk '{print $5}')"
echo ""
echo "   🎉 Ready for public distribution (GitHub, Website, Homebrew)!"
echo ""
