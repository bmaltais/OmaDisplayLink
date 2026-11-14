#!/usr/bin/env bash
# Questions about the GPU and the Aquamarine version, for the plugin and the setup flow.
#
# Usage: displaylink-gpu.sh <mode>
#   --nvidia   exit 0 if Hyprland renders on NVIDIA
#   --stale    exit 0 if DisplayLink is installed, Hyprland renders on NVIDIA and Aquamarine is older
#              than 0.16.0 (the first release that can drive evdi outputs on NVIDIA) and lacks the fix
#   --version  print the installed Aquamarine version
#   --mirror-behind
#              exit 0 if the synced package database (pacman -Si, read-only, no network) still lists an
#              Aquamarine older than 0.16.0, so `omarchy update` would not bring the fix yet
set -euo pipefail

# hyprwm/aquamarine#279 (CPU-copy fallback for evdi) shipped in 0.16.0.
MIN_AQUAMARINE=0.16.0

# Where /proc, /sys and /usr/lib are read from; only tests/gpu.sh sets this, to a fake tree.
ROOT="${DISPLAYLINK_TEST_ROOT:-}"

# Kernel driver of the GPU Hyprland renders on: the first AQ_DRM_DEVICES entry of the running compositor.
# Prints nothing when that cannot be read (no session, or AQ_DRM_DEVICES unset).
primary_gpu_driver() {
  local pid dev card
  pid="$(pidof Hyprland | awk '{print $1}')"
  [[ -n "$pid" && -r "$ROOT/proc/$pid/environ" ]] || return 0
  dev="$(tr '\0' '\n' <"$ROOT/proc/$pid/environ" | sed -n 's/^AQ_DRM_DEVICES=//p' | cut -d: -f1)"
  [[ -n "$dev" ]] || return 0
  card="$(basename "$(readlink -f "$dev")")"
  basename "$(readlink -f "$ROOT/sys/class/drm/$card/device/driver")" 2>/dev/null || true
}

# On a hybrid laptop that renders on the integrated GPU nvidia_drm is loaded too, so it is only a
# fallback for when the primary is unknown.
renders_on_nvidia() {
  local driver
  driver="$(primary_gpu_driver)"
  if [[ -n "$driver" ]]; then
    [[ "$driver" == nvidia ]]
  else
    [[ -d "$ROOT/sys/module/nvidia_drm" ]]
  fi
}

# "0.16.0-1" -> "0.16.0"
aquamarine_version() { pacman -Q aquamarine 2>/dev/null | awk '{sub(/-[^-]*$/, "", $2); print $2}' || true; }

# The Aquamarine version in the sync database, as of the last `pacman -Sy` (empty when there is none).
synced_version() { pacman -Si aquamarine 2>/dev/null | awk '/^Version/ {sub(/-[^-]*$/, "", $3); print $3; exit}' || true; }

# Logged by Aquamarine's evdi CPU-copy path, in the stock 0.16.0 and in the build earlier releases carried.
has_cpu_copy() { grep -aqs -- 'dumb-buffer CPU copy' "$ROOT/usr/lib/libaquamarine.so"; }

case "${1:-}" in
  --nvidia) renders_on_nvidia ;;
  --version) aquamarine_version ;;
  --mirror-behind)
    ver="$(synced_version)"
    [[ -n "$ver" ]] && (($(vercmp "$ver" "$MIN_AQUAMARINE") < 0))
    ;;
  --stale)
    pacman -Q displaylink >/dev/null 2>&1 || exit 1
    renders_on_nvidia || exit 1
    ver="$(aquamarine_version)"
    [[ -n "$ver" ]] || exit 1
    # An older build that carries the fix (the patched one earlier releases installed) works.
    has_cpu_copy && exit 1
    (($(vercmp "$ver" "$MIN_AQUAMARINE") < 0))
    ;;
  *) echo "Usage: displaylink-gpu.sh --nvidia | --stale | --mirror-behind | --version" >&2; exit 2 ;;
esac
