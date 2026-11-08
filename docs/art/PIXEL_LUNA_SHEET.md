# Pixel Luna animation contract (Godot testable)

The current active scene now supports a **real optional ImageGen-derived pixel sprite-sheet** with clean fallback to existing SVG images. This is a technical contract, not a claim of approved final character sprites.

Place at `res://assets/2d/characters/luna/pixel/luna_sheet.png` (or `.webp`).

- Size **96 × 576**, 2 columns × 9 rows, each frame **48 × 64** source pixels, drawn at 2×.
- Rows in order: `idle_down`, `idle_right`, `idle_up`, `walk_down`, `walk_right`, `walk_up`, `cast_down`, `cast_right`, `cast_up`.
- **Left reuses the drawn right pose mirrored.** Cursor determines direction independently of movement.
- Two distinct author-drawn poses per row are enough for the *first prototype*, 6 FPS; 4+ frames can be added in a future verified change. Frame baseline/hat/face/glasses must not shift.
- For now idle blinking, extra hair layers, expressive reactions, and sophisticated cast effects have **not been delivered** by this sheet contract. They need separate artwork and validation. This stage prioritizes real gameplay over pretend animation.
- `tests/test_pixel_luna_2d.gd` proves correct sheet layout, switching, left mirror, idle/walk/cast, and legacy fallback.

Art source status: generated ImageGen storyboard images exist as chat artifacts, but at the time of this commit a **verified high-quality separate alpha sprite sheet has not been placed into GitHub**. The runtime does not make SVG assets look pixel-art until actual artwork is supplied.
