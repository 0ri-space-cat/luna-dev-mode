#!/usr/bin/env python3
"""Reject visible 64px tile seams and missing/unusable illustrated assets."""
from itertools import product
from pathlib import Path
from PIL import Image

ROOT = Path("assets/2d/eternia")
tiles = []
for i in range(1, 13):
    path = ROOT / "terrain" / f"grass_{i}.png"
    assert path.is_file(), f"Missing {path}"
    with Image.open(path) as item:
        assert item.size == (64, 64), f"Wrong tile dimensions {path}: {item.size}"
        tiles.append(item.convert("RGBA").copy())
# The four edges must be pixel-identical to the adjoining edges of ANY tile.
for a, b in product(tiles, repeat=2):
    left = list(a.crop((63, 0, 64, 64)).getdata())
    right = list(b.crop((0, 0, 1, 64)).getdata())
    top = list(a.crop((0, 63, 64, 64)).getdata())
    bottom = list(b.crop((0, 0, 64, 1)).getdata())
    assert left == right, "Visible vertical seam between grass variants"
    assert top == bottom, "Visible horizontal seam between grass variants"

for name in ["flower_bush", "moss_arch", "pink_crystals",
             "oracle_pedestal", "walking_fridge", "berry_tree"]:
    path = ROOT / "props" / (name + ".webp")
    assert path.is_file(), f"Missing painted prop {path}"
    with Image.open(path) as prop:
        assert prop.size == (256, 256), (path, prop.size)
        assert "A" in prop.getbands(), f"Missing alpha channel {path}"
        extrema = prop.getchannel("A").getextrema()
        assert extrema[0] == 0 and extrema[1] > 240, (
            f"Prop lacks a real transparent background: {path}, alpha={extrema}"
        )
print("Eternia art asset checks PASS: 12 seamless grass tiles, 144 tile pairs, 6 transparent props")
