# Hyprland Looks

An Omarchy top-bar widget for adjusting Hyprland window appearance live.

## Features

- Active and inactive window opacity
- Corner rounding
- Blur toggle, size, and passes
- Inner and outer gaps
- Four presets: Custom, Minimal, Balanced, and Glass
- Editable and persistent named presets
- Changes apply immediately and survive Hyprland reloads and reboots

## Install

```bash
omarchy plugin add https://github.com/akash-kamat/hyprland-looks.git --enable
```

The plugin is installed under `~/.config/omarchy/plugins/hypr.looks/` and is
added to the bar automatically by its manifest.

## Use

Click the droplet icon on the top bar. Select a preset or use the sliders.
Choose a named preset, adjust its values, then use the save button to update
that preset. Custom values are saved automatically.

The widget applies runtime values with `hyprctl` and maintains its settings in
the user-owned `~/.config/hypr/looknfeel.lua` file. Preset definitions are
stored in the plugin's `presets.json`.

## Uninstall

```bash
omarchy plugin remove hypr.looks --yes
```

The plugin does not modify `/usr/share/omarchy/`; it only manages files in the
user's configuration directory.

## Development

Validate the plugin with:

```bash
omarchy plugin validate .
```

## License

MIT. See [LICENSE](LICENSE).
