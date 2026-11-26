"""Prepare idle sprites on a shared pixel grid and foot line."""

import colorsys
from pathlib import Path

from PIL import Image, ImageDraw

CHARACTERS = Path(__file__).resolve().parents[1]
ASSETS = CHARACTERS.parents[1]
FAUNA = CHARACTERS.parent / "fauna"
YUKI_PORTRAIT = (
    ASSETS / "approved/hud/godot/retro-ui-kit/assets/ui/pixel-v1/characters/yuki/portrait.png"
)
NEAREST = Image.Resampling.NEAREST
BASELINE = 184
CLASSIC_HEIGHTS = {"leya": 172, "miya": 176, "ori": 177, "toffi": 175, "yuki": 181, "oni": 175}

# Masks exclude the face and the start of each collar. The color condition below
# protects the skin and neutral linework even along the border of these masks.
YUKI_EXCLUSIONS = {
    "sprite": [(551, 286), (573, 315), (607, 357), (645, 397), (661, 463),
               (608, 492), (608, 527), (706, 820), (317, 820), (417, 556),
               (468, 517), (407, 483), (361, 459), (373, 411), (403, 375), (496, 352)],
    "portrait": [(702, 404), (732, 447), (761, 516), (821, 586), (879, 624),
                 (893, 729), (856, 809), (767, 866), (776, 921), (1010, 1241),
                 (234, 1241), (405, 940), (484, 893), (538, 868), (456, 816),
                 (389, 751), (370, 670), (401, 587), (475, 566), (542, 565), (621, 500)],
}
# Values of the old icon ramp and their counterparts in Yuki's vivid sprite.
PALE_TO_VIVID = [
    ((58, 19, 39), (58, 19, 39)),
    ((111, 46, 71), (106, 25, 60)),
    ((160, 62, 98), (154, 15, 70)),
    ((219, 91, 139), (199, 18, 96)),
    ((248, 127, 170), (247, 35, 109)),
    ((251, 180, 211), (250, 117, 182)),
    ((255, 247, 250), (255, 247, 250)),
]


def load(path):
    return Image.open(path).convert("RGBA")


def hair_tone(image, variant):
    mask = Image.new("1", image.size)
    ImageDraw.Draw(mask).polygon(YUKI_EXCLUSIONS[variant], fill=1)
    pixels = image.load()
    excluded = mask.load()
    for y in range(830 if variant == "sprite" else image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if not alpha or excluded[x, y] or not (red > blue > green and blue - green > 17):
                continue
            hue, light, saturation = colorsys.rgb_to_hls(red / 255, green / 255, blue / 255)
            if not (0.89 < hue < 0.98 and light > 0.22):
                continue
            if variant == "sprite":
                rgb = tuple(round(c * 255) for c in colorsys.hls_to_rgb(hue, light, saturation * 0.93))
            else:
                closest = min(PALE_TO_VIVID, key=lambda swatch: sum(
                    (original - value) ** 2 for original, value in zip(swatch[0], (red, green, blue))
                ))
                rgb = tuple(max(0, min(255, value + target - original))
                            for value, original, target in zip((red, green, blue), *closest))
            pixels[x, y] = (*rgb, alpha)
    return image


def fitted(image, size, height, baseline, *, align_feet=False):
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 144 else 0)
    image.putalpha(alpha)
    image = image.crop(alpha.getbbox())
    image = image.resize((round(image.width * height / image.height), height), NEAREST)
    left = (size[0] - image.width) // 2
    if align_feet:
        # Align the stance instead of letting the tail or hair move the anchor.
        foot_band = image.getchannel("A").crop((0, height - 8, image.width, height))
        foot_left, _, foot_right, _ = foot_band.getbbox()
        left = (size[0] - foot_left - foot_right) // 2
        if left < 0 or left + image.width > size[0]:
            raise ValueError("Sprite does not fit the foot-aligned canvas")
    frame = Image.new("RGBA", size)
    frame.paste(image, (left, baseline - height))
    # Canonical transparent pixels prevent faint fringe colors on import.
    blank = Image.new("RGBA", size)
    return Image.composite(frame, blank, frame.getchannel("A"))


def coarsen_detail(image, bounds):
    detail = image.crop(bounds)
    grid = (round(detail.width / 10), round(detail.height / 10))
    detail = detail.resize(grid, NEAREST).resize(detail.size, NEAREST)
    image.paste(detail, bounds[:2])


def save(image, root, name):
    folder = root / "prepared"
    folder.mkdir(exist_ok=True)
    image.save(folder / f"{name}.png", optimize=True)


def save_slime_jump(image, form):
    body = image.crop(image.getchannel("A").getbbox())
    for pose, size in (
        ("squash", (48, 26)),
        ("launch", (38, 33)),
        ("air", (40, 31)),
        ("land", (50, 25)),
    ):
        frame = Image.new("RGBA", image.size)
        frame.paste(body.resize(size, NEAREST), (32 - size[0] // 2, 43 - size[1]))
        save(frame, FAUNA, f"slime-{form}-jump-{pose}")


def main():
    for name, height in CLASSIC_HEIGHTS.items():
        diagonal = load(CHARACTERS / "source" / f"{name}-front-right.png")
        frame = fitted(diagonal, (128, 192), height, BASELINE, align_feet=True)
        save(frame, CHARACTERS, f"{name}-idle-front-right")

        for direction in ("side-right", "back-right", "back"):
            source = CHARACTERS / "source" / f"{name}-{direction}.png"
            if source.exists():
                view = fitted(load(source), (128, 192), height, BASELINE, align_feet=True)
                save(view, CHARACTERS, f"{name}-idle-{direction}")

        if name == "oni":
            front = load(ASSETS / "approved/characters/oni/idle_front.png")
            frame = fitted(front, (128, 192), height, BASELINE)
            save(frame, CHARACTERS, "oni-idle-front")
            continue
        image = load(CHARACTERS / "source" / f"{name}-front.png")
        if name == "yuki":
            image = hair_tone(image, "sprite")
        if name == "ori":
            coarsen_detail(image, (437, 660, 581, 765))
        frame = fitted(image, (128, 192), height, BASELINE)
        if name == "miya":
            # Draw the small vials at sprite resolution so the glass and pocket rim stay distinct.
            frame.alpha_composite(load(CHARACTERS / "source/miya-pocket-vials.png"), (49, 103))
        save(frame, CHARACTERS, f"{name}-idle-front")
    save(hair_tone(load(YUKI_PORTRAIT), "portrait"), CHARACTERS, "yuki-portrait")

    grass = fitted(load(FAUNA / "source/slime-front.png"), (64, 48), 30, 43)
    save(grass, FAUNA, "slime-grass-idle")
    neutral = Image.new("RGBA", grass.size)
    pixels = []
    for red, green, blue, alpha in grass.getdata():
        light = (red + 2 * green + blue) / (4 * 255)
        ramp = ("#503C58", "#9B849F", "#DCCBDC", "#FFF8EB", "#FFFDF7")
        shade = min(4, int(light * 5))
        color = bytes.fromhex(ramp[shade][1:]) if alpha else (0, 0, 0)
        pixels.append((*color, alpha))
    neutral.putdata(pixels)
    save(neutral, FAUNA, "slime-neutral-idle")
    save_slime_jump(grass, "grass")
    save_slime_jump(neutral, "neutral")


if __name__ == "__main__":
    main()
