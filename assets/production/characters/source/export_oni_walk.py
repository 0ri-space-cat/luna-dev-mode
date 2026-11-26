"""Export Oni Classic locomotion at the same pixel scale as the idle sprites."""

from PIL import Image

from export_luna_story import PREPARED, export, frame_on_canvas, pixel_palette
from export_sprites import CHARACTERS, NEAREST, load

CELL = (128, 192)
PIVOT = (64, 184)
WALK = (
    ("contact-near", 130),
    ("pass-far", 110),
    ("contact-far", 130),
    ("pass-near", 110),
)

RUN = (
    ("contact-near", 90),
    ("pass-far", 80),
    ("contact-far", 90),
    ("pass-near", 80),
)


def export_motion(motion, sequence, *, head_shift=0, reuse_idle_head=True):
    idle = load(PREPARED / "oni-idle-front-right.png")
    head = idle.crop((0, 0, CELL[0], 64))
    source_dir = CHARACTERS / "source" / f"oni-{motion}"
    cels = []
    for name, _ in sequence:
        source = load(source_dir / f"{name}.png")
        supported_sole = source.getchannel("A").point(lambda a: 255 if a >= 144 else 0).getbbox()[3]
        cels.append(frame_on_canvas(name, 8, (504, supported_sole), CELL, PIVOT, source_dir=source_dir))
    poses = []
    for (name, duration), frame in zip(sequence, pixel_palette(cels, 48)):
        # Register the torso against a fixed head height. Blend the position into
        # the original stride between the shorts and the feet.
        offset = frame.getbbox()[1] - idle.getbbox()[1] - head_shift
        width, height = CELL
        shorts_bottom, feet_top = 133, 172
        registered = Image.new("RGBA", CELL)
        source_top = max(0, offset)
        registered.paste(frame.crop((0, source_top, width, shorts_bottom)),
                         (0, source_top - offset))
        legs = frame.crop((0, shorts_bottom, width, feet_top))
        legs = legs.resize((width, feet_top - shorts_bottom + offset), NEAREST)
        registered.paste(legs, (0, shorts_bottom - offset))
        registered.paste(frame.crop((0, feet_top, width, height)), (0, feet_top))
        if reuse_idle_head:
            registered.paste(head, (0, 0))
        poses.append((name, registered, duration))
    export(f"oni-classic-{motion}-front-right", "front_right", CELL, PIVOT, poses, {
        motion: [{"frame": name, "duration_ms": duration} for name, duration in sequence],
        "loop": True,
    }, shared_preview_palette=True)


if __name__ == "__main__":
    export_motion("walk", WALK)
    export_motion("run", RUN, head_shift=5, reuse_idle_head=False)
