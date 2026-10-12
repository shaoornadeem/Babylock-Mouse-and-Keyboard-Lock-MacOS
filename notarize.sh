#!/bin/bash
# notarize.sh — Sign and Notarize BabyLock for macOS (Apple Gatekeeper compliant)
#
# Usage:
#   ./notarize.sh "Developer ID Application: Your Name (TEAM_ID)" "your-apple-id@example.com" "TEAM_ID"
#
# Or with App Store Connect API Key:
#   ./notarize.sh "Developer ID Application: Your Name (TEAM_ID)" --keychain-profile "AC_PASSWORD"
#
set -e

SIGNING_IDENTITY="$1"
APPLE_ID="$2"
TEAM_ID="$3"

if [ -z "$SIGNING_IDENTITY" ]; then
    echo "❌ Error: Developer ID signing identity required."
    echo ""
    echo "Usage:"
    echo "  ./notarize.sh \"Developer ID Application: Your Name (TEAM_ID)\" \"apple_id@example.com\" \"TEAM_ID\""
    echo ""
    echo "To list your installed certificates, run:"
    echo "  security find-identity -p codesigning -v"
    exit 1
fi

APP_NAME="BabyLock"
APP_DIR="${APP_NAME}.app"
DMG_NAME="${APP_NAME}-1.0.0.dmg"

echo "🔨 1. Building release binary..."
./build.sh

echo "🔏 2. Signing ${APP_DIR} with Developer ID..."
codesign --force --deep --options runtime \
    --sign "${SIGNING_IDENTITY}" \
    --entitlements "Resources/BabyLock.entitlements" \
    "${APP_DIR}"

echo "✅ Verifying signature..."
codesign --verify --verbose "${APP_DIR}"

echo "📦 3. Packaging into DMG..."
./package_dmg.sh

echo "🔏 4. Signing DMG..."
codesign --force --sign "${SIGNING_IDENTITY}" "${DMG_NAME}"

echo ""
echo "📤 5. Submitting to Apple Notary Service..."
if [ -n "$APPLE_ID" ] && [ -n "$TEAM_ID" ]; then
    xcrun notarytool submit "${DMG_NAME}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${TEAM_ID}" \
        --wait

    echo "📎 6. Stapling notarization ticket..."
    xcrun stapler staple "${DMG_NAME}"
    xcrun stapler staple "${APP_DIR}"

    echo ""
    echo "🎉 Notarization complete! ${DMG_NAME} is certified by Apple and ready for public download without Gatekeeper warnings."
else
    echo "⚠️ Apple ID or Team ID not provided. Skipped notarytool submission."
    echo "   To submit manually:"
    echo "   xcrun notarytool submit ${DMG_NAME} --keychain-profile \"YOUR_PROFILE\" --wait"
fi
