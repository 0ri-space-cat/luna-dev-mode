# Starter meadow: repeating base + independent prop sprites

This experimental Godot scene preserves a **continuous world**, existing character positions, saves and the tall hack inspector.

- `GroundSurface` uses one authored repeating texture. If `assets/2d/eternia/pixel/ground_base.png` is installed, it takes precedence; until then, the scene uses an **existing authored** `terrain/grass_1.png`. The former 12-cell `Terrain` is preserved but hidden for rollback.
- `GroundDecorScatter` instantiates existing separately painted flower/crystal images with a fixed random seed and exclusion zones. It prefers `assets/2d/eternia/pixel/decor/flower.png` and `crystal.png` when approved art is installed, and otherwise falls back to existing transparent WebPs. These are static decorative nodes; **they are not yet individually hackable Entity**.
- `LunaPuppet2D.set_motion(movement, running, delta, aim)` uses the **mouse aim vector** for orientation, independent of WASD. A 3-argument legacy call preserves movement-facing behavior for backward compatibility.
- Current Luna/creatures use **temporary SVG illustrations and temporary movement**. This patch **does not deliver newly authored character sprite sheets or finished animations**. No final pixel assets have been invented by Python.
- The new layout is compatible with pixel art as well as a painted 2D source, provided it is truly repeatable. The final art requires ImageGen outputs and in-Godot visual QA. Source placement/tiling is verified in `tests/test_modular_meadow_2d.gd`.

Next independent tasks: confirm one genuinely seamless neutral grass image; replace temporary character visuals with actual four-facing sprites, short idle/walk/cast cycles; introduce one small hackable decoration with stable identity and persist its promotion; universal ImageGen-drawn round-leg overlay for fridge/tree.
