# ghostty-theme-switcher

An interactive fzf-based theme switcher for the [Ghostty](https://ghostty.org) terminal emulator.

Ghostty supports live config reload and a `light:X,dark:Y` syntax for automatic light/dark theme switching. This script fills the gap that the built-in `ghostty +list-themes` preview leaves: it lets you interactively pick themes and **writes the selection to your config**.

![demo](demo.gif)

## Features

- Main menu: choose between Follow OS / Light Theme / Dark Theme
- **Follow OS** — select separate light and dark themes; writes `theme = light:X,dark:Y`
- **Light / Dark** — select a single fixed theme; writes `theme = X`
- Live preview: press `→` to apply a theme without leaving the menu
- Current active theme is marked with `✓`
- Ghostty live-reloads on config save (no restart needed)

## Requirements

- [Ghostty](https://ghostty.org)
- [fzf](https://github.com/junegunn/fzf) — `brew install fzf`

## Installation

```bash
git clone https://github.com/coclyai/ghostty-theme-switcher.git
```

Optionally add an alias to your shell config (adjust the path to where you cloned the repo):

```bash
alias theme="bash /path/to/ghostty-theme-switcher/theme.sh"
```

## Usage

```bash
bash theme.sh
```

### Key bindings

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate |
| `→` | Enter submenu / live-apply theme |
| `←` | Go back / exit |
| `Enter` | Apply theme and exit |

## How it works

The script uses a **self-invoking subcommand** pattern (`_list`, `_apply`, `_right`) dispatched via a `case` block. fzf `--bind` actions call back into the same script with these subcommands — no temp files needed.

## Theme list

The bundled theme lists (`light_themes` / `dark_themes`) are a curated selection. You can edit `theme.sh` to add or remove themes — any theme available via `ghostty +list-themes` is valid.

## License

MIT
