#!/usr/bin/env python3
"""Validate prepared art contracts without changing saves or needing Godot/Pillow."""
from pathlib import Path
import hashlib
import json
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def require(ok, message):
    if not ok:
        raise ValueError(message)

def data(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def resource(path):
    require(isinstance(path, str) and path.startswith("res://"), f"Invalid resource path: {path}")
    p = (ROOT / path[6:]).resolve()
    require(p.is_relative_to(ROOT), f"Resource escapes project: {path}")
    require(p.is_file(), f"Missing resource: {path}")
    return p

def main():
    profiles = data("assets/ui/profiles.json")["profiles"]
    require(set(profiles) == {"luna", "ori", "leya", "yuki", "toffi", "miya", "oni"}, "Crew profile mismatch")
    shared_keys = None
    for who, profile in profiles.items():
        for key in ["portrait", "backpack", "hack_icon", "close_eyes_icon"]:
            resource(profile[key])
        resource(profile["animation"]["static_fallback"])
        for key in ["mask", "frame"]:
            resource(profile["minimap"][key])
        manifest = data(f"assets/ui/themes/{who}/manifest.json")["assets"]
        keys = set(manifest)
        require(shared_keys is None or keys == shared_keys, f"Theme keys differ: {who}")
        shared_keys = keys
        for key in keys:
            require((ROOT / "assets/ui/themes" / who / key).is_file(), f"Missing themed asset: {who}/{key}")
        scenario = data(f"assets/ui/scenario_icons/{who}/manifest.json")["assets"]
        require(len(scenario) == 180, f"Scenario icon count mismatch: {who}")
        for entry in scenario.values():
            resource(entry["path"])
    canon = {a["id"]: a for a in data("docs/canon/asset_manifest.json")["artifacts"]}
    prepared = data("assets/artifacts/manifest.json")["artifacts"]
    require(len(canon) == len(prepared) == 21, "Expected 21 unique artifacts")
    require({a["id"] for a in prepared} == set(canon), "Artifact IDs differ from canon")
    require("ART-GL-06" in canon and "A05" in canon and "A02" not in canon, "Obsolete/missing artifact ID")
    for item in prepared:
        expected = canon[item["id"]]
        concept, icon = resource(item["concept"]), resource(item["icon"])
        require(hashlib.sha256(icon.read_bytes()).hexdigest() == item["sha256"], f"Changed master: {item['id']}")
        require(concept.read_bytes() == icon.read_bytes(), f"Unexpected divergent icon master: {item['id']}")
        for key in ["concept", "icon"]:
            require(resource("res://" + expected["asset_files"][key]) == resource(item[key]), f"Canon path mismatch: {item['id']}")
        require(item["model"] is None and expected["asset_files"]["model"] is None, "Uncreated model reported as ready")
        require(item["control"] == expected["control"] and item["fields"] == expected["fields"], f"Gameplay metadata drift: {item['id']}")
    for item in data("assets/prepared_asset_catalog.json")["assets"].values():
        resource(item["path"])
    svgs, pngs = list((ROOT / "assets").rglob("*.svg")), list((ROOT / "assets").rglob("*.png"))
    for p in svgs:
        require(ET.parse(p).getroot().tag.endswith("svg"), f"Invalid SVG: {p}")
    for p in pngs:
        raw = p.read_bytes()
        require(raw[:8] == b"\x89PNG\r\n\x1a\n", f"Invalid PNG: {p}")
        w, h, depth, color = struct.unpack(">IIBB", raw[16:26])
        require(w > 0 and h > 0 and depth == 8 and color == 6, f"Expected native RGBA PNG: {p}")
    require((ROOT / "art/.gdignore").is_file(), "Source/archive art must be excluded from Godot import")
    # Existing runtime fallbacks intentionally remain valid until gameplay integration.
    require(data("assets/asset_catalog.json")["assets"]["luna.portrait"]["path"] == "res://assets/generated/luna_portrait.png", "Runtime fallback catalog changed")
    print(f"PASS: 7 themes, 21 artifacts, {len(svgs)} SVG, {len(pngs)} RGBA PNG; resource paths and canonical IDs valid")

if __name__ == "__main__":
    main()
