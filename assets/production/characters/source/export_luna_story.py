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
# Offsets are in native pixels. Negative values shorten the projected leg
# as its foot travels away from the camera.
DOOR_STEPS = (
    ("ready", 0, 0, 90),
    ("right-lift", 1, -2, 70),
    ("right-swing", 2, -5, 70),
    ("right-contact", 3, -4, 90),
    ("transfer", 0, -1, 70),
    ("left-lift", -2, 0, 70),
    ("left-swing", -5, 1, 70),
    ("left-contact", -4, 2, 90),
    ("settle", -2, 1, 100),
    ("ready", 0, 0, 90),
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


def pixel_palette(frames, color_count):
    # Group close shades on the native grid, preserving alpha and avoiding
    # dither pixels within hair, fabric and faces.
    opaque = [pixel[:3] for frame in frames for pixel in frame.getdata() if pixel[3]]
    samples = Image.new("RGB", (len(opaque), 1))
    samples.putdata(opaque)
    palette = samples.quantize(colors=color_count)
    result = []
    for frame in frames:
        rgb = frame.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE)
        clean = Image.new("RGBA", frame.size)
        clean.paste(rgb.convert("RGBA"), (0, 0), frame.getchannel("A"))
        result.append(clean)
    return result


def step_leg(base, frame, left, right, offset):
    hip, ankle = 139, 168
    calf = base.crop((left, hip, right, ankle))
    shoe = base.crop((left, ankle, right, base.height))
    calf = calf.resize((calf.width, calf.height + offset), NEAREST)
    frame.paste(calf, (left, hip), calf.getchannel("A"))
    frame.paste(shoe, (left, ankle + offset), shoe.getchannel("A"))


def door_frames():
    base, = pixel_palette([frame_on_canvas(
        "door-pass", 8, (512, 1425), (128, 192), (64, 184)
    )], 36)
    torso = base.crop((0, 0, base.width, 139))
    frames = []
    for name, left, right, duration in DOOR_STEPS[:-1]:
        frame = Image.new("RGBA", base.size)
        frame.paste(torso)
        step_leg(base, frame, 0, 62, left)
        step_leg(base, frame, 62, base.width, right)
        frames.append((name, frame, duration))
    return frames


def export(name, view, size, anchor, poses, sequence, *, preview_order=None, preview_stride=0):
    width, height = size
    sheet = Image.new("RGBA", (width * len(poses), height))
    frames, records = {}, []
    for index, (pose, frame, _) in enumerate(poses):
        x = index * width
        sheet.paste(frame, (x, 0))
        records.append({"id": pose, "region": [x, 0, width, height]})
        frames[pose] = frame

    sheet.save(PREPARED / f"{name}.png", optimize=True)
    (PREPARED / f"{name}.json").write_text(json.dumps({
        "texture": f"{name}.png",
        "view": view,
        "cell_size": size,
        "anchor": anchor,
        "frames": records,
        **sequence,
    }, indent=2) + "\n")
    order = preview_order or [(pose, duration) for pose, _, duration in poses]
    preview = []
    for index, (pose, _) in enumerate(order):
        panel = Image.new("RGB", (width, height), "#374156")
        draw = ImageDraw.Draw(panel)
        draw.line((0, anchor[1], width - 1, anchor[1]), fill="#4D5970")
        frame = frames[pose]
        panel.paste(frame, (0, -index * preview_stride), frame.getchannel("A"))
        preview.append(panel)
    # Pause on the last drawing so the reset of the preview stays readable.
    if preview_stride:
        order = [*order[:-1], (order[-1][0], 500)]
    timing = [duration for _, duration in order]
    preview[0].save(
        PREVIEWS / f"{name}.gif", save_all=True, append_images=preview[1:],
        duration=timing, loop=0, disposal=2,
    )


def main():
    wake_size, wake_anchor = (192, 192), (96, 184)
    cels = pixel_palette([
        frame_on_canvas(pose, divisor, source_anchor, wake_size, wake_anchor)
        for pose, divisor, source_anchor, _ in WAKE
    ], 48)
    export("luna-classic-wake", "front_right", wake_size, wake_anchor, [
        (pose, cel, ms) for (pose, _, _, ms), cel in zip(WAKE, cels)
    ], {
        "rest_frame": WAKE[0][0],
        "wake": [{"frame": pose, "duration_ms": ms} for pose, _, _, ms in WAKE[1:]],
        "loop": False,
    })
    enter = [(pose, ms) for pose, _, _, ms in DOOR_STEPS]
    export("luna-classic-door", "back", (128, 192), (64, 184), door_frames(), {
        "enter": [{"frame": pose, "duration_ms": ms} for pose, ms in enter],
        "loop": False,
    }, preview_order=enter, preview_stride=1)


if __name__ == "__main__":
    main()
