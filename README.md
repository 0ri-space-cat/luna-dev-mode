# LUNA: Dev Mode — isolated 2D runtime scaffold 🌙

**Branch:** `feat/2d-meta-runtime-scaffold-20261116`.

**Important author decision (20 November 2026): the original 3D graybox and the old puppet-style 2D prototype have been rejected and must never serve as implementation foundations or art references for the final game.** The active canonical documentation is on [main](https://github.com/0ri-space-cat/luna-dev-mode/blob/main/README.md) and [final V6 author decisions](https://github.com/0ri-space-cat/luna-dev-mode/blob/main/docs/canon/30_V6_FINAL_AUTHOR_CHOICES_AND_IMPLEMENTATION_RULES.md). Branch-local legacy V6 documentation predates those decisions and is not authoritative where it conflicts.

## What this branch actually contains

- A separate **experimental 2D gameplay runtime** at `res://scenes/runtime2d/sandbox.tscn` with scripts under `scripts/runtime2d/`.
- Data and tests for this experimental runtime.
- Some **legacy graybox scripts, scenes, historical tests and assets remain alongside it from branch ancestry**, but they are **not the new game and are not a required base**. `scenes/main.tscn` and `scripts/main.gd` are not the run target. Do not copy, migrate or revive their 3D presentation code. The old puppet-based `scripts/2d/` system is absent from this branch.

The experimental 2D runtime **must be reviewed against the latest approved LUNA** before being developed into a true multi-region, multi-input, persistent game. Do not infer that this branch already implements the final game or all its secrets.

## Current approved design resources

1. [Author's V6 bible](https://github.com/0ri-space-cat/luna-dev-mode/blob/main/docs/canon/20_V6_AUTHOR_ONLY_BIBLE.md).
2. [Final author decisions](https://github.com/0ri-space-cat/luna-dev-mode/blob/main/docs/canon/30_V6_FINAL_AUTHOR_CHOICES_AND_IMPLEMENTATION_RULES.md).
3. [Game skeleton handoff](https://github.com/0ri-space-cat/luna-dev-mode/blob/main/docs/drafts/LUNA_MASTER_CONCEPT_AND_SKELETON_HANDOFF_2026-11-20.md).
4. [Ethernia geography draft](https://github.com/0ri-space-cat/luna-dev-mode/blob/main/docs/drafts/ETERNIA_WORKING_TOPOLOGY_V2_2026-11-20.md).

**Do not use the rejected 3D or puppet 2D as a shortcut; reproduce approved game systems with clean 2D logic and temporary assets instead.**
