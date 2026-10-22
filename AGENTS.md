# Agent instructions for OmaDisplayLink

This repository makes DisplayLink USB docks work on [Omarchy](https://omarchy.org/) (Arch + Hyprland). It is **public**: treat every file as if a stranger will clone it.

Live files under `~/.config/` and `/etc/` are applied copies. Templates under `config/displaylink/` are generic, and scripts under `scripts/` bind them to the current machine.

## Layout

```
docs/displaylink.md        # the full guide (detect, install, configure, verify, undo)
config/displaylink/        # generic templates and the Aquamarine patch
scripts/displaylink-*.sh   # detect / install / configure / patch / rebuild / uninstall / benchmark / dryrun
scripts/steps.sh           # numbered-step output shared by setup, reinstall and uninstall (PREVIEW=1 changes nothing)
scripts/lib.sh             # shared helpers
```

## Privacy: never commit personal data

No names, emails, usernames, hostnames, machine IDs, home paths (`/home/<user>/...`), MAC or IP addresses, Wi-Fi names, monitor serials or EDIDs, unsanitized `hyprctl` output, keys or tokens, or screenshots showing personal windows.

Safe: product names (for example "Plugable UD-3900PDZ"), device-class vendor IDs (`17e9` = DisplayLink), placeholders (`DVI-I-1`, `0000:XX:XX.X`), and scripts that detect machine-specific values and write them to the live system. Sanitize output with `scripts/displaylink-detect.sh --sanitize`.

## Rules for changes

- Prefer `omarchy pkg add` and `omarchy pkg aur add` over raw `pacman` / `yay`.
- Hyprland variables needed before the compositor starts (`AQ_*`) go in `~/.config/uwsm/env-hyprland`, not only `hl.env()`.
- System files (`/etc/modprobe.d`, `/etc/udev/rules.d`, systemd drop-ins) are installed by scripts with `sudo` in a visible terminal. `~/StartFS`-style FUSE checkouts cannot be read by root, so scripts stage files through `/tmp` (see `install_file` in `scripts/lib.sh`).
- Back up before editing Hyprland config; validate with `hyprctl reload` and `hyprctl configerrors` (`Hyprland --verify-config` can crash even on a valid config).
- Never install a rebuilt Aquamarine that does not carry the fix; the patch script verifies the built library before installing.
- Update `docs/displaylink.md` and the README in the same change as any behavior change.
- Comments explain non-obvious constraints, not the author's machine.
