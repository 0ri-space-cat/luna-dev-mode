#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if ! command -v godot >/dev/null 2>&1; then
  echo "Godot 4.3+ CLI not found. Install Godot, then run: godot --path . res://scenes/2d/world_2d.tscn"
  exit 1
fi
exec godot --path . res://scenes/2d/world_2d.tscn
