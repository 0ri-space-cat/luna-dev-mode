# 15 — Два режима палочки и магическая консоль Юки
Status: implementation proposal + initial policy code, pending in-game integration. 08.11.2026.

## Intent
Light fantasy about changing reality, not a programming simulator. Every command has a visible effect and a playful Russian description. Technical CAPS keys are optional inner labels, initially gibberish until Oracle Eye. UI categories and buttons remain Russian.

## Wand access (exactly two tiers)
- **ШАЛОСТИ** (`PLAYFUL`): ordinary enchanted wand, accessible immediately. Tint, resize within safe bounds, nudge, rename, inspect, silly behavior, basic vitality and movement; familiar spellcasting remains independent. Copying the wand is possible as a real Entity operation. Do not gate basic fun behind a chapter or XP.
- **АРХИТЕКТОР** (`ARCHITECT`): after a real duplicate of the wand is used to edit the original wand's `ACCESS_TIER`. Grants deeper entity inspection, paths, portals, gravity, global-time interfaces, relationships, ability transfer and avatar/system interaction where the target permits it. There is no middle tier and no grinding.
- Access tier ≠ scan depth ≠ Oracle Eye translation ≠ target lock. A hacked wand can still fail against genuinely external or LOCKED structures. Knowledge-first secrets are available whenever physical conditions are met.
- This is a design for two modes, **not** an assertion that the runtime already enforces these permissions.

## Player-facing verbs
«Посмотреть», «Подкрасить», «Изменить размер», «Подвинуть», «Переименовать», «Скопировать», «Отменить»; after self-hack: «Перенаправить», «Поменять местами», «Забрать способность», «Передать способность», «Изменить притяжение», «Замедлить мир», «Открыть проход», «Переключить героя».
Dangerous delete is contextual and undoable. Time travel and teleportation must have clear visual previews and safe recovery. No code typing required.

## Yuki: distinct fantasy
Yuki carries a **portable magical console** that can see and manipulate **connections between things**: routes, doors, echoes of previous edits, event chains and authored traces. Luna is best at changing **what a thing is**; Yuki is best at seeing and changing **how things connect**. Yuki can draw a glowing path between nodes and redirect multiple routes at once, follow a trace of an earlier change, compare two states and stage a sequence of linked actions. These are diegetic tactile diagrams, not a terminal requiring syntax. Console UI: constellation-like nodes and ribbons; one-click suggestions; optional advanced details.
Yuki must not monopolize basic route edits: Luna's hacked wand can edit TARGET_LOCATION and simple NPC paths. Yuki's advantage is visual multi-object orchestration, trace analysis, and her unusual relationship to the simulation.

## UX and visual architecture
At 1280×720 target, top-left character portrait + HEALTH/MANA/STAMINA; top-right circular minimap; bottom-left character-specific backpack; bottom quick slots; lower-right adaptive entity editor. The editor is a UI overlay, never baked into the terrain atlas. Character profiles recolor frame, particles and inventory; core actions remain consistent. On narrow screens UI must rearrange rather than obscure all play.
New 2D scene is still a smoke-test scaffold; production UI, services and 2D entity adapters are pending.

## Engineering acceptance
- A single wand cannot self-elevate; a separate duplicate of same origin can.
- No fake level gating, no XP.
- Deep commands denied by policy before upgrade and available after, subject to target constraints.
- Yuki's console shares WorldRegistry, CommandProcessor, EventBus and SaveService with Luna; no duplicate world.
- Save/load preserves access state and audit provenance.
- Old 3D runtime remains untouched until 2D integration and headless tests pass.
