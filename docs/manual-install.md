# Manual install (command line)

Most people should use the plugin: see **Install** in the [README](../README.md). Use this page if you do not want the plugin, are on a machine without the Omarchy shell, or want to script it. These are the same scripts the plugin runs, in the same order.

```bash
git clone https://github.com/bmaltais/OmaDisplayLink.git
cd OmaDisplayLink

./scripts/displaylink-detect.sh                   # what does this machine look like?
./scripts/displaylink-prereqs.sh                  # install anything the next steps need (--check only lists)
./scripts/displaylink-install.sh                  # evdi-dkms + displaylink driver
./scripts/displaylink-dryrun.sh --apply-monitors  # optional: preview what configure would change
./scripts/displaylink-configure.sh --apply-monitors
```

**NVIDIA only** (skip on AMD and Intel):

```bash
./scripts/displaylink-aquamarine-patch.sh                # build + install the patched Aquamarine
./scripts/displaylink-aquamarine-patch.sh --install-hook # keep it patched across `omarchy update`
```

Then **log out and back in with the dock attached** (or reboot), and plug it into a USB 3 / SuperSpeed port when you can. Take a snapshot first if you want an easy way back: `omarchy snapshot create`.

## The same thing, guided

`bin/omadisplaylink` runs those scripts as numbered steps with a question before anything changes, and every command has `--preview`, which says what it would do and changes nothing:

```bash
bin/omadisplaylink status     # idle / ok / attention / pending / unconfigured, with a reason
bin/omadisplaylink setup      # install + configure (+ NVIDIA patch and hook), step by step
bin/omadisplaylink reinstall  # rebuild the evdi module and restart the service
bin/omadisplaylink uninstall  # remove DisplayLink and everything setup added
bin/omadisplaylink repair     # fix what status says is wrong (asks first)
bin/omadisplaylink report     # copy a sanitized report to the clipboard
bin/omadisplaylink doctor     # print that report
```

## After a kernel or Omarchy update

```bash
./scripts/displaylink-rebuild.sh                     # rebuild the evdi module for the new kernel
./scripts/displaylink-aquamarine-patch.sh --status   # NVIDIA: prints "patched" or "stock"
```

The update hook (`--install-hook`) re-applies the NVIDIA fix on its own after `omarchy update`.

## Undo

```bash
./scripts/displaylink-uninstall.sh --preview   # what it would do, nothing changed
./scripts/displaylink-uninstall.sh
```

Full explanation, verification steps, troubleshooting and the manual undo: [displaylink.md](displaylink.md).
