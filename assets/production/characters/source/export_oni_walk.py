"""Register Oni's short walk against the original diagonal standing sprite."""

from PIL import Image

from export_luna_story import PREPARED, export, frame_on_canvas
from export_sprites import CHARACTERS, NEAREST, load

CELL = (128, 192)
PIVOT = (64, 184)
SOURCE = CHARACTERS / "source/oni-walk"
SOURCE_PIVOT = (504, 1472)
SHORTS_HEM = 127
POSES = (
    ("contact-near", 140),
    ("pass-far", 110),
    ("contact-far", 140),
    ("pass-near", 110),
)


def main():
    idle = load(PREPARED / "oni-idle-front-right.png")
    frames = []
    for name, duration in POSES:
        pose = frame_on_canvas(name, 8, SOURCE_PIVOT, CELL, PIVOT, source_dir=SOURCE)
        # Start the changing region at the shorts hem so the original head,
        # neck, outfit and hands keep their exact registration.
        bottom = pose.getbbox()[3]
        legs = pose.crop((0, SHORTS_HEM, CELL[0], bottom))
        legs = legs.resize((CELL[0], PIVOT[1] - SHORTS_HEM), NEAREST)
        frame = Image.new("RGBA", CELL)
        frame.paste(idle.crop((0, 0, CELL[0], SHORTS_HEM)))
        frame.paste(legs, (0, SHORTS_HEM))
        frames.append((name, frame, duration))

    export("oni-classic-walk-front-right", "front_right", CELL, PIVOT, frames, {
        "walk": [{"frame": name, "duration_ms": duration} for name, duration in POSES],
        "loop": True,
    }, shared_preview_palette=True, preview_background="#FFFFFF")


if __name__ == "__main__":
    main()
