# Luna chunky-pixel experiment, 2026-11-09

Generated separately with the built-in ImageGen tool, sequentially: front, front-right three-quarter, right profile, then back. Each uses the previous art as references. PNGs retain their generated 1024x1536 dimensions and alpha. Runtime copies are in assets/2d/characters/luna/chunky_v1/. No downsampled intermediate atlas is used.

Prompt specification shared by these three calls: preserve Luna's purple witch hat, round glasses, violet eyes, pink/lilac hair, purple cat hoodie, skirt, striped socks, shoes, large lavender crescent wand with small pink star. Draw deliberately chunky square clusters as a logical 192x288 sprite enlarged on a 1024x1536 canvas; thick stepped outlines, limited palette, no fine texture. Full body, consistent framing and feet baseline, one pose, transparent background, no glow, floor or effects.

Per-view prompts: front-facing neutral idle; rotate the entire character 45 degrees toward the right in a front-right three-quarter view with both eyes visible; rotate fully into a strict right profile with only one eye visible. The front uses luna_front_idle_source_v5_large_crescent.png as design reference; diagonal uses the new front; profile uses both new views.

## Runtime

Open scenes/2d/luna_art_preview.tscn and run the current scene (F6). WASD/arrows move; mouse chooses front, front diagonals or profiles; wheel adjusts visual size from 0.5x to 2x. Aiming straight up selects the new back view. Rear diagonals still keep the previous view until their own artwork exists. This is an art playground, not the main gameplay scene or a replacement for hacking/save systems.

Nearest filtering, base transform 0.1875: nominal canvas size 192x288 world units. This avoids destructive preprocessing but still samples the texture at the final screen size. Fractional scales may create uneven pixel widths and shimmer. World size and collision integration are unchanged; SIZE here is a preview control, not the entity parameter service.

Subtle idle bob and movement bounce are present; these are not authored walk frames. Mirroring also mirrors the wand hand and clothing details. Hat/face silhouettes vary slightly between authored views. Ground is the existing noisy repeated texture, not newly polished terrain.

## Verification

Godot 4.7.2 non-headless Metal/OpenGL rendering captured docs/screenshots/luna_chunky_{front,diagonal,side}.png at 1280x800. Front and diagonal captures inspected. tests/test_luna_art_preview.gd passed for texture loading, nearest filtering, canvas dimensions, base scale and directional selection. Motion smoothness remains a visual review item, not proven by these still captures.

## Cleanup and back view

Built-in ImageGen produced front_eyes_v2.png from front.png with this targeted edit prompt: change only eye highlight pixels, remove the stray lower white spill in the character's left eye, keep one compact rectangular highlight per iris and preserve glasses, expression, clothing, pose and chunky pixel style. Original front.png remains available. Both front and runtime now use front_eyes_v2.png.

Back view prompt: create one strict back-facing Luna using approved cleaned front and side references; match height and framing on 1024x1536, same large stepped pixel clusters, pink/lilac hair covering upper back, witch hat, hoodie/skirt, striped socks, heel view of purple shoes, large lavender crescent wand with pink star; no face, backpack, front cat pocket or front shoe stars on the back, no effects or floor, transparent background. Saved back.png as source and runtime copy.

Visually reviewed all three previous source drawings; compacted front eye highlights. Front correction and back were inspected in actual Godot renders, including docs/screenshots/luna_chunky_back.png. Alpha bounds checked: no clipped opaque silhouette. Per-view feet baselines now align the four views at the rig origin even when size changes. Head/hat silhouettes still differ between drawings, and mirrored views change wand handedness. No claim of completed animation cleanup.

Godot scene test passed after adding back-view loading and UP selection. Upper diagonal selection remains deliberately unavailable. Next asset: rear three-quarter view.
