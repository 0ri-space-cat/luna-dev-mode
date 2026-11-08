#!/usr/bin/env python3
"""Check real ImageGen ground export for seamless tile edges."""
from pathlib import Path
from PIL import Image

path = Path("assets/2d/eternia/pixel/ground_base.png")
assert path.is_file(), f"Missing imported ImageGen ground: {path}"
with Image.open(path) as im:
    assert im.size == (32, 32), (path, im.size)
    image = im.convert("RGBA")
    assert image.getchannel("A").getextrema() == (255, 255), "Ground may not have holes"
    assert list(image.crop((0, 0, 1, 32)).getdata()) == list(image.crop((31, 0, 32, 32)).getdata()), "Grass vertical seam"
    assert list(image.crop((0, 0, 32, 1)).getdata()) == list(image.crop((0, 31, 32, 32)).getdata()), "Grass horizontal seam"
print("ImageGen ground seamlessness PASS (32x32)")
