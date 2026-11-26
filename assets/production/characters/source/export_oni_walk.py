"""Register the full-body diagonal walk cycle for Oni Classic."""

from PIL import Image

from export_luna_story import export
from export_sprites import CHARACTERS, NEAREST, load

CELL = (128, 192)
PIVOT = (64, 184)
SOURCE = CHARACTERS / "source/oni-walk"
SOURCE_CENTER_X = 504
SOURCE_PIXELS_PER_PIXEL = 8
TOP = 9
SHORTS_HEM = 127
POSES = (
    ("contact-near", 180),
    ("pass-far", 200),
    ("contact-far", 180),
    ("pass-near", 200),
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


def registered_pose(source):
    left = SOURCE_CENTER_X - PIVOT[0] * SOURCE_PIXELS_PER_PIXEL
    _, top, _, bottom = source.getbbox()
    region = source.crop((left, top, left + CELL[0] * SOURCE_PIXELS_PER_PIXEL, bottom))
    size = (CELL[0], PIVOT[1] - TOP)
    coverage = region.getchannel("A").resize(size, Image.Resampling.BOX)
    silhouette = coverage.point(lambda alpha: 255 if alpha >= 128 else 0)
    sampled = region.resize(size, NEAREST)
    colors = region.resize(size, Image.Resampling.BOX).convert("RGB")
    colors.paste(sampled.convert("RGB"), mask=sampled.getchannel("A"))

    # Keep the neck and arms with each whole pose. Re-ink only the leg region
    # where resampling can leave a broken or doubled edge.
    leg_box = (0, SHORTS_HEM - TOP, CELL[0], size[1])
    legs = ink_leg_edges(colors.crop(leg_box), silhouette.crop(leg_box))
    colors.paste(legs, leg_box[:2])
    frame = Image.new("RGBA", CELL)
    frame.paste(colors, (0, TOP), silhouette)
    return frame


def main():
    frames = [(name, registered_pose(load(SOURCE / f"{name}.png")), duration)
              for name, duration in POSES]
    walk = [{"frame": name, "duration_ms": duration} for name, duration in POSES]
    export("oni-classic-walk-front-right", "front_right", CELL, PIVOT, frames, {
        "walk": walk,
        "loop": True,
    }, shared_preview_palette=True, preview_background="#FFFFFF",
           preview_order=POSES * 2,
           # On each support phase the heel stays at the contact's screen x.
           preview_advance=(0, 19, 36, 50, 67, 86, 103, 117))


if __name__ == "__main__":
    main()
