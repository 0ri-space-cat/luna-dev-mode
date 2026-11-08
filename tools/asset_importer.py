#!/usr/bin/env python3
"""LUNA asset pipeline: deterministic RGBA grid slicing + tile seam validation.

Usage: python3 tools/asset_importer.py art/source/sheet.json
Requires: pip install Pillow
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path
from PIL import Image

SAFE_NAME = re.compile(r"^[a-z][a-z0-9_]{0,63}$")
MAX_SIZE = 8192

def edge_error(image: Image.Image) -> float:
    """Maximum channel difference for opposite edges of a seamless tile."""
    width, height = image.size
    if width < 2 or height < 2:
        raise ValueError("Tile must be at least 2x2")
    pixels = image.convert("RGBA")
    worst = 0
    for y in range(height):
        a, b = pixels.getpixel((0, y)), pixels.getpixel((width - 1, y))
        worst = max(worst, *(abs(a[c] - b[c]) for c in range(4)))
    for x in range(width):
        a, b = pixels.getpixel((x, 0)), pixels.getpixel((x, height - 1))
        worst = max(worst, *(abs(a[c] - b[c]) for c in range(4)))
    return float(worst)

def assemble(manifest_path: str | Path) -> dict:
    path = Path(manifest_path).resolve()
    cfg = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(cfg, dict):
        raise ValueError("Manifest root must be a JSON object")
    source_name = str(cfg.get("source", ""))
    if Path(source_name).name != source_name or not source_name.lower().endswith(".png"):
        raise ValueError("Source must be a PNG filename inside manifest directory")
    source = path.parent / source_name
    cell = cfg.get("cell_size")
    grid = cfg.get("grid")
    if not (isinstance(cell, list) and isinstance(grid, list) and len(cell) == len(grid) == 2):
        raise ValueError("cell_size and grid must be [width, height]")
    width, height = cell
    columns, rows = grid
    if any(type(v) is not int or v < 1 for v in (width, height, columns, rows)):
        raise ValueError("Grid dimensions must be positive integers")
    if width * columns > MAX_SIZE or height * rows > MAX_SIZE:
        raise ValueError("Image dimensions exceed importer safety limit")
    items = cfg.get("sprites")
    if not isinstance(items, list) or not items or len(items) > columns * rows:
        raise ValueError("Invalid sprite list")
    output_dir = str(cfg.get("output", "export"))
    if not SAFE_NAME.fullmatch(output_dir):
        raise ValueError("Output must be a simple safe directory name")
    with Image.open(source) as source_image:
        image = source_image.convert("RGBA")
    if image.size != (width * columns, height * rows):
        raise ValueError(f"Atlas dimensions {image.size} don't match grid {(width*columns, height*rows)}")
    names, cells = set(), set()
    staged = []
    index = []
    for item in items:
        if not isinstance(item, dict):
            raise ValueError("Invalid sprite item")
        name = item.get("name")
        xy = item.get("cell")
        if not isinstance(name, str) or not SAFE_NAME.fullmatch(name) or name in names:
            raise ValueError("Invalid or duplicate sprite name")
        if not (isinstance(xy, list) and len(xy) == 2 and all(type(n) is int for n in xy)):
            raise ValueError(f"Invalid cell for {name}")
        x, y = xy
        if not (0 <= x < columns and 0 <= y < rows) or (x, y) in cells:
            raise ValueError("Cell out of range or duplicated")
        names.add(name)
        cells.add((x, y))
        pivot = item.get("pivot", [0.5, 1.0])
        if not (isinstance(pivot, list) and len(pivot) == 2 and all(isinstance(n, (int, float)) and 0 <= n <= 1 for n in pivot)):
            raise ValueError(f"Invalid pivot for {name}")
        cropped = image.crop((x * width, y * height, (x + 1) * width, (y + 1) * height))
        if cropped.getchannel("A").getbbox() is None:
            raise ValueError(f"Sprite {name} is completely transparent")
        err = edge_error(cropped) if bool(item.get("seamless_tile", False)) else None
        threshold = float(cfg.get("seam_tolerance", 10))
        if err is not None and err > threshold:
            raise ValueError(f"Tile {name} has a visible edge discontinuity: {err} > {threshold}")
        staged.append((name, cropped))
        index.append({
            "name": name, "cell": xy, "size": [width, height],
            "pivot": pivot, "seam_error": err
        })
    output = path.parent / output_dir
    output.mkdir(parents=True, exist_ok=True)
    for name, cropped in staged:
        dest = output / (name + ".png")
        cropped.save(dest, format="PNG", optimize=True)
        digest = hashlib.sha256(dest.read_bytes()).hexdigest()
        next(entry for entry in index if entry["name"] == name)["sha256"] = digest
    report = {"schema_version": 1, "source": source_name, "count": len(index), "sprites": index}
    (output / "index.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return report

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    report = assemble(args.manifest)
    print(f"Exported {report['count']} sprites and validated requested seamless tiles.")

if __name__ == "__main__":
    main()
