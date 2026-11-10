# LUNA: movement and magic preview

Status: 2026-11-10. Five authored orientations provide eight look directions by mirroring profile and diagonals. All cels use the approved explorer design, moderate eyes, closed smile, plain sleeves, backpack and large lavender crescent wand with pink star.

Open scenes/2d/luna_art_preview.tscn in Godot and run the current scene (F6). Or launch Godot with --path . scenes/2d/luna_art_preview.tscn. Window title: LUNA — движение и магия.

## Controls

- Physical WASD or arrows: normalized movement and facing in eight directions. Stopping retains the last look direction; spells use that direction too.
- Mouse movement does not change facing. The previous mouse-facing mode is retained behind the scene root Inspector property `face_movement_direction` (disable it to compare).
- Left click or Space: a 0.42-second wand gesture. Translation and facing lock briefly during it; one cast_released(direction) signal fires at 0.19 seconds.
- Wheel: visual SIZE from 0.5x to 2x. Camera and player margins keep full canvases visible.
- B / H while standing: preview blink / hair flutter immediately.

Idle bob is ±0.8 world pixels. Walking uses four authored poses at 8 fps, with a 1.5-pixel passing-step lift; in the optional mouse-facing mode, moving opposite the look direction reverses the gait. Blink holds the closed-eye cel for about 0.105 seconds, with idle intervals of 3–6 seconds. Hair tips use a brief alternate cel at intervals of 5–10 seconds.

## Connected assets

| Authored view | Approved idle | Walk | Cast | Blink | Hair |
|---|---:|---:|---:|---:|---:|
| front | 1 | 4 | 3 | 1 | 1 |
| front_right | 1 | 4 | 3 | 1 | 1 |
| side_right | 1 | 4 | 3 | 1 | 1 |
| back | 1 | 4 | 2 | 0 | 1 |
| back_right | 1 | 4 | 2 | 0 | 1 |

Five approved idles are in assets/2d/characters/luna/explorer_v1/. The 41 technical cels are in assets/2d/characters/luna/explorer_animation/<view>/ as walk_00..03.png, cast_00..02.png (rear views stop at 01), blink_00.png and hair_00.png. manifest.json lists every consumed cel, pivot, runtime hash and raw-source hash. Source and runtime dimensions remain 1024×1536; default transform 0.1875 displays a 192×288 nominal canvas with Nearest filtering. No source downsample or separate limb drawing is used. Textures are cached and preloaded before movement begins.

Raw ImageGen masters remain in art/generated/luna/explorer_animation/. Some raw sources contain unwanted low-alpha background noise; these are archival inputs, never gameplay textures. Runtime PNGs have binary alpha and zero RGB in transparent pixels. Visible character RGB is preserved. The five approved idle source masters are unchanged; runtime copies received the same background sanitation.

## Verification and evidence

Godot 4.7.2, real non-headless Metal/OpenGL rendering on Apple M2. Each new candidate was checked at gameplay scale. After the reported smoky frame, candidates were first prepared and reviewed on white and cyan before registration. Generated illustrations and QA plates are not described as game screenshots.

- tests/test_luna_art_preview.gd: eight directions, visibility, mirroring and SIZE.
- tests/test_luna_animation.gd: full bank coverage, distinct cels, state transitions, movement independent from facing, reverse gait clock, aim hysteresis, cast lock and one release signal, return from blink/hair to approved idle.
- tests/test_luna_camera.gd: full texture canvases across states at 0.5x/1x/2x and world corners; no exposed empty terrain.
- ci/validate_luna_animation.py: runtime/source hashes, dimensions, pivots, no semi-transparent background, no hidden RGB, visible artwork unchanged.

All checks passed locally. Individual walk/cast/idle GIFs and pose strips are assembled from actual rendered viewport crops under docs/screenshots/. tests/capture_luna_performance.gd records a 12-second, 16-fps demonstration of the actual controller traversing directions and performing four casts, blink and hair idle. This is a scripted engine demonstration, not manual keyboard QA or a mockup. luna_animation_demo.gif is the assembled recording; luna_size_2x.png is an actual full-viewport 2x-scale capture.

## Current limits

This is the playable art scene. The release signal is ready for gameplay integration; it does not apply a spell or hacking command itself. The wheel is a preview control rather than the authoritative Entity SIZE service. Gameplay entities, saves and Undo/Redo were not refactored in this task.

Mirroring also mirrors wand handedness. Cels retain small silhouette/detail variations from image generation; this is the first complete bank for motion review, not a claim of final hand-pixel cleanup. There is one face-oriented gait per view, reversed for backward movement; dedicated strafing cycles and running/hit/death animations are outside this bank. Existing ground art remains the test surface.

## Art pipeline and prompt set

Built-in ImageGen was used, one full-body cel at a time. Each generation references its approved orientation and, where useful, the matching pose from the first diagonal walk. Shared prompt: preserve exact explorer identity/proportions, glasses/eyes/closed smile, messy pink-lilac hair, purple hat/hoodie/backpack, pink shorts, short socks and high-tops, same crescent wand/hand; deliberate coarse pixel blocks INSIDE face, hair and folds as well as outlines; no vector arcs, gradients, new costume ornaments or atmospheric background. Keep 1024×1536 framing and stable upper-body/head registration.

Walk prompts alternate contact / passing / opposite contact / opposite passing, adapted to the view. Cast poses use a brief shoulder anticipation, an outward wind-up, then a release directed along the gaze. Front, front-right and profile use three cels; rear views use two. Blink changes only the visible eye(s) to short stepped closed-eyelid lines inside unchanged glasses. Hair flutter changes only a few strand tips by roughly 24–32 source pixels, with roots and pose fixed.

prepare_luna_candidate.py produces cleaned PNG and two-background QA before game registration. register_luna_frame.py preserves the raw master, sanitizes runtime alpha/hidden RGB, records bounds and hashes. These tools require Pillow only for asset preparation/QA; the game needs no Python dependency. build_luna_previews.py only assembles real engine screenshots.

## Focused corrections, 2026-11-10

Only back_right/walk_01 and walk_03 were redrawn for walking: match the raised/sloping hat brim of walk_00 while retaining the passing legs and body. All four rear-diagonal walk cels now share source pivot y=1499. registration_offset_y records the intentional distance below the painted support foot; the validator permits this explicit offset. With the existing passing-step lift, head-top variation is 0.75 world pixels at default size. Hat tilt was also checked in the rendered four-pose strip.

Built-in ImageGen edited each cel separately at 1024×1536. Shared edit specification: preserve approved identity, outfit, full-body registration and coarse interior pixel clusters; edit only the named hat or arm/wand area; transparent background without atmosphere, glow, shadow or smoke. Specific cast prompts moved hand/elbow away from the cheek and chest in front, front_right and side_right. Release prompts use foreshortening toward the viewer for front (crescent below the hand), down-right for front_right, and mostly vertical up for back. side_right and back_right release artwork was retained.

The original close front/profile poses are reused as 50 ms anticipation, not as the final gesture. Three-cel timing: idle until 0.06 s, close anticipation 0.06–0.11, outward wind-up 0.11–0.19, directed release 0.19–0.33, then idle. Total cast duration and the single release event at 0.19 s are unchanged. Left-facing versions mirror the corresponding right-facing sequence.

Original affected cels and the previous manifest are preserved under art/archive/luna_animation_2026_11_10/. The experimental uniform blue glow is disconnected from the scene: no shader material or glow key binding is assigned by the controller. Future environment lighting remains unimplemented.
