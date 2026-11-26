"""Export the working inspector palette from the original pixel textures."""

import colorsys
import json
from pathlib import Path

from PIL import Image, ImageColor

SOURCE = Path(__file__).resolve().parent
DESTINATION = SOURCE.parent / "prepared"
KIT = SOURCE.parents[2] / "approved/hud/godot/retro-ui-kit/assets/ui/pixel-v1"
STATES = ("normal", "hover", "pressed")
COOL_TABS = ("tab_general", "tab_mind", "tab_behavior", "tab_relationships")


def rgba(hex_code):
    return ImageColor.getrgb(f"#{hex_code}") + (255,)


def load(path):
    return Image.open(KIT / f"{path}.png").convert("RGBA")


def export(image, path):
    path = DESTINATION / f"{path}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def remap(image, palette):
    output = Image.new("RGBA", image.size)
    output.putdata([palette.get(pixel, pixel) for pixel in image.getdata()])
    return output


def action(theme, kind, state, shades):
    suffix = "" if state == "normal" else f"_{state}"
    if kind == "save":
        original = f"themes/{theme}/button_save{suffix}"
    elif kind == "copy" and theme == "luna":
        original = f"themes/luna/copy_{state}"
    else:
        original = f"common/button_{kind}_{state}"
    image = load(original)
    width, height = image.size
    rim = load(f"themes/{theme}/tab_normal").getpixel((12, 0))
    body, shine, shadow = map(rgba, shades)
    highlight = rgba("F5F9F3") if state == "hover" else shine
    lowlight, side = (highlight, shadow) if state == "pressed" else (shadow, highlight)
    return remap(image, {
        image.getpixel((width // 2, 0)): rim,
        image.getpixel((width // 2, 1)): side,
        image.getpixel((width // 2, height // 2)): body,
        image.getpixel((width // 2, height - 2)): lowlight,
    })


def icon(image, kind, theme):
    """Keep the glyph alpha and light/dark structure, tone down pink in the icons."""
    accent = {"copy": 0.74 if theme == "luna" else 0.54, "delete": 0.025}[kind]
    result = []
    for red, green, blue, alpha in image.getdata():
        if not alpha:
            result.append((red, green, blue, alpha))
            continue
        _, light, saturation = colorsys.rgb_to_hls(red / 255, green / 255, blue / 255)
        saturation = min(0.42, saturation * 0.68)
        if light < 0.25:
            accent_hue = 0.67 if theme in ("luna", "oni", "miya", "ori", "yuki") else accent
        else:
            accent_hue = accent
        channels = colorsys.hls_to_rgb(accent_hue, light, saturation)
        result.append(tuple(round(channel * 255) for channel in channels) + (alpha,))
    image.putdata(result)
    return image


def cool_tab(image):
    result = []
    for red, green, blue, alpha in image.getdata():
        hue, light, saturation = colorsys.rgb_to_hls(red / 255, green / 255, blue / 255)
        if alpha and (hue > 0.79 or hue < 0.035) and saturation > 0.23:
            channels = colorsys.hls_to_rgb(0.585, light, min(saturation, 0.60))
            red, green, blue = (round(channel * 255) for channel in channels)
        result.append((red, green, blue, alpha))
    image.putdata(result)
    return image


def main():
    palettes = json.loads((SOURCE / "palette.json").read_text())
    for part in COOL_TABS:
        export(cool_tab(load(f"common/{part}")), f"cool-tabs/{part}")
    for theme, palette in palettes.items():
        for kind in ("save", "copy", "delete"):
            for state in STATES:
                name = f"button_{kind}_{state}"
                export(action(theme, kind, state, palette[kind]), f"{theme}/{name}")
        for kind in ("copy", "delete"):
            export(icon(load(f"common/icon_{kind}"), kind, theme), f"{theme}/icon_{kind}")
        if "active" in palette:
            original, replacement = map(rgba, palette["active"])
            for part in ("tab_selected", "toggle_on", "field_focus"):
                image = load(f"themes/{theme}/{part}")
                export(remap(image, {original: replacement}), f"{theme}/{part}")
        error = load(f"themes/{theme}/field_error")
        export(remap(error, {rgba("F45173"): rgba(palette["delete"][0])}), f"{theme}/field_error")


if __name__ == "__main__":
    main()
