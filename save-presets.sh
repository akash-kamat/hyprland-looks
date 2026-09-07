#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || exit 2
plugin_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp "$plugin_dir/presets.json.XXXXXX")
printf '%s\n' "$1" > "$tmp"
mv "$tmp" "$plugin_dir/presets.json"
