"""Register Oni's short walk against the original diagonal standing sprite."""

from PIL import Image

from export_luna_story import PREPARED, export
from export_sprites import CHARACTERS, NEAREST, load

CELL = (128, 192)
PIVOT = (64, 184)
SOURCE = CHARACTERS / "source/oni-walk"
SOURCE_PIVOT = (504, 1472)
SOURCE_PIXELS_PER_PIXEL = 8
SHORTS_HEM = 127
POSES = (
    ("contact-near", 140),
    ("pass-far", 110),
    ("contact-far", 140),
    ("pass-near", 110),
)


CONTOUR = (21, 9, 44)
CARDINAL_STEPS = ((-1, 0), (1, 0), (0, -1), (0, 1))


def ink_leg_edges(colors, silhouette):
    inked = colors.copy()
    mask = silhouette.load()
    surface = colors.load()
    left, _, right, bottom = silhouette.getbbox()
    edge = {
        (x, y)
        for y in range(8, bottom)
        for x in range(left, right)
        if mask[x, y] and any(
            y + dy >= bottom or not mask[x + dx, y + dy]
            for dx, dy in CARDINAL_STEPS
        )
    }
    for x, y in edge:
        inked.putpixel((x, y), CONTOUR)
        if y + SHORTS_HEM < 155:
            continue
        for dx, dy in CARDINAL_STEPS:
            px, py = x + dx, y + dy
            if py >= bottom or not mask[px, py] or (px, py) in edge:
                continue
            if surface[px, py][0] >= 125:
                continue
            # Remove the doubled dark fringe just inside the outer contour.
            # Sample inward so toe marks and drawn contacts stay intact.
            for distance in (1, 2, 3):
                tx, ty = px + distance * dx, py + distance * dy
                if not (left <= tx < right and 0 <= ty < bottom and mask[tx, ty]):
                    break
                skin = surface[tx, ty]
                if skin[0] >= 210:
                    inked.putpixel((px, py), skin)
                    break
    return inked


def registered_legs(source):
    left = SOURCE_PIVOT[0] - PIVOT[0] * SOURCE_PIXELS_PER_PIXEL
    top = SOURCE_PIVOT[1] - (PIVOT[1] - SHORTS_HEM) * SOURCE_PIXELS_PER_PIXEL
    region = source.crop((left, top, left + CELL[0] * SOURCE_PIXELS_PER_PIXEL,
                          source.getbbox()[3]))
    size = (CELL[0], PIVOT[1] - SHORTS_HEM)
    # Measure coverage once at the final resolution. Keep nearest samples
    # for the palette and use the covered color when a center sample is clear.
    coverage = region.getchannel("A").resize(size, Image.Resampling.BOX)
    outline = coverage.point(lambda alpha: 255 if alpha >= 128 else 0)
    sampled = region.resize(size, NEAREST)
    legs = region.resize(size, Image.Resampling.BOX).convert("RGB")
    legs.paste(sampled.convert("RGB"), mask=sampled.getchannel("A"))
    return ink_leg_edges(legs, outline), outline


def main():
    idle = load(PREPARED / "oni-idle-front-right.png")
    frames = []
    for name, duration in POSES:
        legs, outline = registered_legs(load(SOURCE / f"{name}.png"))
        frame = Image.new("RGBA", CELL)
        frame.paste(idle.crop((0, 0, CELL[0], SHORTS_HEM)))
        frame.paste(legs, (0, SHORTS_HEM), outline)
        # Preserve the bottom of each idle cuff where its fixed hand reaches
        # below the shorts-hem compositing line.
        for left, right in ((0, 49), (79, CELL[0])):
            frame.paste(idle.crop((left, SHORTS_HEM, right, 131)), (left, SHORTS_HEM))
        frames.append((name, frame, duration))

    export("oni-classic-walk-front-right", "front_right", CELL, PIVOT, frames, {
        "walk": [{"frame": name, "duration_ms": duration} for name, duration in POSES],
        "loop": True,
    }, shared_preview_palette=True, preview_background="#FFFFFF")


if __name__ == "__main__":
    main()
