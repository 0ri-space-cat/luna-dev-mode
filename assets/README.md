# Prepared game assets

See [the asset index](../docs/art/ASSET_INDEX.md) for current paths, contracts and honest integration status.

- `ui/common/`, `ui/hack/`: reusable UI sources and approved pixel inspector.
- `ui/themes/`, `ui/scenario_icons/`, `ui/profiles.json`: seven character palettes and UI contracts.
- `characters/<id>/ui/`: static portraits and individual backpacks.
- `artifacts/<ID>/`, `artifacts/manifest.json`: 21 transparent artifact masters, with canonical IDs.
- `prepared_asset_catalog.json`: real resource paths for later integration.
- `asset_catalog.json`: existing runtime fallback catalog, unchanged.

No 3D models, new abilities, audio loops or animated portraits are implied by these files. Earlier art iterations and provenance live under `art/`, excluded from Godot import by `.gdignore`.
