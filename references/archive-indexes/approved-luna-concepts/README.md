# LUNA: DEV MODE — Approved concept references

Curated by the project author (November 2026). Use these visual references to guide implementation, not as evidence that the features or models already exist in Godot.

## Four selected image assets (original PNGs)

| Target filename | Use |
|---|---|
| `menu-with-buttons.png` | Start-menu composition with example pixel-neon buttons; create actual interactive buttons in Godot |
| `menu-background-no-buttons.png` | Same start-menu background without buttons; preferred clean backdrop for native menu controls |
| `gameplay-concept-approved.png` | Author-preferred game-screen concept: Luna, bright tiered meadows, waterfalls, cartoony creatures, HUD, inventory, hack panel |
| `luna-character-modeling-guide.png` | Luna turnaround and visual reference for the future stylized 3D model, with toon outlines and accessories |

**Transfer status:** the four original image files were collected and verified in the conversation archive `luna-approved-references.zip`; the archive is not committed to GitHub yet. Upload the PNG files from that archive to this folder before treating the reference package as complete.

## Usage notes

- Preserve the look: stylized **3D designed to read as 2D**, with clear outlines, soft cel-shading, bright greens, lilac/violet outfits and playful expressions.
- The first menu uses **START GAME / OPTIONS / EXIT** as **visual guidance** only; actual buttons must be coded and localizable.
- Use the clean no-buttons title screen for Godot's runtime menu.
- Character and gameplay images are art references, not 3D models, textures that can be plugged directly into Godot, or gameplay captures.
- Follow `docs/canon/` for current narrative/system canon and `art/source/hack/DIRECTION.md` for the hack editor's accepted vertical pixel layout.
- To avoid misleading screenshots, clearly label concept images as concept art when sharing outside the repository.
