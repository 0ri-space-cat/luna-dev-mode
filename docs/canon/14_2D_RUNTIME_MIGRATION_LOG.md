# 14 — 2D runtime migration log

Status: experimental branch `feat/2d-runtime-foundation`. Main game entry remains legacy 3D until acceptance tests pass.

## Verified from source
- `project.godot` points at `scenes/main.tscn`.
- `scenes/main.tscn` is a `Node3D` scene.
- `scripts/main.gd` extends `Node3D` and creates a `CharacterBody3D` and `Camera3D`.
- `scripts/core/entity_record.gd` is a `RefCounted` data model independent of 3D nodes.
- Current 2D scene is a disposable visual/physics smoke-test scaffold, NOT the final world and NOT wired to gameplay services.

## Guardrails
1. Keep `main` and the existing 3D scene runnable until 2D parity is verified.
2. Preserve Entity IDs, typed parameters, transactions, provenance and Undo/Redo.
3. Extract game service composition from legacy `main.gd` into a presentation-independent context before swapping startup scenes.
4. Define and test save migration for 3D x/z coordinates into 2D x/y; never silently reinterpret coordinates.
5. Build tile terrain from seamless base textures and boundary geometry; do not bake tile-grid outlines into art.
6. Validate 2D collision, camera, entity editing, save/load and headless tests before removing legacy 3D code.

## First milestone
A separate `scenes/2d/world_2d.tscn` with `Node2D`, `CharacterBody2D`, `Camera2D` and a code-drawn test ground. This is not yet connected to `project.godot` and has not been run through Godot CLI in this environment.

## Next technical tasks
- Run Godot headless parse/import of the isolated scene; fix any errors.
- Move service initialization out of legacy `main.gd` into a reusable 2D-neutral game context.
- Attach an Entity ID to 2D visual actors, with commands updating the canonical record.
- Add collision-aware TileMapLayer test grounds and build two terrain compositions from the same tiles.
- Implement deterministic atlas slicing and seam-check tooling before bulk image generation.
