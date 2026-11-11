# Runtime foundation audit

Audit basis: `origin/main` at `0f23f12` (11 November 2026), PR #17 and #18 merged. The current playable project still boots its graybox through `Node3D`; this change adds an engine-independent time/history service but does not migrate the scene graph.

| Area | Exists on main | This slice | Remaining work |
|---|---|---|---|
| Typed parameters/components and applicability | `ParameterRegistry`, `ComponentRegistry`, `EntityRecord` | None | One shared declaration layer and explicit component compatibility rules |
| Commands, transactions, undo/audit and permissions | `CommandProcessor`, `WorldAccessService`; atomic batches and tool authority tests | None | Normalize authorization/validation across every future command producer; distinct Luna/wand policy contract |
| Rules and events | Bounded `RuleEngine`, queued `EventBus`, condition/action grammar | None | Explicit WHEN/IF/DO public command format and transition routing |
| Effects | `EffectEngine`, elemental statuses, atomic world changes | None | Common source/target/delivery/duration/stack/resistance/rollback envelope; wider general effect catalog |
| Consumables | `ConsumableService` applies configured effects and supports splash/area | None | Generic liquid collision, coating, spill and contact simulation, pending a 2D physics adapter |
| Programmable spells | `SpellWorkshopService` stores bounded recipes; `SpellService` executes them | None | Generalize recipes away from current command/effect constraints; no in-flight projectile editing per approved canon |
| Saves and recovery | Versioned `SaveService`, typed validation, checkpoint rollback, entity/effect/rule state | None | Reusable rewind history, complete simulation-state inventory, schema migration policy |
| World time and rewind | No dedicated clock/history service | Added portable dual clock, bounded validated data snapshots, rewind and recovery state | Connect a renderer/physics-neutral world snapshot provider; include every active simulation subsystem before claiming complete rewind |
| Clone limits | Bounded creation in magic and saves; copy identity/origin persistence | None | Standalone clone policy/service, recursive ancestry limits and visual inheritance |
| Observation, perception and camera | Some awareness/visibility behavior exists; current camera/player are scene-bound | None | Separate observer/player/camera contract and WorldTruth/Perception/Rendering layers |
| HUD/meta interactions and palette grading | Existing UI and saved properties; V6 visual direction is documented | None | Physical HUD/inventory rooms/minimap contracts and render adapter for zonal grading |
| Safety/glitch recovery | Multiple local caps and transactional save rollback | Timeline adds bounded history and ERROR/recovery signals | One shared operation/memory/tick budget and player-facing controlled-glitch flow |

## Time service contract

`TimeService` has separate world and control clocks. World time scale is finite and capped at 4; zero pauses world advancement while control time continues. Callers provide `capture`, `validate`, and atomic `restore` callbacks over plain data. The service keeps a bounded ring of up to 240 snapshots, caps each JSON-encoded snapshot at 1 MiB and total history at 8 MiB, rejects non-JSON values, and enters `ERROR` when capture or restore fails. A caller must provide a restore callback with transaction semantics; the service cannot make arbitrary engine mutations atomic itself.

The current `SaveService` is not yet wired as the time provider: its snapshot contract is `Node3D`-specific and does not include all transient actors such as live projectiles. Therefore this is a tested foundation API, not a claim that full-world rewind is already available in the playable scene.
