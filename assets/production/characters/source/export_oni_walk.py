"""Export Oni Classic walking at the same pixel scale as the idle sprites."""

from export_luna_story import PREPARED, export, frame_on_canvas, pixel_palette
from export_sprites import CHARACTERS, load

CELL = (128, 192)
PIVOT = (64, 184)
SOURCE = CHARACTERS / "source/oni-walk"
POSES = (
    ("contact-near", 130),
    ("pass-far", 110),
    ("contact-far", 130),
    ("pass-near", 110),
)


def main():
    idle = load(PREPARED / "oni-idle-front-right.png")
    head = idle.crop((0, 0, CELL[0], 64))
    cels = []
    for name, _ in POSES:
        source = load(SOURCE / f"{name}.png")
        supported_sole = source.getchannel("A").point(lambda a: 255 if a >= 144 else 0).getbbox()[3]
        cels.append(frame_on_canvas(name, 8, (504, supported_sole), CELL, PIVOT, source_dir=SOURCE))
    poses = []
    for (name, duration), frame in zip(POSES, pixel_palette(cels, 48)):
        # Keep the exact face and hair across the cycle, retaining the step's bob.
        bob = frame.getbbox()[1] - idle.getbbox()[1]
        frame.paste((0, 0, 0, 0), (0, 0, CELL[0], head.height + bob))
        frame.paste(head, (0, bob))
        poses.append((name, frame, duration))
    export("oni-classic-walk-front-right", "front_right", CELL, PIVOT, poses, {
        "walk": [{"frame": name, "duration_ms": duration} for name, duration in POSES],
        "loop": True,
    })


if __name__ == "__main__":
    main()
