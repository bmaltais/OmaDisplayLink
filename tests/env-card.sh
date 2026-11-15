#!/usr/bin/env bash
# Tests the primary-card fallback in config/displaylink/env-hyprland.example against a fake /dev/dri
# and /sys/class/drm tree: the block's absolute paths are rewritten to a temp root, then run with sh.
# The layouts are the real ones people reported; no hardware is touched.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
example=$repo/config/displaylink/env-hyprland.example
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

# card NAME DRIVER [CONNECTOR...]: one fake DRM card with its driver and connector entries.
card() {
  local name=$1 driver=$2; shift 2
  mkdir -p "$root/sys/bus/$driver" "$root/sys/class/drm/$name/device"
  ln -s "$root/sys/bus/$driver" "$root/sys/class/drm/$name/device/driver"
  touch "$root/dev/dri/$name"
  local c
  for c in "$@"; do mkdir -p "$root/sys/class/drm/$name-$c"; done
}

# expect LABEL WANT_FIRST_CARD: run the block and compare the first AQ_DRM_DEVICES entry.
expect() {
  local sh=$work/block.sh
  sed -e "s#/dev/dri#$root/dev/dri#g" -e "s#/sys/class/drm#$root/sys/class/drm#g" "$example" >"$sh"
  # shellcheck disable=SC2016 # the line is meant to be expanded later, by the block's shell
  echo 'echo "${AQ_DRM_DEVICES:-unset}"' >>"$sh"
  local got
  got=$(sh "$sh" | cut -d: -f1 | sed "s#^$root/dev/dri/##")
  if [[ $got == "$2" ]]; then echo "ok    $1"; else echo "FAIL  $1: wanted $2, got $got"; fails=1; fi
}

fresh() { root=$work/root; rm -rf "$root"; mkdir -p "$root/dev/dri"; }

fresh # MacBook M1 (Asahi): Touch Bar on card1 (DSI), render-only GPU on card2, panel on card3
card card0 evdi DVI-I-1; card card1 apple-dcp DSI-1; card card2 asahi; card card3 apple-drm DP-1 DP-2 eDP-1
expect "Asahi: the eDP card wins over the Touch Bar DSI card" card3

fresh # Asahi layout seen first: render-only GPU before the display card
card card0 asahi; card card1 apple-drm eDP-1
expect "Asahi: render-only GPU skipped" card1

fresh # ordinary single-GPU laptop
card card0 i915 eDP-1 HDMI-A-1
expect "plain laptop: first card" card0

fresh # an evdi card is never primary
card card0 evdi DVI-I-1; card card1 amdgpu DP-1
expect "evdi skipped" card1

fresh # only DSI connectors (a DSI-only device): still better than nothing
card card0 evdi DVI-I-1; card card1 vc4 DSI-1
expect "DSI-only: falls back to the DSI card" card1

fresh # nothing probed yet: first non-evdi card
card card0 evdi; card card1 amdgpu
expect "no connectors yet: first non-evdi card" card1

exit "$fails"
