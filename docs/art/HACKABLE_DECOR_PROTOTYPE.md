# Prototype B: shared feet + promotion of nearby decoration

- Fridge and tree use `UniversalRoundLegs2D`: left/right `Sprite2D` feet driven by one small reusable movement cycle. Approved ImageGen `pixel/shared/round_leg.png` has priority, fallback is the already-authored `luna/boot.svg`. The fallback is **not final art**.
- Static grass/flower/crystal decorations do **not** allocate physics or AI.
- When a nearby decoration is clicked after rift unlock, `World2D._promote_decoration` creates an `arcane_object` with a persistent ID. The original static Sprite2D is hidden. The object can change `alive`, color, size and AI behavior through existing editor/commands.
- After loading a save, scene hides already promoted static decorations again. Cloning, Undo/Redo and deletion use existing lifecycle.
- `EntityActor` derives flower/crystal visual kind from stable ID prefixes. These use existing authored WebP fallback until dedicated transparent pixel art is imported.
- Missing: real ImageGen round-leg asset, finished sprite animations for the four directions, actual WALK transferable capability, and proof of visual quality in a native Godot screenshot. These are **not** claimed complete.

QA: `test_hackable_decor_2d.gd` exercises promotion, animation toggling and persistence.
