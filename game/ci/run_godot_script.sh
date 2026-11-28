#!/usr/bin/env bash
# Run a headless Godot test and catch engine errors that don't change exit code.
set -euo pipefail
if [ "$#" -ne 1 ]; then
  echo "Usage: bash ci/run_godot_script.sh res://tests/test_name.gd"
  exit 2
fi
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
# The integrated Administrator regression walks the full forest-valley route
# multiple times and restarts the profile. The public campaign walks from
# the default start to the ordinary credits and the physical White Void route.
# The refuge regression retraces both passages and simulates the NPC schedule.
budget=40s
case "$1" in
  res://tests/test_skeleton_administrator.gd|res://tests/test_skeleton_proto_refuge.gd) budget=80s ;;
  res://tests/test_skeleton_luma_city.gd) budget=170s ;;
esac
set +e
timeout "$budget" godot --headless --path . --script "$1" 2>&1 | tee "$log"
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
