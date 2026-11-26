"""Export Luna Classic's cast with independently composited wand and fingers."""

import json

from PIL import Image, ImageDraw

from export_luna_story import PREPARED, PREVIEWS, frame_on_canvas, pixel_palette
from export_sprites import ASSETS, NEAREST, load

BODY_SIZE = (128, 192)
BODY_ANCHOR = (64, 184)
WAND_SIZE = (96, 96)
WAND_GRIP = (48, 48)
WAND_SOURCE = ASSETS / "approved/hud/godot/retro-ui-kit/assets/ui/pixel-v1/items/wand.png"
# Grip and finger outlines are authored in pixels on the registered body.
POSES = (
    ("hold", "hold", (480, 1489), (53, 84), 69, (50, 77, 60, 89)),
    ("windup", "cast-windup", (485, 1489), (39, 98), 102, (35, 92, 46, 104)),
    ("pass", "cast-pass-near", (485, 1489), (76, 84), -22, (70, 77, 82, 90)),
    ("release", "cast-release-near", (485, 1489), (101, 94), -56, (96, 89, 108, 100)),
)
# The profile reuses the same bent-arm drawing for idle and the passing stage.
PROFILE_POSES = (
    ("hold", "cast-side-pass", (512, 1494), (82, 97), 3, (76, 91, 88, 103)),
    ("windup", "cast-side-windup", (512, 1494), (51, 110), 106, (46, 105, 58, 116)),
    ("pass", "cast-side-pass", (512, 1494), (82, 97), -26, (76, 91, 88, 103)),
    ("release", "cast-side-release", (512, 1494), (106, 81), -56, (99, 77, 112, 89)),
)
ORDER = (("hold", 250), ("windup", 150), ("pass", 80), ("release", 120), ("pass", 90), ("hold", 310))


def wand_source():
    image = load(WAND_SOURCE)
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 144 else 0)
    image.putalpha(alpha)

    # Build a high-resolution square centered on the middle of the handle.
    # Rotation before export keeps all orientations on one nearest-neighbor grid.
    source_grip = (276, 757)
    radius = WAND_GRIP[0] * 19
    centered = Image.new("RGBA", (2 * radius, 2 * radius))
    centered.paste(image, tuple(radius - value for value in source_grip), alpha)
    return centered


def write_atlas(name, frames, size):
    width, height = size
    atlas = Image.new("RGBA", (width * len(frames), height))
    for index, cel in enumerate(frames):
        atlas.paste(cel, (index * width, 0))
    atlas.save(PREPARED / name, optimize=True)


def make_preview(stem, records, bodies, wands, fingers):
    previews = {}
    for record, body, wand, finger in zip(records, bodies, wands, fingers):
        panel = Image.new("RGBA", (224, 192), "#374156")
        ImageDraw.Draw(panel).line((0, BODY_ANCHOR[1], 223, BODY_ANCHOR[1]), fill="#4D5970")
        x, y = record["grip"]
        panel.alpha_composite(body, (48, 0))
        panel.alpha_composite(wand, (48 + x - WAND_GRIP[0], y - WAND_GRIP[1]))
        panel.alpha_composite(finger, (48, 0))
        previews[record["id"]] = panel.convert("RGB")
    panels = [previews[pose] for pose, _ in ORDER]
    duration = [ms for _, ms in ORDER]
    panels[0].save(PREVIEWS / f"{stem}.gif", save_all=True,
                   append_images=panels[1:], duration=duration, loop=0, disposal=2)


def export_cast(stem, view, poses, *, locked_rows=()):
    bodies = pixel_palette([
        frame_on_canvas(source, 8, anchor, BODY_SIZE, BODY_ANCHOR)
        for _, source, anchor, _, _, _ in poses
    ], 48)
    reference = bodies[0].copy()
    for top, bottom in locked_rows:
        fixed = reference.crop((0, top, BODY_SIZE[0], bottom))
        for body in bodies[1:]:
            body.paste(fixed, (0, top))
    master = wand_source()
    wands = pixel_palette([
        master.rotate(angle, resample=NEAREST).resize(WAND_SIZE, NEAREST)
        for _, _, _, _, angle, _ in poses
    ], 32)
    fingers, records = [], []
    for index, ((pose, _, _, grip, _, bounds), body) in enumerate(zip(poses, bodies)):
        front = Image.new("RGBA", BODY_SIZE)
        front.paste(body.crop(bounds), bounds[:2])
        fingers.append(front)
        records.append({
            "id": pose,
            "body_region": [index * BODY_SIZE[0], 0, *BODY_SIZE],
            "fingers_region": [index * BODY_SIZE[0], 0, *BODY_SIZE],
            "wand_region": [index * WAND_SIZE[0], 0, *WAND_SIZE],
            "grip": grip,
        })

    body_file = f"{stem}-body.png"
    wand_file = f"{stem}-wand.png"
    fingers_file = f"{stem}-fingers.png"
    write_atlas(body_file, bodies, BODY_SIZE)
    write_atlas(wand_file, wands, WAND_SIZE)
    write_atlas(fingers_file, fingers, BODY_SIZE)
    data = {
        "view": view,
        "body_anchor": BODY_ANCHOR,
        "wand_grip": WAND_GRIP,
        "layers": {"body": body_file, "wand": wand_file, "fingers": fingers_file},
        "frames": records,
        "hold_frame": "hold",
        "cast": [{"frame": pose, "duration_ms": ms} for pose, ms in ORDER[1:]],
        "release_frame": "release",
        "loop": False,
    }
    (PREPARED / f"{stem}.json").write_text(json.dumps(data, indent=2) + "\n")
    make_preview(stem, records, bodies, wands, fingers)


if __name__ == "__main__":
    export_cast("luna-classic-wand-cast", "front_right", POSES)
    export_cast("luna-classic-wand-cast-side-right", "side_right", PROFILE_POSES,
                locked_rows=((0, 72), (134, BODY_SIZE[1])))
