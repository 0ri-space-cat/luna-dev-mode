#!/usr/bin/env bash
# Export the existing Adventure entry point with an isolated alpha profile.
set -euo pipefail
if [ "$#" -ne 1 ] || [[ "$1" != /*.zip ]]; then
  echo "Usage: bash ci/build_macos_alpha.sh /absolute/path/to/LUNA-Adventure-Alpha.zip" >&2
  exit 2
fi
output="$1"
project="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
rsync -a --exclude=.godot --exclude=export_presets.cfg "$project/" "$stage/"
cp "$project/ci/macos_alpha.cfg" "$stage/export_presets.cfg"
python3 - "$stage/project.godot" <<'PY'
import sys
from pathlib import Path

project = Path(sys.argv[1])
source = project.read_text()
marker = 'config/name="LUNA: DEV MODE"'
assert source.count(marker) == 1
project.write_text(source.replace(marker, '\n'.join((
    'config/name="LUNA Adventure Alpha"',
    'config/use_custom_user_dir=true',
    'config/custom_user_dir_name="LUNA Adventure Alpha"',
    'config/version="0.1.0-alpha"',
))).replace('[rendering]\n', '[rendering]\n\ntextures/vram_compression/import_etc2_astc=true\n'))
PY
mkdir -p "$(dirname "$output")"
godot --headless --editor --path "$stage" --import --quit
godot --headless --path "$stage" --export-release "macOS Alpha" "$output"
