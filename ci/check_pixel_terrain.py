#!/usr/bin/env python3
"""Validate optional 32px grass tiles before Godot imports them.

Exact edges make every combination of 12 meadow tiles seamless.
This does not judge artistic quality or terrain transition sprites.
"""
from itertools import product
from pathlib import Path
from PIL import Image

ATLAS = Path("assets/2d/eternia/pixel/grass_32_atlas.png")
TILE_SIZE = 32
COLUMNS = 4
ROWS = 3


def validate_atlas(path: Path, tile_size: int = TILE_SIZE, columns: int = COLUMNS, rows: int = ROWS) -> int:
    expected = (tile_size * columns, tile_size * rows)
    if tile_size < 1 or columns < 1 or rows < 1:
        raise ValueError("Tile dimensions and grid must be positive")
    with Image.open(path) as raw:
        if raw.size != expected:
            raise ValueError(f"Expected {expected} atlas, got {raw.size}: {path}")
        image = raw.convert("RGBA")

    tiles = [image.crop((x * tile_size, y * tile_size,
                         (x + 1) * tile_size, (y + 1) * tile_size))
             for y in range(rows) for x in range(columns)]
    for index, tile in enumerate(tiles):
        if tile.getchannel("A").getextrema() != (255, 255):
            raise ValueError(f"Grass tile {index} has transparency; ground must be opaque")

    left = [tile.crop((0, 0, 1, tile_size)).tobytes() for tile in tiles]
    right = [tile.crop((tile_size - 1, 0, tile_size, tile_size)).tobytes() for tile in tiles]
    top = [tile.crop((0, 0, tile_size, 1)).tobytes() for tile in tiles]
    bottom = [tile.crop((0, tile_size - 1, tile_size, tile_size)).tobytes() for tile in tiles]
    for a, b in product(range(len(tiles)), repeat=2):
        if right[a] != left[b]:
            raise ValueError(f"Horizontal seam: right of tile {a} != left of tile {b}")
        if bottom[a] != top[b]:
            raise ValueError(f"Vertical seam: bottom of tile {a} != top of tile {b}")
    return len(tiles)


def main() -> None:
    if not ATLAS.is_file():
        print("Pixel grass atlas not installed - QA skipped; 64px fallback remains active")
        return
    count = validate_atlas(ATLAS)
    print(f"Pixel grass atlas PASS: {count} tiles, {count * count} pairs, exact edge matching")


if __name__ == "__main__":
    main()
