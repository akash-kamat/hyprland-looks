#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 8 ]]; then
  echo "usage: apply.sh rounding active inactive blur size passes inner outer" >&2
  exit 2
fi

rounding=$1; active=$2; inactive=$3; blur=$4; size=$5; passes=$6; inner=$7; outer=$8

case "$blur" in true|false) ;; *) exit 2 ;; esac
for value in "$rounding" "$size" "$passes" "$inner" "$outer"; do
  [[ "$value" =~ ^[0-9]+$ ]] || exit 2
done
for value in "$active" "$inactive"; do
  [[ "$value" =~ ^0\.[0-9]+$|^1(\.0+)?$|^0$ ]] || exit 2
done

hyprctl keyword general:gaps_in "$inner" >/dev/null
hyprctl keyword general:gaps_out "$outer" >/dev/null
hyprctl keyword decoration:rounding "$rounding" >/dev/null
hyprctl keyword decoration:active_opacity "$active" >/dev/null
hyprctl keyword decoration:inactive_opacity "$inactive" >/dev/null
hyprctl keyword decoration:blur:enabled "$blur" >/dev/null
hyprctl keyword decoration:blur:size "$size" >/dev/null
hyprctl keyword decoration:blur:passes "$passes" >/dev/null

config="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/looknfeel.lua"
tmp=$(mktemp "${config}.XXXXXX")
trap 'rm -f "$tmp"' EXIT

awk -v rounding="$rounding" -v active="$active" -v inactive="$inactive" \
  -v blur="$blur" -v size="$size" -v passes="$passes" \
  -v inner="$inner" -v outer="$outer" '
  BEGIN { in_block = 0 }
  /-- BEGIN hypr.looks managed settings/ {
    in_block = 1
    seen = 1
    print "-- BEGIN hypr.looks managed settings"
    print "hl.config({"
    print "  general = { gaps_in = " inner ", gaps_out = " outer " },"
    print "  decoration = {"
    print "    rounding = " rounding ","
    print "    active_opacity = " active ","
    print "    inactive_opacity = " inactive ","
    print "    blur = { enabled = " blur ", size = " size ", passes = " passes " },"
    print "  },"
    print "})"
    next
  }
  /-- END hypr.looks managed settings/ { in_block = 0; print; next }
  !in_block { print }
  END {
    if (!seen) {
      print ""
      print "-- BEGIN hypr.looks managed settings"
      print "hl.config({"
      print "  general = { gaps_in = " inner ", gaps_out = " outer " },"
      print "  decoration = {"
      print "    rounding = " rounding ","
      print "    active_opacity = " active ","
      print "    inactive_opacity = " inactive ","
      print "    blur = { enabled = " blur ", size = " size ", passes = " passes " },"
      print "  },"
      print "})"
      print "-- END hypr.looks managed settings"
    }
  }
' "$config" > "$tmp"
mv "$tmp" "$config"
trap - EXIT
