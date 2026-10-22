# Developing the plugin

Clone with `--recurse-submodules` (the test kit is `scripts/devkit`; people who install the plugin do not get it).

- `scripts/check.sh` runs shellcheck, qmllint and the manifest check.
- `scripts/dev up` starts a second desktop that your mouse and keyboard cannot reach, running this checkout in **demo mode**: a marker file in its sandbox home makes `bin/omadisplaylink` report a fixed state, and setup, reinstall and uninstall ask their real questions but only simulate the steps, so nothing is installed or changed.
- `scripts/dev state unconfigured|pending|idle|ok|attention [setup|relogin|reinstall|patch|service]` changes what the demo reports. `scripts/dev click X Y`, `scripts/dev key NAME`, `scripts/dev shot FILE` drive and photograph it; `scripts/dev reload` loads an edit; `scripts/dev down` ends it.
- The screenshots in `docs/images` were taken this way. The card's design decisions are in [ui-standards.md](ui-standards.md).
