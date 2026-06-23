# VibeBlank App Icon Refresh Design

## Goal

Replace VibeBlank's Dock, Finder, and packaged app icon with the approved generated black privacy-terminal mark while keeping the app name, menu-bar behavior, and packaging flow unchanged.

## Source Artwork

- Use `/Users/bytedance/Downloads/ChatGPT Image 2026年6月23日 19_39_20.png` as the visual source.
- Use only the upper rounded-square app icon artwork.
- Exclude the lower `黑码码` wordmark, underline, and English tagline from the app icon.
- Do not use `/Users/bytedance/Downloads/ChatGPT Image 2026年6月23日 19_39_11.png` for the shipped app icon; it remains a possible future glyph reference.

## Design

- Produce a clean 1024 x 1024 RGBA app-icon source from the approved image.
- Center the rounded-square icon mark on a transparent canvas so Dock and Finder display the icon shape rather than the source image's white presentation background.
- Preserve the visual identity of the approved image: black rounded square, dark terminal/privacy panel, diagonal privacy cover, and teal signal accents.
- Avoid tiny text inside the icon. The product name remains provided by `CFBundleDisplayName=黑码码`, Finder, and the DMG volume/app label.
- Keep `assets/heimama-icon.icns` and `CFBundleIconFile=heimama-icon` as the app bundle contract so existing packaging scripts and docs stay stable.
- Keep `assets/heimama-status-template.png` unchanged. The menu-bar icon should remain a simple template image that macOS can tint correctly at 18 x 18.

## Implementation Boundaries

- Modify `scripts/generate_icon.sh` so the app icon can be generated from a PNG source while continuing to generate the menu-bar template image.
- Add the approved generated image into `assets/` as the reproducible source for the app icon.
- Regenerate `assets/heimama-icon.icns` from that source.
- Do not rename the app, bundle identifier, DMG volume, or status item assets.

## Acceptance

- `bash scripts/generate_icon.sh` creates `assets/heimama-icon.icns` from the approved PNG source.
- The generated `.icns` contains the standard iconset sizes: 16, 32, 128, 256, and 512 points with `@2x` variants.
- `bash scripts/package_app.sh` creates `dist/VibeBlank.app`, `dist/VibeBlank.zip`, and `dist/VibeBlank.dmg`.
- `dist/VibeBlank.app/Contents/Info.plist` still contains `CFBundleIconFile=heimama-icon`.
- `dist/VibeBlank.app/Contents/Resources/heimama-icon.icns` exists and is non-empty.
- The packaged app icon visually shows the new rounded black privacy-terminal mark without the wordmark or tagline.
- The menu-bar status icon still loads from `heimama-status-template.png` and remains template-safe.
