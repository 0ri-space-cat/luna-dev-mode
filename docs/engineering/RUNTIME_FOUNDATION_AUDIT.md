# Runtime foundation audit

Audit basis: `origin/main` at `0f23f12` (11 November 2026), PR #17 and #18 merged. The current playable project still boots its graybox through `Node3D`; this change adds an engine-independent time/history service and connects it to the graybox. The scene graph is still 3D.

| Area | Exists on main | This slice | Remaining work |
|---|---|---|---|
| Typed parameters/components and applicability | `ParameterRegistry`, `ComponentRegistry`, `EntityRecord` | None | One shared declaration layer and explicit component compatibility rules |
| Commands, transactions, undo/audit and permissions | `CommandProcessor`, `WorldAccessService`; atomic batches and tool authority tests | None | Normalize authorization/validation across every future command producer; distinct Luna/wand policy contract |
| Rules and events | Bounded `RuleEngine`, queued `EventBus`, condition/action grammar | None | Explicit WHEN/IF/DO public command format and transition routing |
| Effects | `EffectEngine`, elemental statuses, atomic world changes | None | Common source/target/delivery/duration/stack/resistance/rollback envelope; wider general effect catalog |
| Consumables | `ConsumableService` applies configured effects and supports splash/area | None | Generic liquid collision, coating, spill and contact simulation, pending a 2D physics adapter |
| Programmable spells | `SpellWorkshopService` stores bounded recipes; `SpellService` executes them | None | Generalize recipes away from current command/effect constraints; no in-flight projectile editing per approved canon |
| Saves and recovery | Versioned `SaveService`, typed validation, checkpoint rollback, entity/effect/rule state | The graybox uses the existing snapshot transaction for in-memory rewind | Complete simulation-state inventory and schema migration policy |
| World time and rewind | No dedicated clock/history service | Portable dual clock and bounded history; the graybox records/restores save-backed simulation state | Full world time scaling, and exact restoration of transient simulation state |
| Clone limits | Bounded creation in magic and saves; copy identity/origin persistence | None | Standalone clone policy/service, recursive ancestry limits and visual inheritance |
| Observation, perception and camera | Some awareness/visibility behavior exists; current camera/player are scene-bound | The graybox camera supports FOLLOW/LOCKED; portable observation rules and optional 3D collision adapter | Compute Luna sight and player screen coverage in the level adapter; integrate perception, rendering and NPC reactions |
| HUD/meta interactions and palette grading | Existing UI and saved properties; V6 visual direction is documented | Optional grading adapter for a composited world viewport | Physical HUD/inventory rooms/minimap, 2D scene and zone wiring, visual QA |
| Safety/glitch recovery | Multiple local caps and transactional save rollback | Timeline adds bounded history and ERROR/recovery signals | One shared operation/memory/tick budget and player-facing controlled-glitch flow |

## Time service contract

`TimeService` has separate world and control clocks. World time scale is finite and capped at 4; zero pauses world advancement while control time continues. Callers provide `capture`, `validate`, and atomic `restore` callbacks over plain data. The service keeps a bounded ring of up to 240 snapshots, caps each JSON-encoded snapshot at 1 MiB and total history at 8 MiB, rejects non-JSON values, and enters `ERROR` when capture or restore fails. A caller must provide a restore callback with transaction semantics; the service cannot make arbitrary engine mutations atomic itself.

### Graybox controls (debug builds)

- F7 records an in-memory checkpoint. Automatic checkpoints are recorded after world ticks, every half second.
- F8 restores the latest checkpoint. Shift+F8 restores the preceding recorded checkpoint.
- F10 toggles the camera between FOLLOW and LOCKED. Camera state belongs to the view and is independent of checkpoints.

Restore uses the existing save transaction and reconciles actor lifecycle and inventory after it succeeds. Checkpoints cover actor positions, velocities and records, recreatable actors, copies, deletions, relationships, elemental statuses, surface fields, social awareness and rules. Restore discards in-flight projectiles and queued events, resets zone tracking and ability cooldowns, and clears command undo history. Disk load starts a new timeline, and disk saving is suspended while the timeline reports an error. There is no save format change.

This adapter runs at normal physics speed. World scale on the portable clock does not yet drive Godot physics. Exact rewind requires state for AI internals, projectiles and cooldowns, and a policy for frame and zone transitions.

### Observation

`ObservationRules` separates visibility and solidity. It resolves distinct rules for permanent solidity, solidity when Luna is not looking, solidity when the player is not observing through the camera, and solidity only while Luna's eyes are open. Camera observation can independently block a transition. `observation_surface_3d.gd` applies the result to a static body. The headless test verifies actual collisions including an invisible solid surface. The scene supplies gaze and screen coverage; the adapter does not assume how future levels compute them.

### World grading

Attach `world_grade_rect.gd` to the TextureRect that displays the world SubViewport. Keep the HUD in the outer viewport. The grade reads only the world texture, uses nearest sampling and preserves source alpha. `set_grade()` accepts saturation, contrast, brightness and RGB tint, with an optional transition in seconds. Use a transparent world viewport where compositing needs transparency. Set nearest filtering for sprites inside it separately. The headless test covers binding, filtering, invalid profiles and transitions. Final pixel appearance and performance need a rendered 2D scene.
