"""Draws the fork's "Hive" app icon and writes every size into the iOS AppIcon set.

FORK: fork-only file (see FORK.md). Run from the repo root:

    uv run --with pillow python fork/assets/make_hive_icon.py

A white hexagonal speech bubble with three honey hexagons, on a honey gradient.
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

# Background: honey gradient, lighter top-left to deeper bottom-right.
top, bottom = (255, 206, 72), (240, 146, 0)
grad = Image.linear_gradient("L").resize((2 * S, 2 * S)).rotate(-20, resample=Image.BICUBIC).crop((S // 2, S // 2, S // 2 + S, S // 2 + S))
bg = Image.composite(Image.new("RGB", (S, S), bottom), Image.new("RGB", (S, S), top), grad)

# Bubble: a pointy-top hexagon with a tail at the lower left.
cx, cy, r = 512 * k, 488 * k, 318 * k
bubble = Image.new("L", (S, S), 0)
d = ImageDraw.Draw(bubble)
d.polygon(hexagon(cx, cy, r), fill=255)
# Tail: a wedge growing out of the lower-left corner, pointing down-left.
pts = hexagon(cx, cy, r)
bottom_v = max(pts, key=lambda p: p[1])
L = min((p for p in pts if p[1] > cy), key=lambda p: p[0])
UL = min((p for p in pts if p[1] < cy), key=lambda p: p[0])
def towards(p, q, t):
    return (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t)
base1 = towards(L, UL, 0.10)
base2 = towards(L, bottom_v, 0.28)
tip = (L[0] - 46 * k, L[1] + 118 * k)
d.polygon([base1, base2, tip], fill=255)
bubble = rounded(bubble, 26 * k)

# Soft shadow under the bubble.
shadow = bubble.filter(ImageFilter.GaussianBlur(40 * k)).point(lambda v: int(v * 0.28))
shadow = ImageChops.offset(shadow, 0, int(26 * k))
img = Image.composite(Image.new("RGB", (S, S), (150, 80, 0)), bg, shadow)
img = Image.composite(Image.new("RGB", (S, S), (255, 255, 255)), img, bubble)

# Three small hexagons inside, like a typing indicator.
dots = Image.new("L", (S, S), 0)
dd = ImageDraw.Draw(dots)
for i, dx in enumerate((-118, 0, 118)):
    dd.polygon(hexagon(cx + dx * k, cy + 6 * k, 50 * k), fill=255)
dots = rounded(dots, 9 * k)
colours = [(245, 170, 20), (240, 150, 0), (225, 128, 0)]
for i, dx in enumerate((-118, 0, 118)):
    m = Image.new("L", (S, S), 0)
    ImageDraw.Draw(m).rectangle([cx + (dx - 70) * k, 0, cx + (dx + 70) * k, S], fill=255)
    img = Image.composite(Image.new("RGB", (S, S), colours[i]), img, ImageChops.multiply(dots, m))

master = img.resize((1024, 1024), Image.LANCZOS)
iconset = Path(__file__).resolve().parents[2] / "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"
for entry in json.loads((iconset / "Contents.json").read_text())["images"]:
    px = round(float(entry["size"].split("x")[0]) * int(entry["scale"].rstrip("x")))
    master.resize((px, px), Image.LANCZOS).save(iconset / entry["filename"], optimize=True)
master.save(Path(__file__).with_name("hive-icon-1024.png"))
