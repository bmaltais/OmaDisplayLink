#!/usr/bin/env bash
# Undo displaylink-install.sh, displaylink-configure.sh and displaylink-aquamarine-patch.sh.
#
# Usage: displaylink-uninstall.sh [--preview]
#   --preview   say what each step would do and change nothing
#
# Your monitors.lua is not touched: layout lines belong to you (or to a monitor tool).
# Testing override: OMADL_ETC (default /etc).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
# shellcheck source=steps.sh
source "$SCRIPT_DIR/steps.sh"

ETC="${OMADL_ETC:-/etc}"
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/env-hyprland"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/OmaDisplayLink"
PATCH="$SCRIPT_DIR/displaylink-aquamarine-patch.sh"

case "${1:-}" in
  --preview) PREVIEW=1 ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

remove_env_block() {
  [[ -f $ENV_FILE ]] || return 0
  grep -qE 'BEGIN (OmaDisplayLink|omarchy-setup displaylink)' "$ENV_FILE" || return 0
  cp "$ENV_FILE" "$ENV_FILE.bak.$(date +%s)"
  python3 - "$ENV_FILE" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
for name in ("OmaDisplayLink", "omarchy-setup displaylink"):
    start, end = f"# BEGIN {name}", f"# END {name}"
    i, j = text.find(start), text.find(end)
    if i != -1 and j != -1:
        text = (text[:i].rstrip("\n") + "\n" + text[j + len(end):].lstrip("\n")).lstrip("\n")
        break
path.write_text(text)
PY
}

patched_aquamarine() { [[ $("$PATCH" --status 2>/dev/null || true) == patched ]]; }

cat <<'TXT'
OmaDisplayLink uninstall

This will, in order:
  - stop the DisplayLink service and remove its systemd drop-in
  - remove the evdi module settings and the stable GPU names (udev rule)
  - remove the OmaDisplayLink block from your Hyprland environment file (a backup is kept)
  - remove the update hook
  - put Arch's stock Aquamarine back, if the patched one is installed
  - remove the displaylink and evdi-dkms packages

Your monitor layout (monitors.lua) is left alone. DisplayLink screens go dark as soon as the
driver is removed, and the change is complete after you log out and back in.
TXT
echo
if ! ask "Remove DisplayLink from this machine?"; then
  echo "Cancelled. Nothing was changed."
  exit 130
fi
((PREVIEW)) || need_sudo

TOTAL=6
patched_aquamarine && TOTAL=7
steps_begin "$TOTAL"

step "Snapshot" "A system snapshot lets you roll back if something goes wrong."
if ((PREVIEW)); then
  step_would "offer to run: omarchy snapshot create"
elif gum confirm "Take a system snapshot first? (recommended)"; then
  omarchy snapshot create || step_skip "snapshot failed; continuing"
else
  step_skip "skipped"
fi

step "Stop the service" "Stops displaylink.service and removes the early-start drop-in."
run_step "stop and disable displaylink.service" sudo systemctl disable --now displaylink.service || step_skip "the service was not there"
run_step "remove the systemd drop-in" sudo rm -rf "$ETC/systemd/system/displaylink.service.d" || stop_flow
run_step "reload systemd" sudo systemctl daemon-reload || stop_flow

step "Remove the setup files" "Removes the evdi module settings and the stable GPU names."
run_step "remove modprobe, modules-load and udev files" \
  sudo rm -f "$ETC/modprobe.d/evdi.conf" "$ETC/modules-load.d/evdi.conf" "$ETC/udev/rules.d/99-drm-stable-names.rules" || stop_flow
run_step "reload udev rules" sudo udevadm control --reload || stop_flow

step "Hyprland environment" "Removes the OmaDisplayLink block from $ENV_FILE and keeps a backup."
run_step "remove the block" remove_env_block || stop_flow

step "Update hook" "Removes the hook that kept the NVIDIA fix across updates."
run_step "remove the hook" "$PATCH" --remove-hook || stop_flow

if patched_aquamarine; then
  step "Stock Aquamarine" "Puts Arch's own Aquamarine back, replacing the patched build."
  run_step "reinstall the stock package" sudo pacman -S --noconfirm aquamarine || stop_flow
fi

step "Remove the packages" "Removes displaylink and evdi-dkms (the evdi kernel module stays loaded until you reboot)."
run_step "remove displaylink and evdi-dkms" omarchy pkg drop displaylink evdi-dkms || stop_flow

echo
if ((PREVIEW)); then
  echo "Preview only: nothing was changed."
else
  rm -rf "$STATE_DIR"
  echo "Done. Your monitors.lua still lists the dock screens; remove those lines if you do not want them."
  echo "Log out and back in to finish."
fi
