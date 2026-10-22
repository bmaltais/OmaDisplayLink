# OmaDisplayLink

**Use a DisplayLink USB dock or hub (Plugable, StarTech, Dell, Lenovo, and others) as extra monitors on [Omarchy](https://omarchy.org/): Arch Linux + Hyprland, including NVIDIA and Wayland.**

If your DisplayLink screens show **no signal**, stay at **0x0**, or Hyprland logs `drmPrimeFDToHandle failed` / `Buffer failed to import to KMS`, this project is for you.

> **Status: experimental.** Verified end to end on one machine (see [Tested hardware](#tested-hardware)). AMD and Intel should need less and are expected to work, but nobody has run them yet. Reports from other setups are welcome.
>
> This is an independent community project. It is not affiliated with or endorsed by Omarchy, Hyprland, Synaptics/DisplayLink, or any dock vendor.

## What you get

DisplayLink docks are not ordinary USB-C or DisplayPort docks. They send video over USB and need the **evdi** kernel module plus the proprietary **DisplayLink** userspace driver, and Hyprland has to be told how to use the resulting virtual screens. This repo automates that on Omarchy:

- Detects your GPU, dock, kernel headers and Hyprland state (`displaylink-detect.sh`, with a `--sanitize` mode for pasting into issues).
- Installs `evdi-dkms` and `displaylink` through Omarchy's package helpers (`displaylink-install.sh`).
- Configures stable device names (`/dev/dri/evdi0`, `/dev/dri/nvidia-gpu`), early loading of evdi, the `AQ_DRM_DEVICES` environment Hyprland needs before it starts, and, optionally, `hl.monitor` entries for the new screens (`displaylink-configure.sh`).
- **On NVIDIA**, builds and installs a patched Aquamarine (Hyprland's backend library) that adds the CPU-copy fallback from [hyprwm/aquamarine#279](https://github.com/hyprwm/aquamarine/pull/279), because stock Aquamarine cannot drive evdi outputs on NVIDIA. A post-update hook rebuilds it automatically when `omarchy update` replaces Aquamarine.
- Measures what the DisplayLink path costs (`displaylink-benchmark.sh`) and previews every change safely first (`displaylink-dryrun.sh`).

Everything is a plain shell script you can read, and every change has a documented undo.

## Quick start

```bash
git clone https://github.com/bmaltais/OmaDisplayLink.git
cd OmaDisplayLink

./scripts/displaylink-detect.sh                   # what does this machine look like?
./scripts/displaylink-install.sh                  # evdi-dkms + displaylink driver
./scripts/displaylink-dryrun.sh --apply-monitors  # optional: preview what configure would change
./scripts/displaylink-configure.sh --apply-monitors
```

**NVIDIA only** (skip on AMD and Intel):

```bash
./scripts/displaylink-aquamarine-patch.sh               # build + install the patched Aquamarine
./scripts/displaylink-aquamarine-patch.sh --install-hook # keep it patched across `omarchy update`
```

Then **reboot with the dock attached** (or log out and back in), and plug it into a USB 3 / SuperSpeed port when you can. Take a snapshot first if you want an easy way back: `omarchy snapshot create`.

Full explanation, verification steps and undo: [docs/displaylink.md](docs/displaylink.md).

## Omarchy plugin (in development)

The repo root is also an Omarchy shell plugin (`manifest.json`, `Service.qml`, `BarWidget.qml`, `bin/omadisplaylink`). It adds a bar icon (a "D" with a pixel inside it that lights up while a dock is working) and a standard Omarchy card: one sentence about the dock, then only the actions that apply, each with a line saying what it will do. Anything that needs your password opens in a visible terminal and asks first. The scripts above stay the real engine and keep working without it.

```bash
omarchy plugin add https://github.com/bmaltais/OmaDisplayLink.git --enable
```

Not published to the marketplace yet. The bar icon has been exercised in the devkit's nested test session (all four states and the card, in demo mode), not yet on a real shell with a real dock. The command line side works today:

```bash
bin/omadisplaylink status     # idle / ok / attention / unconfigured, with a reason
bin/omadisplaylink setup      # guided install + configure (+ NVIDIA patch and hook)
bin/omadisplaylink repair     # fix what status says is wrong (asks first)
bin/omadisplaylink report     # copy a sanitized report to the clipboard
bin/omadisplaylink doctor     # print that report
```

### Developing the plugin

Clone with `--recurse-submodules` (the test kit is `scripts/devkit`; users who install the plugin do not get it). `scripts/check.sh` runs shellcheck, qmllint and the manifest check. `scripts/dev up` starts a second desktop that your mouse and keyboard cannot reach, running this checkout in demo mode, so nothing real is installed or changed. `scripts/dev state unconfigured|idle|ok|attention` changes what it reports, `scripts/dev shot FILE` takes a screenshot, `scripts/dev reload` loads an edit, `scripts/dev down` ends it.

## Tested hardware

| | |
|---|---|
| Dock | Plugable UD-3900PDZ (triple HDMI, two DisplayLink heads) |
| GPU | NVIDIA RTX 3090 (nvidia-open) |
| Software | Omarchy, Hyprland 0.56.2, Aquamarine 0.15.1, evdi 1.15.1, `displaylink` 6.4 |
| Link | USB 2 (480M) |
| Result | Two dock screens plus a native screen, replug and mode changes work |

Cost on that machine: about 1.4% of one core for Hyprland when idle, and 73–82% in a deliberately harsh worst case (a 900x600 terminal printing continuously while jumping across the screens). See [Measure the cost](docs/displaylink.md#measure-the-cost). Others in the Aquamarine PR thread report it working on an RTX 5070 and an RTX 2080 Ti with an Elgato Prompter.

Have a different dock or GPU? Run `./scripts/displaylink-detect.sh --sanitize` and open an issue with the result and whether it worked.

## Symptoms this fixes

Search-engine-friendly list of what people actually see:

- DisplayLink monitor **shows no signal / black screen** on Hyprland or Omarchy
- `hyprctl monitors` lists `DVI-I-1` / `DVI-I-2` but at **0x0** or disabled
- `drm: drmPrimeFDToHandle failed`, `Buffer failed to import to KMS`
- DisplayLink works on Windows but not on Omarchy / Arch Linux / Wayland
- evdi on **NVIDIA with Wayland** produces no output (works on X11 or on AMD/Intel)
- Screens vanish after `omarchy update` (a new Aquamarine dropped the patch): the update hook handles this
- `AQ_NO_MODIFIERS=1` "fixes" the dock but greys out your main monitors (not needed here; the patch is the real fix)

Also check your monitor's input source before debugging further: a healthy dock output can look like "no signal" if the monitor is set to another input.

## How it works

1. **evdi** creates virtual DRM cards that the DisplayLink service feeds with frames over USB.
2. **udev rules** give those cards and your real GPU stable names so `AQ_DRM_DEVICES` never points at the wrong device.
3. **Hyprland** (through Aquamarine) renders on the real GPU and hands finished frames to evdi. On AMD and Intel that import works. On NVIDIA the driver refuses to share its buffers with evdi, so the patched Aquamarine reads the frame back and copies it into a plain buffer instead. That costs CPU, which is why heavy motion is the expensive case.

## Update safety

- `displaylink-aquamarine-patch.sh --status` prints `patched` or `stock`.
- The hook runs after every `omarchy update`: it does nothing unless Hyprland renders on NVIDIA and the library lost the fix, then rebuilds, verifies the build really carries the fix, installs it, and notifies you. If the patch stops applying, you get a notification and the system package is left alone.
- After a kernel update: `./scripts/displaylink-rebuild.sh`.
- Once upstream merges the fix and Arch ships it, remove the hook and use the stock package (steps in the guide).

## Uninstall

Every script documents its undo in [docs/displaylink.md](docs/displaylink.md#undo). The patched package is replaced by the stock one with `sudo pacman -S aquamarine`, and `displaylink-aquamarine-patch.sh --remove-hook` removes the update hook.

## Contributing

Reports, hardware results and pull requests are welcome. Keep everything public-safe: no hostnames, serials, MAC addresses, home paths or unsanitized `hyprctl` output. See [AGENTS.md](AGENTS.md).

## Credits

The CPU-copy fallback is based on the work of the author of [hyprwm/aquamarine#279](https://github.com/hyprwm/aquamarine/pull/279), adapted here to Aquamarine 0.15.1. Thanks to the Hyprland, Aquamarine, evdi and Omarchy projects.

## Keywords

DisplayLink Omarchy, DisplayLink Hyprland, DisplayLink Arch Linux, DisplayLink Wayland, DisplayLink NVIDIA Linux, evdi Hyprland, evdi NVIDIA Wayland, USB graphics adapter Linux, Plugable UD-3900PDZ Linux, triple monitor USB dock Linux, Aquamarine evdi.

## License

[MIT](LICENSE). The bundled Aquamarine patch is a derivative of Aquamarine (BSD-3-Clause); the `displaylink` driver is proprietary and installed from the AUR under its own license.
