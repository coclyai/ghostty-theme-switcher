# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the script

```bash
bash theme.sh
```

Requires `fzf` (`brew install fzf`) and Ghostty installed with a config at `~/.config/ghostty/config`.

## Architecture

The entire tool is a single Bash script (`theme.sh`) using a **self-invoking subcommand pattern**. fzf `--bind` actions call back into the same script with internal subcommands:

- `_list <mode>` — prints the theme list for `light` or `dark` with a `✓` marker on the active theme
- `_apply <mode> <style> <selected>` — writes the selected theme to `~/.config/ghostty/config`
- `_right <mode> <style> <selected> <pos>` — applies theme and returns fzf reload+pos actions for live preview

The `case` block near line 133 dispatches these subcommands and exits early. Everything below it is the main interactive flow.

### Config format

The script edits the `theme = ...` line in the Ghostty config (matched by `^theme = ` pattern, not by line number):
- Fixed theme: `theme = ThemeName`
- OS-adaptive: `theme = light:LightTheme,dark:DarkTheme`

`sed` rewrites the matching line in-place via a `.tmp` file.

### Theme lists

`light_themes` and `dark_themes` are curated arrays in the script. Any theme from `ghostty +list-themes` can be added.
