"""Pack Luna Classic story poses with authored placement at the scene anchor."""

import json

from PIL import Image, ImageDraw

from export_sprites import CHARACTERS, NEAREST, load

STUDIES = CHARACTERS / "source/luna-action-studies"
PREPARED = CHARACTERS / "prepared"
PREVIEWS = CHARACTERS / "previews"

# Scale each drawing by the head size and place its active support on the
# common scene line. The wider wake canvas accommodates the horizontal pose.
WAKE = (
    ("sleep-right", 9.6, (887, 864), 650),
    ("wake-recline", 9.7, (700, 1002), 160),
    ("wake", 8.0, (464, 1324), 240),
    ("wake-crouch", 9.0, (495, 1396), 170),
    ("wake-stand", 8.0, (480, 1488), 300),
)
DOOR = (
    ("door-step", 8.0, (512, 1489), 130),
    ("door-pass", 8.0, (512, 1489), 90),
    ("door-step-opposite", 8.0, (512, 1489), 130),
)


def frame_on_canvas(name, divisor, source_anchor, size, anchor):
    image = load(STUDIES / f"{name}.png")
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 144 else 0)
    image.putalpha(alpha)
    bounds = alpha.getbbox()
    sprite = image.crop(bounds).resize(
        (round((bounds[2] - bounds[0]) / divisor), round((bounds[3] - bounds[1]) / divisor)),
        NEAREST,
    )
    position = tuple(
        output - round((source - edge) / divisor)
        for output, source, edge in zip(anchor, source_anchor, bounds[:2])
    )
    if any(start < 0 or start + extent > limit
           for start, extent, limit in zip(position, sprite.size, size)):
        raise ValueError(f"{name} exceeds the story canvas")
    frame = Image.new("RGBA", size)
    frame.paste(sprite, position, sprite.getchannel("A"))
    return frame


def export(name, view, size, anchor, poses, sequence):
    width, height = size
    sheet = Image.new("RGBA", (width * len(poses), height))
    panels, records = [], []
    for index, (pose, divisor, source_anchor, preview_ms) in enumerate(poses):
        frame = frame_on_canvas(pose, divisor, source_anchor, size, anchor)
        x = index * width
        sheet.paste(frame, (x, 0))
        records.append({"id": pose, "region": [x, 0, width, height]})
        panel = Image.new("RGB", (width, height + 16), "#374156")
        draw = ImageDraw.Draw(panel)
        draw.line((0, anchor[1], width - 1, anchor[1]), fill="#4D5970")
        draw.text((8, height), pose, fill="#E8EDF5")
        panel.paste(frame, (0, 0), frame)
        panels.append(panel)

    sheet.save(PREPARED / f"{name}.png", optimize=True)
    (PREPARED / f"{name}.json").write_text(json.dumps({
        "texture": f"{name}.png",
        "view": view,
        "cell_size": size,
        "anchor": anchor,
        "frames": records,
        **sequence,
    }, indent=2) + "\n")
    panels[0].save(
        PREVIEWS / f"{name}.gif", save_all=True, append_images=panels[1:],
        duration=[pose[3] for pose in poses], loop=0, disposal=2,
    )


def main():
    export("luna-classic-wake", "front_right", (192, 192), (96, 184), WAKE, {
        "rest_frame": WAKE[0][0],
        "wake": [{"frame": pose, "duration_ms": ms} for pose, _, _, ms in WAKE[1:]],
        "loop": False,
    })
    export("luna-classic-door", "back", (128, 192), (64, 184), DOOR, {
        "enter": [{"frame": pose, "duration_ms": ms} for pose, _, _, ms in DOOR],
        "loop": False,
    })


if __name__ == "__main__":
    main()
