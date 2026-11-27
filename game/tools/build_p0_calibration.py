"""Produce review-only P0 contact sheets from existing assets without modifying them.

Run: python game/tools/build_p0_calibration.py --out /tmp/luna-p0
The divisors are hypotheses, not measured cluster pitch or approved world scale.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
APPROVED = ROOT / "assets/approved/characters"
PRODUCTION = ROOT / "assets/production"
DIVISORS = (16, 23, 32)
TILE_SIZES = (16, 32)
GRIDS = ((320, 180), (640, 360))
BACKGROUND = (43, 46, 58, 255)
LIGHT = (226, 224, 230, 255)
FLOOR = (111, 125, 133, 255)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def image_info(path: Path, pivot=None, basis: int = 1):
    with Image.open(path) as source:
        frame = source.convert("RGBA")
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"Empty alpha: {path}")
    if pivot is None:
        pivot = ((bbox[0] + bbox[2]) // 2, bbox[3])
        provenance = "alpha bbox estimate; verify feet visually"
    else:
        provenance = "existing manifest or asset register"
    px, py = map(int, pivot)
    if not 0 <= px <= frame.width or not 0 <= py <= frame.height:
        raise ValueError(f"Pivot {pivot} outside {frame.size}: {path}")
    return frame, {
        "path": path.relative_to(ROOT).as_posix(),
        "sha256": digest(path),
        "size": list(frame.size),
        "alpha_bbox": list(bbox),
        "pivot": [px, py],
        "pivot_source": provenance,
        "source_basis": basis,
        "alpha_values": len(frame.getchannel("A").getcolors(256)),
    }


def sample(frame: Image.Image, info: dict, divisor: int):
    # Prepared slime frames are on the existing 1:8 export scale; the ratio
    # is a comparison hypothesis, not a measured common character/art pixel pitch.
    scale = info["source_basis"] / divisor
    size = tuple(max(1, round(n * scale)) for n in frame.size)
    result = frame.resize(size, Image.Resampling.NEAREST)
    pivot = tuple(round(p * n / old) for p, n, old in zip(info["pivot"], size, frame.size))
    if result.getchannel("A").getbbox() is None:
        raise ValueError(f"Candidate lost all visible pixels: {info['path']} divisor={divisor}")
    return result, pivot


def integer_fit(logical, available):
    factor = min(a // n for n, a in zip(logical, available))
    if factor < 1:
        return None
    size = [n * factor for n in logical]
    return {"factor": factor, "origin": [(a - n) // 2 for a, n in zip(available, size)], "size": size}


def build(out: Path):
    out = out.resolve()
    # Never write generated comparisons over approved/source/production art.
    if out == ROOT or (ROOT / "assets") in out.parents or out == ROOT / "assets":
        raise ValueError("Choose a review output outside assets/ and the repository root")
    chibi_manifest = json.loads((APPROVED / "luna/chibi/manifest.json").read_text())
    chibi_pivot = chibi_manifest["front"]["idle"][0]["pivot"]
    entries = [
        ("Classic", APPROVED / "luna/palette_blue_lilac/explorer_v1/front.png", None, 1),
        ("Chibi", APPROVED / "luna/chibi_master/front/idle.png", chibi_pivot, 1),
        ("Oni", APPROVED / "oni/idle_front.png", None, 1),
        ("Grass slime", PRODUCTION / "fauna/prepared/slime-grass-idle.png", (32, 43), 8),
        ("Neutral slime", PRODUCTION / "fauna/prepared/slime-neutral-idle.png", (32, 43), 8),
    ]
    loaded = [(label, *image_info(path, pivot, basis)) for label, path, pivot, basis in entries]
    col_w, row_h, left, top = 155, 158, 96, 32
    sheet = Image.new("RGBA", (left + len(loaded) * col_w, top + len(DIVISORS) * row_h + 42), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 7), "LUNA P0 / DEV hypotheses / nearest / no approved scale", fill=LIGHT)
    report = {"status": "DEV_CANDIDATES_NOT_APPROVED", "sources": {}, "candidates": [],
              "missing_material_samples": ["grass tile", "stone tile", "wood tile", "world door", "tree"],
              "grid_options": GRIDS, "tile_options": TILE_SIZES,
              "window_fit": [{"grid": grid, "window": window, "fit": integer_fit(grid, window)}
                             for grid in GRIDS for window in ((1280, 800), (1920, 1080), (800, 600), (320, 180))]}
    for i, (label, frame, info) in enumerate(loaded):
        report["sources"][label] = info
        draw.text((left + i * col_w + 8, top - 12), label, fill=LIGHT)
    for row, divisor in enumerate(DIVISORS):
        y = top + row * row_h
        floor = y + 125
        draw.text((8, y + 12), f"1:{divisor}", fill=LIGHT)
        draw.text((8, y + 32), "source ratio", fill=LIGHT)
        draw.line((left, floor, sheet.width - 1, floor), fill=FLOOR)
        for col, (label, frame, info) in enumerate(loaded):
            candidate, pivot = sample(frame, info, divisor)
            x = left + col * col_w + col_w // 2
            origin = (x - pivot[0], floor - pivot[1])
            cell_x = left + col * col_w
            if origin[0] < cell_x or origin[0] + candidate.width > cell_x + col_w or origin[1] < y or origin[1] + candidate.height > y + row_h:
                raise ValueError(f"Candidate outside comparison cell: {label}, divisor {divisor}")
            sheet.alpha_composite(candidate, origin)
            draw.line((x - 3, floor, x + 3, floor), fill=(247, 191, 123, 255))
            draw.text((left + col * col_w + 8, floor + 10), f"{candidate.width}x{candidate.height}", fill=LIGHT)
            report["candidates"].append({"asset": label, "source_divisor": divisor, "canvas": candidate.size,
                                         "pivot": pivot, "alpha_bbox": candidate.getchannel("A").getbbox()})
    draw.text((8, sheet.height - 29), "Materials / door / tree: missing from this sheet; no synthetic replacements.", fill=LIGHT)
    out.mkdir(parents=True, exist_ok=True)
    sheet.save(out / "p0-native.png")
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.Resampling.NEAREST).save(out / "p0-nearest-x4.png")
    (out / "p0-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for _, _, info in loaded:
        if digest(ROOT / info["path"]) != info["sha256"]:
            raise RuntimeError(f"Source unexpectedly changed: {info['path']}")
    print(f"P0: {len(report['candidates'])} review candidates; source hashes unchanged; {out}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    build(parser.parse_args().out)
