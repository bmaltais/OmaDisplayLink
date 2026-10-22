# OmaDisplayLink card: UI standards

The shared rules are the Start apps' [ui-standards](https://github.com/bmaltais/omarchy-plugin-devkit/blob/main/docs/ui-standards.md): follow the theme, say what will happen, quiet by default, one accent-filled thing per screen. This file is what is specific to the card, and its decision log.

## The card

A `PopupCard` anchored to the bar icon (`BarWidget.qml`), top to bottom:

1. **Status band.** The plugin's "D" mark, the title, the state in small capitals (`WORKING`, `NEEDS ATTENTION`, `NOT INSTALLED`, `LOG OUT TO FINISH`, `NO DOCK PLUGGED IN`) and one plain sentence, on a band tinted with the state colour (accent when working or finishing, the theme's urgent colour when something is wrong, none otherwise) with a matching hairline. It answers "is it fine?" before anything is read.
2. **The one thing to do.** At most one accent-filled button with an icon (`PrimaryAction.qml`), and under it a caption saying what pressing it does. The state picks it: set up, log out, reinstall, repair. When nothing needs doing there is none.
3. **Quiet actions.** Copy report and Guide, side by side, no fill (`QuietButton.qml`). Their longer explanation is the tooltip.
4. **Maintenance.** Hidden until something is installed. A hairline, a small-caps label, and Reinstall and Uninstall as small quiet buttons at the right. Uninstall turns red only on hover. Reinstall is dropped from here when it is already the main action.

Colours, fonts, radii and spacing come from the shell; nothing is hard-coded. The label on the filled button is the theme's dark or light colour, whichever reads better on the accent.

## Decision log

- **One filled button, picked by state** (instead of four equal buttons). With every action the same weight a first-time user could not tell what to do first; guidance in the shell's own standards and in common button-hierarchy guidance is one primary, outlined or text secondaries, and destructive actions apart and quiet.
- **Reinstall and Uninstall in a footer** (instead of in the main list). They are maintenance, not the next step, and Uninstall must never be the loudest thing. The terminal flow still shows a summary and asks before it changes anything.
- **Hints as tooltips for quiet actions, visible for the primary.** The primary's caption is the one a person reads before clicking; the others are secondary and their flows explain themselves in the terminal.
- **A tinted status band** (instead of text colour alone). The tint is readable without reading, and works for people who do not distinguish the state colours, because the state word is always written out.
