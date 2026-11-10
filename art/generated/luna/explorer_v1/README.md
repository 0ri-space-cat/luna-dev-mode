# Luna explorer turnaround — 2026-11-09

Approved personality anchor: front_right.png. The user approved this curious, untidy explorer design and the final front.png; side and front diagonal art must remain unchanged. Five authored views give eight gameplay directions by mirroring side and both diagonal views. Source PNGs here are copied unchanged to assets/2d/characters/luna/explorer_v1/. They remain 1024x1536 RGBA; runtime uses nearest filtering and scale 0.1875 (192x288 nominal canvas), with per-view feet baselines. No destructive intermediate downsample.

## Generation and prompt record

All assets were generated separately using built-in ImageGen. front_right.png used the user's three concept crops: curious scrappy explorer, moderately sized eyes, small closed asymmetric smile, loose lilac-pink hair, huge purple floppy witch hat, plain purple hoodie with white cat chest emblem, pink shorts, long bare legs, short pale socks with single purple band, purple high-top sneakers, small purple explorer backpack, lavender crescent wand and small pink star. No sleeve moon, frills, gold buckles or baby-doll proportions. Coarse square pixel clusters, stepped dark purple outlines, limited palette, transparent background, no floor or aura.

front.png final prompt: redraw a fresh frontal view from the approved diagonal plus user pixel-concept crops, prioritizing a natural curious face, round pixel-stepped glasses, modest oval eyes and simple dark-violet pupils with small catchlights, relaxed short eyebrows partly covered by bangs, tiny nose and small closed smile. No severe eyebrow arch, giant glossy eyes, square glasses or rectangular eye blocks. Keep the approved explorer outfit/proportions and 1024x1536 framing. This final version supersedes local face trials that the user rejected.

side_right.png prompt: rotate exact approved diagonal/front into strict right profile, one eye visible through round glasses, same character proportions, relaxed smile, backpack behind shoulders, lavender crescent wand in front, same coarse clusters and framing. The user asked to preserve this and the approved front diagonal.

back.png prompt: strict back view of approved diagonal/profile, matching hat, messy hair, compact backpack under hair, plain hoodie, shorts, socks and sneaker heels, no face, no chest emblem on back, no effects, same full-body framing and pixel style.

back_right.png prompt: add the missing rear-right three-quarter northeast pose, halfway between approved back and profile, predominantly show back/hair/backpack, only cheek/glasses edge at right, coherently rotated feet and hat, same clothing, crescent wand, proportion, clusters and framing. No face toward viewer, no front cat emblem on back.

## Runtime and verification

Run scenes/2d/luna_art_preview.tscn with F6. WASD/arrows move independently of mouse-selected eight-direction facing. Wheel changes the preview visual size from 0.5x to 2x. The actual entity SIZE service is not connected to this art playground; gameplay/save systems remain separate. Authored walking, casting, blinking and hair-flutter cels are now connected through explorer_animation/manifest.json. See docs/LUNA_ANIMATION_PREVIEW.md.

Godot 4.7.2 actual non-headless Metal/OpenGL renders are in docs/screenshots/luna_explorer_{front,diagonal,side,back,back_diagonal}.png. Front, side and both rear views inspected at runtime scale. luna_explorer_turnaround.png is an actual engine-rendered eight-view comparison gallery, not a normal gameplay layout. Reproduce with tests/capture_luna_turnaround.gd. Headless tests/test_luna_art_preview.gd passed all eight direction choices, exactly-one-view visibility, mirror flags and feet alignment at 0.5x, 1x and 2x.

## Limits and next-frame art rule

The user noted that some internal lines/shading look smoother and more cartoon-like than the contours. Current approved views stay intact. For EVERY future animation frame, the ImageGen prompt must require visible square color clusters and stepped transitions INSIDE face, eyes, hair, hoodie folds and shadows, not merely around the silhouette; no vector curves, airbrushed shading or fine gradients. Nearest display reduces visible smoothing at game scale but does not create authored pixel consistency. This remains an art-quality limitation, not a solved technical issue.

Mirroring changes wand handedness. Individual drawings retain modest silhouette/hat and pose differences; fully smooth motion has not been established by still renders. The directional animation bank has now been completed and tested in the art playground. Next is user review of movement timing and later integration into the gameplay actor. All older chunky_v1 assets remain available.
