#!/usr/bin/env bash
# Make sure everything the other scripts lean on is installed, so a fresh Omarchy needs nothing by hand.
#
# Usage: displaylink-prereqs.sh [--build] [--check]
#   --build   only what building the patched Aquamarine needs
#   --check   list what is missing and change nothing (exit 1 if anything is)
#
# Omarchy's own package list already has base-devel, git, jq, gum, wl-clipboard and dkms; they are listed
# here anyway so this does not depend on that staying true.
set -euo pipefail

BUILD=(base-devel git curl python libarchive cmake hyprwayland-scanner)
HELPERS=(dkms usbutils jq gum wl-clipboard)

pkgs=("${BUILD[@]}")
check=0
build_only=0
for arg in "$@"; do
  case "$arg" in
    --build) build_only=1 ;;
    --check) check=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
((build_only)) || pkgs+=("${HELPERS[@]}")

# pacman -T prints the ones that are not satisfied.
mapfile -t missing < <(pacman -T "${pkgs[@]}" || true)

if ((${#missing[@]} == 0)); then
  echo "All prerequisites are installed."
  exit 0
fi

echo "Missing: ${missing[*]}"
((check)) && exit 1
omarchy pkg add "${missing[@]}"
