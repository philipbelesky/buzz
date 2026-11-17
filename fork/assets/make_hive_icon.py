"""Draws the fork's "Hive" app icon and writes every size into the iOS AppIcon set.

FORK: fork-only file (see FORK.md). Run from the repo root:

    uv run --with pillow python fork/assets/make_hive_icon.py

A blue speech bubble with three white hexagons as typing dots, on white:
Safari's palette.
Drawn at 4x and downsampled; corners are rounded by blurring and re-thresholding.
"""
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 4096  # supersampled canvas; final 1024
k = S / 1024

def hexagon(cx, cy, r, rot=-90):
    return [(cx + r * math.cos(math.radians(rot + 60 * i)), cy + r * math.sin(math.radians(rot + 60 * i))) for i in range(6)]

def rounded(mask, radius):
    # Blur-and-threshold rounds convex corners of a shape mask.
    blurred = mask.filter(ImageFilter.GaussianBlur(radius))
    return blurred.point(lambda v: 255 if v >= 128 else 0)

def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

def vertical_gradient(top, bottom, y0=0, y1=S):
    """An RGB canvas shading from `top` at y0 to `bottom` at y1."""
    ramp = Image.linear_gradient("L").resize((S, max(1, int(y1 - y0))))
    band = Image.composite(Image.new("RGB", ramp.size, bottom), Image.new("RGB", ramp.size, top), ramp)
    canvas = Image.new("RGB", (S, S), top)
    canvas.paste(band, (0, int(y0)))
    canvas.paste(Image.new("RGB", (S, S - int(y1)), bottom), (0, int(y1)))
    return canvas

# Background: Safari's near-white, a touch cooler at the bottom.
img = vertical_gradient((255, 255, 255), (236, 238, 243))

# Bubble: a circle with a tail at the lower left, like a speech bubble.
cx, cy, r = 512 * k, 500 * k, 372 * k
bubble = Image.new("L", (S, S), 0)
d = ImageDraw.Draw(bubble)
d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
def on_circle(degrees, radius=r):
    a = math.radians(degrees)
    return (cx + radius * math.cos(a), cy + radius * math.sin(a))
# Tail: a wedge whose base spans the circle around 135° (lower left).
d.polygon([on_circle(118), on_circle(152), (cx - 0.93 * r, cy + 0.98 * r)], fill=255)
bubble = rounded(bubble, 22 * k)

# Soft shadow under the bubble.
shadow = bubble.filter(ImageFilter.GaussianBlur(36 * k)).point(lambda v: int(v * 0.30))
shadow = ImageChops.offset(shadow, 0, int(22 * k))
img = Image.composite(Image.new("RGB", (S, S), (40, 70, 140)), img, shadow)

# Safari's blue: bright cyan at the top to a deep blue at the bottom.
blue = vertical_gradient((40, 205, 255), (18, 98, 240), cy - r, cy + r)
img = Image.composite(blue, img, bubble)

# A thin lighter rim inside the edge, as on Safari's dial.
inner = rounded(bubble.filter(ImageFilter.MinFilter(int(18 * k) | 1)), 8 * k)
rim = ImageChops.subtract(bubble, inner).point(lambda v: int(v * 0.35))
img = Image.composite(Image.new("RGB", (S, S), (255, 255, 255)), img, rim)

# Three white hexagons inside, like a typing indicator.
dots = Image.new("L", (S, S), 0)
dd = ImageDraw.Draw(dots)
for dx in (-172, 0, 172):
    dd.polygon(hexagon(cx + dx * k, cy, 70 * k), fill=255)
dots = rounded(dots, 10 * k)
img = Image.composite(Image.new("RGB", (S, S), (255, 255, 255)), img, dots)

master = img.resize((1024, 1024), Image.LANCZOS)
iconset = Path(__file__).resolve().parents[2] / "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"
for entry in json.loads((iconset / "Contents.json").read_text())["images"]:
    px = round(float(entry["size"].split("x")[0]) * int(entry["scale"].rstrip("x")))
    master.resize((px, px), Image.LANCZOS).save(iconset / entry["filename"], optimize=True)
master.save(Path(__file__).with_name("hive-icon-1024.png"))
