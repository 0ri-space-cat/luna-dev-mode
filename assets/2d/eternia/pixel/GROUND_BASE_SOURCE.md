# Ground base: ImageGen source, technical repeat export

- ImageGen artwork: the author's approved 08.11.2026 **calmer grassy texture without flowers**, originally a 1024px rendered picture from the ongoing LUNA chat.
- This 64x64 indexed PNG is a **technical export** of that AI-rendered image, resized with Nearest, gently blended at the tile boundaries and quantized to 24 colors. No artistic pixel shapes have been drawn with code.
- Adjacent first/last pixel rows and columns were checked for exact equality. Repetition preview should still be reviewed in a real Godot scene for recognizable repeated clumps and texture density.
- This is a **first playable candidate**, not artistically final. Future replacement: re-export new approved ImageGen grass at the same path without changing any Godot scene or gameplay.
- Image is intentionally a single material, separate from independent flower/crystal overlays; no 12-way grass palette randomization.
