# ImageGen pixel creatures — starter asset contract

Three optional pixel PNGs can replace the old SVG previews in-place:
- `res://assets/2d/eternia/pixel/characters/fridge.png`
- `res://assets/2d/eternia/pixel/characters/tree.png`
- `res://assets/2d/eternia/pixel/characters/duck.png`

The first art prototypes are **64×80** source pixels. `CreatureVisual2D` uses these authored cutouts at Nearest while preserving the corresponding `EntityRecord`, collision, behavior, color tint and saves.

ImageGen fridge/tree bodies should be drawn **without integrated boots**; `UniversalRoundLegs2D` adds a shared, separately painted `res://assets/2d/eternia/pixel/shared/round_leg.png` whenever `alive=true`. The duck already has organic feet in its artwork, so it must never receive the reusable generic leg module.

Until artistically acceptable pixel cutouts exist at these repo paths, old authored SVG art remains active. This stage prepares sprites **without claiming final AI character design or complete animations**.
