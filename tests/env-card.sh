#!/usr/bin/env bash
# Tests the no-symlink fallback in config/displaylink/env-hyprland.example against a fake /dev/dri
# and /sys/class/drm tree: the block's absolute paths are rewritten to a temp root, then run with sh.
# The layouts are real ones (or the shapes of them); no hardware is touched.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
example=$repo/config/displaylink/env-hyprland.example
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

fresh() { root=$work/root; rm -rf "$root"; mkdir -p "$root/dev/dri"; }

# card NAME SUBSYSTEM DRIVER: one fake DRM card with its bus subsystem and driver.
card() {
  local name=$1 subsystem=$2 driver=$3
  mkdir -p "$root/sys/bus/$subsystem" "$root/sys/bus/$driver" "$root/sys/class/drm/$name/device"
  ln -s "$root/sys/bus/$subsystem" "$root/sys/class/drm/$name/device/subsystem"
  ln -s "$root/sys/bus/$driver" "$root/sys/class/drm/$name/device/driver"
  touch "$root/dev/dri/$name"
}

# run_block: print the block's AQ_DRM_DEVICES and AQ_FORCE_LINEAR_BLIT, paths made relative to the root.
run_block() {
  local sh=$work/block.sh
  sed -e "s#/dev/dri#$root/dev/dri#g" -e "s#/sys/class/drm#$root/sys/class/drm#g" "$example" >"$sh"
  # shellcheck disable=SC2016 # the line is meant to be expanded later, by the block's shell
  echo 'echo "${AQ_DRM_DEVICES:-unset} ${AQ_FORCE_LINEAR_BLIT:-unset}"' >>"$sh"
  env -u AQ_DRM_DEVICES -u AQ_FORCE_LINEAR_BLIT -u AQ_MGPU_NO_EXPLICIT sh "$sh" | sed "s#$root/dev/dri/##g"
}

expect() {
  local got
  got=$(run_block)
  if [[ $got == "$2" ]]; then echo "ok    $1"; else echo "FAIL  $1: wanted '$2', got '$got'"; fails=1; fi
}

fresh # MacBook M1 (Asahi): Touch Bar, render-only GPU and display card are all platform devices
card card0 platform evdi; card card1 platform apple-dcp; card card2 platform asahi; card card3 platform apple-drm
expect "Asahi: no PCI card, variable stays unset" "unset unset"

fresh # x86, symlink missing: first PCI non-evdi card, evdi appended
card card0 platform evdi; card card1 pci amdgpu
touch "$root/dev/dri/evdi0"
expect "x86 without symlink: PCI card then evdi0" "card1:evdi0 unset"

fresh # an evdi card is never primary
card card0 platform evdi
expect "only evdi: unset" "unset unset"

fresh # symlink wins over the scan
card card0 pci i915; card card1 pci amdgpu; touch "$root/dev/dri/amd-gpu"
expect "symlink present: used as is" "amd-gpu unset"

fresh # NVIDIA symlink: the workarounds are set
mkdir -p "$root/sys/bus/nvidia" "$root/sys/class/drm/card0/device"
ln -s "$root/sys/bus/nvidia" "$root/sys/class/drm/card0/device/driver"
touch "$root/dev/dri/card0"; ln -s "$root/dev/dri/card0" "$root/dev/dri/nvidia-gpu"
expect "NVIDIA symlink: linear blit workaround set" "nvidia-gpu 0"

exit "$fails"
