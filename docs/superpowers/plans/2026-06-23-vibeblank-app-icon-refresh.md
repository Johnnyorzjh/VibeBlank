# VibeBlank App Icon Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the packaged VibeBlank app icon with the approved generated black privacy-terminal mark.

**Architecture:** Keep the existing app bundle contract: `CFBundleIconFile=heimama-icon` and `assets/heimama-icon.icns`. Add a reproducible PNG source in `assets/`, update `scripts/generate_icon.sh` to build the app icon from that PNG source, and leave the menu-bar template image generation unchanged.

**Tech Stack:** Bash, Python 3, Pillow, macOS `sips`, macOS `iconutil`, SwiftPM packaging scripts.

## Global Constraints

- Use `/Users/bytedance/Downloads/ChatGPT Image 2026年6月23日 19_39_20.png` as the approved visual source.
- Use only the upper rounded-square app icon artwork.
- Exclude the lower `黑码码` wordmark, underline, and English tagline from the app icon.
- Keep `assets/heimama-icon.icns` and `CFBundleIconFile=heimama-icon` as the app bundle contract.
- Keep `assets/heimama-status-template.png` unchanged.
- Do not rename the app, bundle identifier, DMG volume, or status item assets.

---

### Task 1: Create Reproducible App Icon Source

**Files:**
- Create: `assets/heimama-icon-source.png`

**Interfaces:**
- Consumes: `/Users/bytedance/Downloads/ChatGPT Image 2026年6月23日 19_39_20.png`
- Produces: `assets/heimama-icon-source.png`, a 1024 x 1024 RGBA PNG that later icon generation consumes.

- [x] **Step 1: Generate the cropped source image**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw

source = Path("/Users/bytedance/Downloads/ChatGPT Image 2026年6月23日 19_39_20.png")
out = Path("assets/heimama-icon-source.png")
image = Image.open(source).convert("RGBA")

# Crop the upper rounded-square icon body and apply a clean alpha mask.
box = (354, 185, 904, 748)
icon = image.crop(box)
w, h = icon.size
scale = 4
mask = Image.new("L", (w * scale, h * scale), 0)
draw = ImageDraw.Draw(mask)
radius = int(min(w, h) * 0.22 * scale)
draw.rounded_rectangle((0, 0, w * scale - 1, h * scale - 1), radius=radius, fill=255)
mask = mask.resize((w, h), Image.Resampling.LANCZOS)
icon.putalpha(mask)

canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
icon.thumbnail((884, 884), Image.Resampling.LANCZOS)
x = (1024 - icon.width) // 2
y = (1024 - icon.height) // 2
canvas.alpha_composite(icon, (x, y))
canvas.save(out)
PY
```

Expected: `assets/heimama-icon-source.png` exists.

- [x] **Step 2: Verify image dimensions**

Run:

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha assets/heimama-icon-source.png
```

Expected output includes:

```text
pixelWidth: 1024
pixelHeight: 1024
hasAlpha: yes
```

### Task 2: Generate And Package New App Icon

**Files:**
- Modify: `scripts/generate_icon.sh`
- Modify: `assets/heimama-icon.icns`
- Test: `dist/VibeBlank.app/Contents/Info.plist`
- Test: `dist/VibeBlank.app/Contents/Resources/heimama-icon.icns`

**Interfaces:**
- Consumes: `assets/heimama-icon-source.png`
- Produces: `assets/heimama-icon.icns`, `dist/VibeBlank.app`, `dist/VibeBlank.zip`, and `dist/VibeBlank.dmg`.

- [x] **Step 1: Update app icon source path in the generation script**

Change the top of `scripts/generate_icon.sh` so app icon generation uses the PNG source:

```bash
SOURCE_IMAGE="$ASSET_DIR/heimama-icon-source.png"
STATUS_SVG="$ASSET_DIR/heimama-status-template.svg"
ICONSET_DIR="$ASSET_DIR/heimama-icon.iconset"
OUTPUT_ICNS="$ASSET_DIR/heimama-icon.icns"
STATUS_PNG="$ASSET_DIR/heimama-status-template.png"
BASE_PNG="$ASSET_DIR/heimama-icon-1024.png"
```

The script must fail with `Missing icon source: $SOURCE_IMAGE` if the PNG source is absent.

- [x] **Step 2: Replace the SVG rendering branch with PNG normalization**

Copy `SOURCE_IMAGE` to `BASE_PNG` as a normalized 1024 x 1024 PNG before the existing `sips` iconset loop:

```bash
python3 - "$SOURCE_IMAGE" "$BASE_PNG" <<'PY'
import sys
from PIL import Image

source_path, out_path = sys.argv[1], sys.argv[2]
image = Image.open(source_path).convert("RGBA")
if image.size != (1024, 1024):
    image = image.resize((1024, 1024), Image.Resampling.LANCZOS)
image.save(out_path)
PY
```

- [x] **Step 3: Regenerate the `.icns` file**

Run:

```bash
bash scripts/generate_icon.sh
```

Expected output includes:

```text
Created /Users/bytedance/Documents/AI/assets/heimama-icon.icns
Created /Users/bytedance/Documents/AI/assets/heimama-status-template.png
```

- [x] **Step 4: Verify generated icon asset**

Run:

```bash
test -s assets/heimama-icon.icns
file assets/heimama-icon.icns
```

Expected: `file` reports `Mac OS X icon`.

- [x] **Step 5: Package the app**

Run:

```bash
bash scripts/package_app.sh
```

Expected output includes:

```text
Packaged /Users/bytedance/Documents/AI/dist/VibeBlank.app
Created /Users/bytedance/Documents/AI/dist/VibeBlank.zip
Created /Users/bytedance/Documents/AI/dist/VibeBlank.dmg
```

- [x] **Step 6: Verify bundle icon contract**

Run:

```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" dist/VibeBlank.app/Contents/Info.plist
test -s dist/VibeBlank.app/Contents/Resources/heimama-icon.icns
```

Expected output:

```text
heimama-icon
```
