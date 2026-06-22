#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="VibeBlank"
APP_DISPLAY_NAME="黑码码"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$PRODUCT_NAME.app"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_FILE="$DIST_DIR/$PRODUCT_NAME.dmg"
DMG_RW_FILE="$DIST_DIR/$PRODUCT_NAME-rw.dmg"
DMG_MOUNT_DIR="$DIST_DIR/dmg-mount"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_NAME="heimama-icon"
ICON_FILE="$ROOT_DIR/assets/$ICON_NAME.icns"
STATUS_ICON_NAME="heimama-status-template.png"
STATUS_ICON_FILE="$ROOT_DIR/assets/$STATUS_ICON_NAME"
ONBOARDING_GUIDE_NAME="onboarding-guide.png"
ONBOARDING_GUIDE_FILE="$ROOT_DIR/assets/$ONBOARDING_GUIDE_NAME"
DMG_BACKGROUND_NAME="dmg-background.png"
DMG_BACKGROUND_FILE="$ROOT_DIR/assets/$DMG_BACKGROUND_NAME"
DMG_WINDOW_WIDTH=1180
DMG_WINDOW_HEIGHT=738
DMG_WINDOW_LEFT=140
DMG_WINDOW_TOP=90
DMG_ICON_SIZE=164
DMG_APP_ICON_X=220
DMG_APP_ICON_Y=388
DMG_APPLICATIONS_ICON_X=966
DMG_APPLICATIONS_ICON_Y=388

cleanup_dmg_mount() {
    if [[ -d "$DMG_MOUNT_DIR" ]]; then
        hdiutil detach "$DMG_MOUNT_DIR" >/dev/null 2>&1 || true
    fi
}
trap cleanup_dmg_mount EXIT

cd "$ROOT_DIR"

if [[ ! -f "$ICON_FILE" || ! -f "$STATUS_ICON_FILE" ]]; then
    bash "$ROOT_DIR/scripts/generate_icon.sh"
fi

if [[ ! -f "$DMG_BACKGROUND_FILE" || ! -f "$ONBOARDING_GUIDE_FILE" ]]; then
    echo "Missing packaging asset. Expected $DMG_BACKGROUND_FILE and $ONBOARDING_GUIDE_FILE" >&2
    exit 1
fi

swift build -c release --product "$PRODUCT_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_DIR/$PRODUCT_NAME" "$MACOS_DIR/$PRODUCT_NAME"
chmod +x "$MACOS_DIR/$PRODUCT_NAME"
cp "$ICON_FILE" "$RESOURCES_DIR/$ICON_NAME.icns"
cp "$STATUS_ICON_FILE" "$RESOURCES_DIR/$STATUS_ICON_NAME"
cp "$ONBOARDING_GUIDE_FILE" "$RESOURCES_DIR/$ONBOARDING_GUIDE_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>黑码码</string>
    <key>CFBundleExecutable</key>
    <string>VibeBlank</string>
    <key>CFBundleIconFile</key>
    <string>heimama-icon</string>
    <key>CFBundleIdentifier</key>
    <string>local.vibeblank.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>黑码码</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.4.0</string>
    <key>CFBundleVersion</key>
    <string>4</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

rm -f "$DIST_DIR/$PRODUCT_NAME.zip" "$DMG_FILE" "$DMG_RW_FILE"
(
    cd "$DIST_DIR"
    ditto -c -k --keepParent "$PRODUCT_NAME.app" "$PRODUCT_NAME.zip"
)

rm -rf "$DMG_STAGING_DIR" "$DMG_MOUNT_DIR"
mkdir -p "$DMG_STAGING_DIR/.background"
ditto "$APP_DIR" "$DMG_STAGING_DIR/$APP_DISPLAY_NAME.app"
sips "$DMG_BACKGROUND_FILE" \
    --resampleHeightWidth "$DMG_WINDOW_HEIGHT" "$DMG_WINDOW_WIDTH" \
    --out "$DMG_STAGING_DIR/.background/$DMG_BACKGROUND_NAME" >/dev/null
ln -s /Applications "$DMG_STAGING_DIR/Applications"
if [[ -d "/Volumes/$APP_DISPLAY_NAME" ]]; then
    hdiutil detach "/Volumes/$APP_DISPLAY_NAME" >/dev/null 2>&1 || true
fi
hdiutil create \
    -volname "$APP_DISPLAY_NAME" \
    -srcfolder "$DMG_STAGING_DIR" \
    -ov \
    -format UDRW \
    "$DMG_RW_FILE" >/dev/null

mkdir -p "$DMG_MOUNT_DIR"
hdiutil attach -readwrite -mountpoint "$DMG_MOUNT_DIR" "$DMG_RW_FILE" >/dev/null
osascript <<APPLESCRIPT
tell application "Finder"
    set dmgFolder to POSIX file "$DMG_MOUNT_DIR" as alias
    open dmgFolder
    delay 0.5
    set dmgWindow to container window of dmgFolder
    set current view of dmgWindow to icon view
    try
        set toolbar visible of dmgWindow to false
    end try
    try
        set statusbar visible of dmgWindow to false
    end try
    set bounds of dmgWindow to {$DMG_WINDOW_LEFT, $DMG_WINDOW_TOP, $((DMG_WINDOW_LEFT + DMG_WINDOW_WIDTH)), $((DMG_WINDOW_TOP + DMG_WINDOW_HEIGHT))}
    set viewOptions to the icon view options of dmgWindow
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to $DMG_ICON_SIZE
    set background picture of viewOptions to POSIX file "$DMG_MOUNT_DIR/.background/$DMG_BACKGROUND_NAME"
    set position of item "$APP_DISPLAY_NAME.app" of dmgFolder to {$DMG_APP_ICON_X, $DMG_APP_ICON_Y}
    set position of item "Applications" of dmgFolder to {$DMG_APPLICATIONS_ICON_X, $DMG_APPLICATIONS_ICON_Y}
    update dmgFolder without registering applications
    delay 1
    close dmgWindow
end tell
APPLESCRIPT
sync
for _ in {1..10}; do
    [[ -s "$DMG_MOUNT_DIR/.DS_Store" ]] && break
    sleep 0.5
done
if [[ ! -s "$DMG_MOUNT_DIR/.DS_Store" ]]; then
    echo "Failed to write Finder layout .DS_Store into DMG." >&2
    exit 1
fi
hdiutil detach "$DMG_MOUNT_DIR" >/dev/null
hdiutil convert "$DMG_RW_FILE" -format UDZO -imagekey zlib-level=9 -o "$DMG_FILE" >/dev/null
rm -rf "$DMG_STAGING_DIR" "$DMG_MOUNT_DIR" "$DMG_RW_FILE"

echo "Packaged $APP_DIR"
echo "Created $DIST_DIR/$PRODUCT_NAME.zip"
echo "Created $DMG_FILE"
