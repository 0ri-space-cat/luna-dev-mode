"""Export a registered Luna Classic item gesture and review the existing sprint bank."""

import json
from pathlib import Path

from PIL import Image, ImageDraw

from export_sprites import ASSETS, CHARACTERS, NEAREST, load

CELL = (128, 192)
PIVOT = (64, 184)
SCALE = 8  # Source pixels per production pixel.
DIRECTIONS = ("front", "front_right", "side_right", "back_right", "back")
GRIP_FRAMES = (("lower", (53, 104)), ("hold", (54, 83)), ("raise", (47, 76)))
USE_ORDER = (0, 1, 2, 1, 0)
USE_TIMING = (100, 80, 160, 80, 100)
SPRINT_TIMING = (90, 90, 90, 90)


def registered(image, source_pivot):
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 144 else 0)
    image.putalpha(alpha)
    # Sample against the common pivot, keeping a single grid between frames.
    left, top = (source - target * SCALE for source, target in zip(source_pivot, PIVOT))
    image = image.crop((left, top, left + CELL[0] * SCALE, top + CELL[1] * SCALE))
    image = image.resize(CELL, NEAREST)
    return Image.composite(image, Image.new("RGBA", CELL), image.getchannel("A"))


def preview_frame(frames, labels):
    panel = Image.new("RGB", (CELL[0] * len(frames), CELL[1] + 16), "#374156")
    draw = ImageDraw.Draw(panel)
    draw.line((0, PIVOT[1], panel.width - 1, PIVOT[1]), fill="#4D5970")
    for column, (frame, label) in enumerate(zip(frames, labels)):
        x = column * CELL[0]
        panel.paste(frame, (x, 0), frame)
        draw.text((x + 9, CELL[1]), label, fill="#E8EDF5")
    return panel


def save_loop(frames, filename, timing):
    frames[0].save(
        CHARACTERS / "previews" / filename,
        save_all=True, append_images=frames[1:], duration=timing, loop=0, disposal=2,
    )


def export_grip():
    sheet = Image.new("RGBA", (CELL[0] * len(GRIP_FRAMES), CELL[1]))
    frames = []
    records = []
    for index, (name, grip) in enumerate(GRIP_FRAMES):
        path = CHARACTERS / "source/luna-action-studies" / f"{name}.png"
        frame = registered(load(path), (480, 1489))
        offset = index * CELL[0]
        sheet.paste(frame, (offset, 0))
        frames.append(frame)
        records.append({"id": name, "region": [offset, 0, *CELL], "grip": grip})

    prepared = CHARACTERS / "prepared"
    sheet.save(prepared / "luna-classic-item-use.png", optimize=True)
    data = {
        "texture": "luna-classic-item-use.png",
        "view": "front_right",
        "cell_size": CELL,
        "pivot": PIVOT,
        "frames": records,
        "hold_frame": "lower",
        "use": [
            {"frame": GRIP_FRAMES[index][0], "duration_ms": duration}
            for index, duration in zip(USE_ORDER, USE_TIMING)
        ],
        "loop": False,
    }
    (prepared / "luna-classic-item-use.json").write_text(json.dumps(data, indent=2) + "\n")
    panels = [preview_frame([frames[index]], [GRIP_FRAMES[index][0]]) for index in USE_ORDER]
    save_loop(panels, "luna-classic-item-use.gif", USE_TIMING)


def preview_sprint():
    luna = ASSETS / "approved/characters/luna"
    manifest = json.loads((luna / "explorer_animation/manifest.json").read_text())
    columns = []
    for direction in DIRECTIONS:
        cels = []
        for frame in manifest["views"][direction]["run"]:
            path = luna / "palette_blue_lilac/explorer_animation" / direction / Path(frame["path"]).name
            cels.append(registered(load(path), frame["pivot"]))
        columns.append(cels)
    panels = [
        preview_frame(frames, [direction.replace("_", " ") for direction in DIRECTIONS])
        for frames in zip(*columns)
    ]
    save_loop(panels, "luna-classic-run.gif", SPRINT_TIMING)


if __name__ == "__main__":
    export_grip()
    preview_sprint()
