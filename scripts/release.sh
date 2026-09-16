#!/usr/bin/env bash
#
# MisiCopy release pipeline
# -------------------------
# Builds Release, signs with Developer ID, notarizes the .app, packages
# into a signed+notarized DMG, staples the ticket, and emits the final
# artifact ready for distribution from misiraca.com.
#
# Requirements (one-time):
#   1. Developer ID Application certificate in login keychain
#   2. App-specific password stored:
#        xcrun notarytool store-credentials "AC_PASSWORD" \
#          --apple-id <email> --team-id SM6L2XLUBA --password <app-specific>
#
# Run from project root:
#   bash scripts/release.sh
#

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

APP_NAME="MisiCopy"
SCHEME="MisiCopy"
BUNDLE_ID="fr.misilab.MisiCopy"
TEAM_ID="SM6L2XLUBA"
SIGN_ID="Developer ID Application: matthieu misiraca ($TEAM_ID)"
INSTALLER_SIGN_ID="Developer ID Installer: matthieu misiraca ($TEAM_ID)"
NOTARY_PROFILE="AC_PASSWORD"
# Resolve the version from the Mac SCHEME's build settings — NOT a raw
# grep of the pbxproj. Once the iOS targets were added, a bare grep picked
# up the iPhone app's MARKETING_VERSION (it appears first in the file) and
# mis-stamped the Mac release. `-showBuildSettings` resolves the value for
# the exact scheme we're shipping, whatever the file ordering.
_BUILD_SETTINGS=$(xcodebuild -project MisiCopy.xcodeproj -scheme "$SCHEME" -showBuildSettings 2>/dev/null)
VERSION=$(echo "$_BUILD_SETTINGS" | awk -F' = ' '/ MARKETING_VERSION =/{print $2; exit}')
: "${VERSION:=1.0}"
# Sparkle compares `sparkle:version` to the app's CFBundleVersion. We mirror
# the build number from CURRENT_PROJECT_VERSION so it stays in sync.
BUILD_NUMBER=$(echo "$_BUILD_SETTINGS" | awk -F' = ' '/ CURRENT_PROJECT_VERSION =/{print $2; exit}')
: "${BUILD_NUMBER:=1}"

BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/${APP_NAME}.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_PATH="$EXPORT_DIR/${APP_NAME}.app"
PKG_COMPONENT="$BUILD_DIR/${APP_NAME}-component.pkg"
PKG_PATH="$BUILD_DIR/${APP_NAME}-${VERSION}.pkg"

# ─────────────────────────────────────────────────────────────────────
# Reset
# ─────────────────────────────────────────────────────────────────────
echo "▸ Cleaning build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$EXPORT_DIR"

# ─────────────────────────────────────────────────────────────────────
# 1. Archive
# ─────────────────────────────────────────────────────────────────────
echo "▸ Archiving (Release)"
xcodebuild \
    -project MisiCopy.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$SIGN_ID" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    PROVISIONING_PROFILE_SPECIFIER="MisiCopy Developer ID" \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    archive | xcbeautify --quieter 2>/dev/null || \
xcodebuild \
    -project MisiCopy.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$SIGN_ID" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    PROVISIONING_PROFILE_SPECIFIER="MisiCopy Developer ID" \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    archive

# ─────────────────────────────────────────────────────────────────────
# 2. Export
# ─────────────────────────────────────────────────────────────────────
echo "▸ Exporting .app"
cat > "$BUILD_DIR/exportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>fr.misilab.MisiCopy</key>
        <string>MisiCopy Developer ID</string>
    </dict>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/exportOptions.plist"

# ─────────────────────────────────────────────────────────────────────
# 3. Verify signature
# ─────────────────────────────────────────────────────────────────────
echo "▸ Verifying app signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose=2 "$APP_PATH" || echo "⚠ Will pass after notarization"

# ─────────────────────────────────────────────────────────────────────
# 4. Notarize .app
# ─────────────────────────────────────────────────────────────────────
echo "▸ Zipping app for notarization"
APP_ZIP="$BUILD_DIR/${APP_NAME}.zip"
ditto -c -k --keepParent "$APP_PATH" "$APP_ZIP"

echo "▸ Submitting to Apple notary service (this can take 1-15 min)"
xcrun notarytool submit "$APP_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "▸ Stapling notarization ticket to .app"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

# ─────────────────────────────────────────────────────────────────────
# 5. Build a signed installer package (.pkg)
# ─────────────────────────────────────────────────────────────────────
echo "▸ Building component .pkg"
pkgbuild \
    --component "$APP_PATH" \
    --identifier "$BUNDLE_ID" \
    --version "$VERSION" \
    --install-location "/Applications" \
    "$PKG_COMPONENT"

echo "▸ Building distribution .pkg + signing with Developer ID Installer"
PKG_RESOURCES="$BUILD_DIR/pkg-resources"
mkdir -p "$PKG_RESOURCES"
cp "$PROJECT_DIR/marketing/EULA.txt" "$PKG_RESOURCES/EULA.txt"

DIST_XML="$BUILD_DIR/distribution.xml"
cat > "$DIST_XML" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>${APP_NAME}</title>
    <organization>fr.misilab</organization>
    <license file="EULA.txt" mime-type="text/plain"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <os-version min="14.0"/>
    <choices-outline>
        <line choice="default">
            <line choice="${BUNDLE_ID}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${BUNDLE_ID}" visible="false">
        <pkg-ref id="${BUNDLE_ID}"/>
    </choice>
    <pkg-ref id="${BUNDLE_ID}" version="${VERSION}" onConclusion="none">${APP_NAME}-component.pkg</pkg-ref>
</installer-gui-script>
EOF

productbuild \
    --distribution "$DIST_XML" \
    --package-path "$BUILD_DIR" \
    --resources "$PKG_RESOURCES" \
    --sign "$INSTALLER_SIGN_ID" \
    --timestamp \
    "$PKG_PATH"

rm -rf "$PKG_COMPONENT" "$DIST_XML" "$PKG_RESOURCES"

# ─────────────────────────────────────────────────────────────────────
# 6. Notarize the PKG
# ─────────────────────────────────────────────────────────────────────
echo "▸ Submitting PKG to notary service"
xcrun notarytool submit "$PKG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "▸ Stapling ticket to PKG"
xcrun stapler staple "$PKG_PATH"
xcrun stapler validate "$PKG_PATH"

# ─────────────────────────────────────────────────────────────────────
# 7. Sparkle: sign PKG for auto-updates + emit appcast entry
# ─────────────────────────────────────────────────────────────────────
SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -name sign_update -type f 2>/dev/null | head -1)
APPCAST_SNIPPET="$BUILD_DIR/appcast-entry.xml"
if [ -n "$SIGN_UPDATE" ] && [ -x "$SIGN_UPDATE" ]; then
    echo "▸ Signing PKG for Sparkle"
    # sign_update outputs: sparkle:edSignature="…" length="…"
    SIG_LINE=$("$SIGN_UPDATE" "$PKG_PATH")
    PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
    PKG_URL="https://github.com/misilab/misicopy/releases/download/v${VERSION}/${APP_NAME}-${VERSION}.pkg"

    cat > "$APPCAST_SNIPPET" <<EOF
        <item>
            <title>Version ${VERSION}</title>
            <pubDate>${PUB_DATE}</pubDate>
            <sparkle:version>${BUILD_NUMBER}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <sparkle:installationType>package</sparkle:installationType>
            <description><![CDATA[
                <ul>
                    <li>TODO: ajouter les notes de version ici</li>
                </ul>
            ]]></description>
            <enclosure url="${PKG_URL}"
                       type="application/x-newton-compatible-pkg"
                       ${SIG_LINE}/>
        </item>
EOF
    # Insert snippet into both appcast files (root + marketing/).
    # The root appcast.xml is the one served by raw.githubusercontent.com
    # and read by Sparkle. marketing/appcast.xml is kept in sync as a backup.
    for APPCAST_FILE in "$PROJECT_DIR/appcast.xml" "$PROJECT_DIR/marketing/appcast.xml"; do
        if [ -f "$APPCAST_FILE" ]; then
            SNIPPET_CONTENT=$(cat "$APPCAST_SNIPPET")
            # Insert after <language>fr</language>
            awk -v snippet="$SNIPPET_CONTENT" '
                /<language>fr<\/language>/ { print; print ""; print snippet; next }
                { print }
            ' "$APPCAST_FILE" > "${APPCAST_FILE}.tmp" && mv "${APPCAST_FILE}.tmp" "$APPCAST_FILE"
            echo "  ✓ Appcast entry inserted into: $APPCAST_FILE"
        fi
    done
    echo "  ✓ Appcast snippet saved to: $APPCAST_SNIPPET"
else
    echo "⚠ sign_update introuvable — Sparkle step skipped."
    echo "  Build first: xcodebuild -resolvePackageDependencies"
fi

# ─────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────
SIZE=$(du -h "$PKG_PATH" | cut -f1)
echo ""
echo "✅ Release ready:"
echo "   $PKG_PATH ($SIZE)"
echo ""
echo "Next:"
echo "  1. Edit the <description> TODO in appcast.xml and marketing/appcast.xml"
echo "  2. git add appcast.xml marketing/appcast.xml && git commit && git push"
echo "  3. Upload $PKG_PATH as GitHub Release asset:"
echo "     https://github.com/misilab/misicopy/releases/new?tag=v${VERSION}"
echo "  4. Sparkle will pick it up within minutes on user Macs"
