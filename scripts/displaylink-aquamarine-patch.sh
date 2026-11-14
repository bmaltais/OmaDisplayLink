#!/usr/bin/env bash
# Compatibility stub. Earlier releases installed an Omarchy update hook that runs this script
# (`displaylink-aquamarine-patch.sh --ensure`) and notifies loudly when it is missing. The patch is gone
# (Aquamarine 0.16.0 carries the fix), so for any argument this removes that hook and exits quietly; the
# plugin's status check removes the hook too, but an old hook can fire first. Nothing else calls this.
rm -f "$HOME/.config/omarchy/hooks/post-update.d/displaylink-aquamarine.hook"
exit 0
