#!/usr/bin/env bash
# Run a headless Godot test and catch engine errors that don't change exit code.
set -euo pipefail
if [ "$#" -ne 1 ]; then
  echo "Usage: bash ci/run_godot_script.sh res://tests/test_name.gd"
  exit 2
fi
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
set +e
timeout 40s godot --headless --path . --script "$1" 2>&1 | tee "$log"
godot_status=${PIPESTATUS[0]}
set -e
if [ "$godot_status" -ne 0 ]; then
  echo "::error::Godot test failed or timed out ($godot_status): $1"
  exit "$godot_status"
fi
if grep -E 'SCRIPT ERROR|Parse Error|Failed to load script|Invalid call|Assertion failed' "$log"; then
  echo "::error::Godot script/runtime error in $1"
  exit 1
fi
# Known Godot 4.3 dummy-renderer diagnostic during headless MeshInstance3D
# creation. Report its count but do not hide any unrelated engine error.
if grep '^ERROR:' "$log" | grep -Fv 'ERROR: Parameter "m" is null.'; then
  echo "::error::Unexpected Godot engine ERROR in $1"
  exit 1
fi
ignored="$(grep -c -F 'ERROR: Parameter "m" is null.' "$log" || true)"
if [ "$ignored" -gt 0 ]; then
  echo "::notice::Known headless dummy-renderer mesh diagnostics ($ignored) in $1"
fi
