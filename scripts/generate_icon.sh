#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$ROOT_DIR/assets"
SOURCE_SVG="$ASSET_DIR/heimama-icon.svg"
STATUS_SVG="$ASSET_DIR/heimama-status-template.svg"
ICONSET_DIR="$ASSET_DIR/heimama-icon.iconset"
OUTPUT_ICNS="$ASSET_DIR/heimama-icon.icns"
STATUS_PNG="$ASSET_DIR/heimama-status-template.png"
BASE_PNG="$ASSET_DIR/heimama-icon-1024.png"

if [[ ! -f "$SOURCE_SVG" ]]; then
    echo "Missing icon source: $SOURCE_SVG" >&2
    exit 1
fi

if [[ ! -f "$STATUS_SVG" ]]; then
    echo "Missing status icon source: $STATUS_SVG" >&2
    exit 1
fi

mkdir -p "$ASSET_DIR"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

if command -v qlmanage >/dev/null 2>&1; then
    rm -f "$BASE_PNG"
    qlmanage -t -s 1024 -o "$ASSET_DIR" "$SOURCE_SVG" >/dev/null 2>&1 || true
    if [[ -f "$ASSET_DIR/$(basename "$SOURCE_SVG").png" ]]; then
        mv "$ASSET_DIR/$(basename "$SOURCE_SVG").png" "$BASE_PNG"
    fi
fi

if [[ ! -f "$BASE_PNG" ]]; then
    python3 - "$SOURCE_SVG" "$BASE_PNG" <<'PY'
import re
import sys
from xml.etree import ElementTree as ET

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.stderr.write("Pillow is required when qlmanage cannot render SVG.\n")
    raise

svg_path, out_path = sys.argv[1], sys.argv[2]
tree = ET.parse(svg_path)
root = tree.getroot()
image = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
draw = ImageDraw.Draw(image)

def color(value):
    value = value.strip()
    if value.startswith("#") and len(value) == 7:
        return tuple(int(value[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
    raise ValueError(f"Unsupported color: {value}")

def numbers(value):
    return [float(part) for part in re.findall(r"-?\d+(?:\.\d+)?", value)]

for element in root:
    tag = element.tag.split("}")[-1]
    fill = color(element.attrib.get("fill", "#000000"))
    if tag == "rect":
        x = float(element.attrib.get("x", 0))
        y = float(element.attrib.get("y", 0))
        width = float(element.attrib["width"])
        height = float(element.attrib["height"])
        radius = float(element.attrib.get("rx", 0))
        draw.rounded_rectangle((x, y, x + width, y + height), radius=radius, fill=fill)
    elif tag == "circle":
        cx = float(element.attrib["cx"])
        cy = float(element.attrib["cy"])
        r = float(element.attrib["r"])
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill)
    elif tag == "path":
        pts = numbers(element.attrib["d"])
        coords = list(zip(pts[0::2], pts[1::2]))
        if coords:
            draw.polygon(coords, fill=fill)

image.save(out_path)
PY
fi

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$BASE_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    sips -z "$double_size" "$double_size" "$BASE_PNG" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"
rm -rf "$ICONSET_DIR"
rm -f "$BASE_PNG"

rm -f "$STATUS_PNG"
python3 - "$STATUS_PNG" <<'PY'
import sys
from PIL import Image, ImageDraw

out_path = sys.argv[1]
scale = 4
size = 64
mask = Image.new("L", (size * scale, size * scale), 0)
draw = ImageDraw.Draw(mask)

def pts(values):
    return [(int(x * scale), int(y * scale)) for x, y in values]

draw.polygon(
    pts([
        (45, 8), (52, 12), (56, 18), (54, 25), (44, 32), (50, 35),
        (55, 43), (50, 52), (28, 52), (15, 48), (8, 40), (7, 28),
        (13, 17), (24, 10), (35, 8)
    ]),
    fill=255,
)
draw.polygon(pts([(19, 5), (24, 15), (16, 20), (12, 14)]), fill=255)
draw.polygon(pts([(28, 8), (35, 5), (36, 14), (29, 17)]), fill=255)

draw.polygon(pts([(15, 29), (36, 29), (30, 35), (10, 35)]), fill=0)
draw.polygon(pts([(8, 40), (30, 40), (24, 46), (11, 46)]), fill=0)
draw.ellipse((44 * scale, 19 * scale, 49 * scale, 24 * scale), fill=0)

mask = mask.resize((size, size), Image.Resampling.LANCZOS)
image = Image.new("RGBA", (size, size), (0, 0, 0, 255))
image.putalpha(mask)
image.save(out_path)
PY

echo "Created $OUTPUT_ICNS"
echo "Created $STATUS_PNG"
