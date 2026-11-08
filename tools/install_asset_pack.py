#!/usr/bin/env python3
"""Install the approved LUNA sprite ZIP into the repository, with checksums."""
from __future__ import annotations
import argparse, hashlib, json, zipfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
TOP = "LUNA_Eternia_Asset_Pack_01/"
PROPS = ("berry_tree", "flower_bush", "pink_crystals", "moss_arch", "oracle_pedestal", "walking_fridge")
def install(pack: Path, force: bool = False) -> list[str]:
    if not zipfile.is_zipfile(pack):
        raise ValueError("Not a ZIP asset pack")
    results = []
    with zipfile.ZipFile(pack) as z:
        manifest = json.loads(z.read(TOP + "props_manifest.json").decode("utf-8"))
        records = {item["id"]: item for item in manifest["sprites"]}
        if set(records) != set(PROPS):
            raise ValueError("Unexpected props manifest")
        outputs = []
        for name in PROPS:
            path = TOP + "props/" + name + ".png"
            raw = z.read(path)
            if hashlib.sha256(raw).hexdigest() != records[name]["sha256"]:
                raise ValueError("Corrupted sprite: " + name)
            if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Not a PNG: " + name)
            outputs.append((ROOT / "assets/2d/eternia/props" / (name + ".png"), raw))
        for name in ("grass_1", "grass_2", "grass_3"):
            raw = z.read(TOP + "terrain/" + name + ".png")
            if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Not a PNG: " + name)
            outputs.append((ROOT / "assets/2d/eternia/terrain" / (name + ".png"), raw))
        if not force and any(dest.exists() for dest, _ in outputs):
            raise FileExistsError("Some files already exist; use --force only after review")
        for dest, raw in outputs:
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(raw)
            results.append(str(dest.relative_to(ROOT)))
    return results
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    for path in install(args.zip, args.force):
        print("Installed:", path)
