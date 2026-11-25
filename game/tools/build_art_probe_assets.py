"""Pack approved character art at the fixed scale of the Godot art probe."""
import json
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[1]
CHARACTERS = GAME.parent / "assets/approved/characters"
DESTINATION = GAME / "assets/art_probe"
DIRECTIONS = ("front", "front_right", "side_right", "back_right", "back")
CELL = (48, 76)
FOOT = (24, 70)
SOURCE_PIXELS_PER_PIXEL = 23


def paste_frame(atlas, path, cell_origin, pivot=None):
    with Image.open(path) as source:
        frame = source.convert("RGBA")
    if pivot is None:
        pivot = (frame.width // 2, frame.getchannel("A").getbbox()[3])
    frame = frame.resize(
        tuple(round(size / SOURCE_PIXELS_PER_PIXEL) for size in frame.size),
        Image.Resampling.LANCZOS,
    )
    offset = tuple(foot - round(point / SOURCE_PIXELS_PER_PIXEL)
                   for foot, point in zip(FOOT, pivot))
    atlas.paste(frame, tuple(origin + delta for origin, delta in zip(cell_origin, offset)))


def main():
    luna = CHARACTERS / "luna"
    palette = luna / "palette_blue_lilac"
    manifest = json.loads((luna / "explorer_animation/manifest.json").read_text())
    atlas = Image.new("RGBA", (CELL[0] * 5, CELL[1] * len(DIRECTIONS)))
    for row, direction in enumerate(DIRECTIONS):
        paste_frame(atlas, palette / f"explorer_v1/{direction}.png", (0, row * CELL[1]))
        for column, frame in enumerate(manifest["views"][direction]["walk"], start=1):
            path = palette / "explorer_animation" / direction / Path(frame["path"]).name
            paste_frame(atlas, path, (column * CELL[0], row * CELL[1]), frame["pivot"])
    DESTINATION.mkdir(parents=True, exist_ok=True)
    atlas.save(DESTINATION / "luna.png")
    oni = Image.new("RGBA", CELL)
    paste_frame(oni, CHARACTERS / "oni/idle_front.png", (0, 0))
    oni.save(DESTINATION / "oni.png")


if __name__ == "__main__":
    main()
