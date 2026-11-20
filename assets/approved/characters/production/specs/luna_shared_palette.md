# Shared Luna palette

The playable comparison scene (`scenes/2d/luna_comparison.tscn`) and classic art preview use the approved blue-lilac sprites from `assets/2d/characters/luna/palette_blue_lilac/`. The classic keeps her drawing and uses softer violet and pink shades. Each cast cel matches the thickness of the corresponding idle outline inside the original alpha boundary. Chibi gets the same violet family and more definition in her existing hair and clothing shadows, without thickening the outlines.

The active banks contain 66 classic cels and 100 chibi cels. All eight chibi directions use the new design for idle, four-frame walking with or without the wand, four-frame sprinting, casting anticipation, and standing and moving cast release. The three left-facing views mirror their right-facing counterparts. Sprint stows the wand and lets both arms swing. Action poses reuse the matching walking steps and keep the idle head and hat registered. The palette bake preserves each cel's dimensions and alpha.

The original classic PNGs and source cels used by the bake remain as a legacy baseline for future art revisions. The four unused chibi front-diagonal cels were removed after the canonical front-diagonal set replaced them. To add a pose or regenerate the grade, update its source bank, then run the commands below. Set `final_palette` on a cel already drawn in the final palette so the bake copies its pixels without applying the legacy grade.

```sh
python3 art/tools/bake_luna_palette.py
python3 art/tools/bake_luna_palette.py --check
```

The bake requires Pillow, NumPy and OpenCV. The comparison scene uses Tab to switch variants in place and Shift to run; use Q for chibi's wand and F for casting.
