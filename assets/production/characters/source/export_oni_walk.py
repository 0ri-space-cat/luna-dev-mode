"""Export Oni Classic walking at the same pixel scale as the idle sprites."""

from PIL import Image

from export_luna_story import PREPARED, export, frame_on_canvas, pixel_palette
from export_sprites import CHARACTERS, NEAREST, load

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
        # Register the torso against the idle head. Blend the position into
        # the original stride between the shorts and the feet.
        offset = frame.getbbox()[1] - idle.getbbox()[1]
        width, height = CELL
        shorts_bottom, feet_top = 133, 172
        registered = Image.new("RGBA", CELL)
        registered.paste(frame.crop((0, offset, width, shorts_bottom)), (0, 0))
        legs = frame.crop((0, shorts_bottom, width, feet_top))
        legs = legs.resize((width, feet_top - shorts_bottom + offset), NEAREST)
        registered.paste(legs, (0, shorts_bottom - offset))
        registered.paste(frame.crop((0, feet_top, width, height)), (0, feet_top))
        registered.paste(head, (0, 0))
        poses.append((name, registered, duration))
    export("oni-classic-walk-front-right", "front_right", CELL, PIVOT, poses, {
        "walk": [{"frame": name, "duration_ms": duration} for name, duration in POSES],
        "loop": True,
    }, shared_preview_palette=True)


if __name__ == "__main__":
    main()
