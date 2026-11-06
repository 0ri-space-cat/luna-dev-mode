# 27 — Asset-ready UI and visual integration contracts (05.11.2026)

> **Технический исторический мануал (ревизия ссылок 06.11.2026).** Актуальная концепция: [28 — Game Bible](28_AUTHORITATIVE_GAME_BIBLE.md), [29 — семь рутов](29_CHARACTER_ROUTES_AND_TOOLS.md), [30 — неизменность мира](30_BEYOND_PROJECTION_AND_OBSERVATION.md), [32 — три основных локации](32_WORLD_AND_CONTENT_PLAN.md), [33 — план разработки](33_IMPLEMENTATION_ROADMAP_2026.md), [34 — решения](34_DECISION_HISTORY_AND_BACKLOG.md). Технические возможности 0.27 не доказывают реализации новых рутов и пазлов. Кокомо исключён из обязательного игрового сценария; лаборатория — доступная отовсюду песочница; Этерния/Нью-Париж/Литтас — три главных области.\n
**Status:** graybox UI foundation [IMPLEMENTED]; final art/audio [NOT CREATED]; several represented systems [NOT IMPLEMENTED]. This pass adds replaceable slots and navigation without claiming the design is final.

## What exists in the project now

- `scripts/luna_shell.gd` adds a persistent HUD shell: Luna portrait placeholder, level slot, HEALTH/MANA/STAMINA bars explicitly marked as unbound data, a stylized minimap placeholder, five quick slots and navigation for INVENTORY/HACK/MAGIC/DIALOGUE/JOURNAL/MAP/SETTINGS/HELP.
- INVENTORY reads actual carried entity IDs through `InventoryService`. It does not add pickup, drag/drop, equipment or item-use controls; those mechanics need UX decisions and integration.
- MAGIC opens the existing spell workshop; JOURNAL points to the existing discovery journal. The established B and J shortcuts remain in place. HACK remains the existing functional editor opened on a selected world object.
- Other destinations are labelled foundation placeholders. Dialogue, a full map, configurable settings, gameplay resource values, hotbar assignment, portrait binding and camera/map navigation are not implemented here.
- `scripts/core/asset_registry.gd` loads typed logical IDs from `assets/asset_catalog.json`. Missing paths resolve as `null`, so callers retain explicit procedural/graybox fallbacks.
- `luna.model` can replace the controller's procedural appearance when a compatible `PackedScene` exists; `luna.portrait` fills the HUD portrait slot when a `Texture2D` exists. Animation, icon, panel, audio and VFX IDs are registered for later consumers but are not played/rendered by this pass.
- The new shell currently uses English text; the established EN/RU selector still localizes the legacy interface. Shell translation is a remaining integration task.
- Existing world and profile SaveService flows remain authoritative. This UI layer introduces no duplicate save format or fake gameplay state.

## Future asset contract

| ID | Type / suggested contract | Current fallback |
|---|---|---|
| `luna.portrait` | square transparent portrait, readable at 64 and 128 px | initials/star badge |
| `luna.model` | Godot 4 scene, humanoid proportions, forward axis -Z, root at floor, collision remains separately owned by controller | current procedural graybox |
| `luna.animations` | AnimationLibrary keyed `idle`, `walk`, `run`, `cast`, `hack`, `hurt`, `interact`; root motion off initially | controller movement only |
| `ui.minimap` | frame/background texture; map content remains a live viewport/drawing layer | green map swatch and marker |
| `ui.inventory_frame`, `ui.hack_frame`, `ui.magic_frame` | panel frame/background with stretch-safe nine-patch margins | StyleBoxFlat panels |
| `icon.health`, `icon.mana`, `icon.stamina` | matching 24/32 px transparent symbols with strong silhouette | text labels |
| `icon.item_unknown` | neutral 48 px silhouette, no baked-in rarity | empty slot glyph |
| `audio.ui_open`, `audio.ui_confirm` | short UI one-shots, normalized and non-looping | silence |
| `vfx.hack_selection` | reusable scene centered on selected entity; no gameplay collision | editor selection only |

**General delivery:** source PNG/WebP for 2D, `.tscn` plus source model for 3D, `.tres` AnimationLibrary, imported Godot audio stream; keep source files and licenses alongside generated outputs. Keep technical IDs, margins, pivots, scale and animation names in metadata/docs, never embedded into textures. UI art should provide transparent margins and tolerate 9-slice scaling. This is a production contract, not an assertion that these files exist.

## Screen and interaction map

| Surface | Base / current connection | Future work |
|---|---|---|
| Player HUD | shell, placeholder resources | AvatarBindingService + real resource/progression model |
| Minimap | decorative placeholder | world bounds, player marker, POI layer, zoom and accessible fallback |
| Backpack | inventory service item list | author-approved slot behavior, selection, actions, equipment and persistence UX |
| Hack editor | existing pause, selected Entity editor, COPY/DELETE/DONE, undo path | art frame, selection VFX, final hover cards |
| Magic | existing block workshop | asset frame, iconography, authored sound feedback |
| Dialogue | named slot only | dialogue model, speaker portrait and response flow |
| Journal | existing discovery journal | shell integration and visual hierarchy |
| Map | named slot only | full-screen map and navigation contract |
| Settings | named slot only | persist language/input/audio/video preferences |
| Help | named slot only | contextual input/tutorial cards |
| Overlays | existing hack tint, save status, journal/workshop/editor | shared modal stack, pause ownership and transition feedback |

## Integration rule

Resolve optional art through AssetRegistry, validate resource type before assignment, and keep the current fallback when absent or invalid. Gameplay services own values and actions; Control nodes render state and forward explicit intents. A missing visual must never block a save, interaction, undo or loading operation.

## Verification

`tests/test_asset_ui_foundation.gd` checks catalog parsing, missing-asset fallback, required resource slots and destination IDs. GitHub Actions imports the project, runs this test and boots the actual main scene. A headless pass cannot verify Mac visual layout, final asset imports, controller navigation, sound mixing or interactive UX.
