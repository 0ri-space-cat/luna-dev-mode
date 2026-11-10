# Rear cast palette correction — 2026-11-10

The live interactive recording confirmed the reported pale flash occurs on `explorer_animation/back/cast_01.png`, the highest straight-back wand pose. All recorded frames had normal white modulation, no body material, and no visible hand overlay. The prior outline-only investigation missed this interior color difference.

Only this cel received a material palette correction against the approved straight-back idle. Violet RGB offset: (-3, -9, +4); pink hair/trim: (-1, -12, +12); skin: (-2, -3, +6). Dark outlines and neutral highlights are retained. No pixels were moved or resampled; resolution, alpha, silhouette, pose, wand and pivot remain unchanged. The original generator output is preserved under `art/archive/luna_rear_cast_palette/cast_01_original.png`.

Reproduce the technical color correction with `art/tools/match_luna_cel_palette.py SOURCE REFERENCE OUTPUT`, then register the result using `art/tools/register_luna_frame.py OUTPUT back cast 1 --pivot-y 1496`.

Validation: all 61 current runtime cels pass source/hash/alpha/pivot checks; all five approved idles remain unchanged. The corrected cel was rendered in the actual Godot scene. User confirmation of the revised transition remains pending.

## Superseded by an authored redraw

The user confirmed palette matching reduced the white flash but still revealed a different drawing style. The active `back/cast_01.png` was therefore regenerated through built-in ImageGen, using `back/cast_00.png` as the edit target and the approved straight-back idle as identity/palette reference. Only this release cel was replaced. The earlier palette-only version remains archived as `art/archive/luna_rear_cast_palette/cast_01_palette_corrected_superseded.png`; do not apply the old color-transfer script to the new cel.

The new full source remains 1024×1536. Runtime preparation only thresholds alpha and clears hidden RGB, without resizing or sharpening. Ground pivot is [512,1498], matching the new cel's baseline. White/cyan transparency checks, a native-resolution detail inspection and actual Godot rendering were performed. The 61-cel validator and classic facing/mirror/feet/SIZE test pass. Final prompt and reference roles are recorded in `art/specs/luna_back_cast_redraw.md`.
