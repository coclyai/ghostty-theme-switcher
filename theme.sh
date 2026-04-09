#!/bin/bash

# Ghostty theme switcher - select light/dark themes interactively

if ! command -v fzf &>/dev/null; then
  echo "Error: fzf is required but not installed." >&2
  echo "Install via Homebrew: brew install fzf" >&2
  echo "Other installation methods: https://github.com/junegunn/fzf" >&2
  exit 1
fi

config_file="$HOME/.config/ghostty/config"

# Light themes
light_themes=(
  "3024 Day"
  "Adwaita"
  "Alabaster"
  "Apple System Colors Light"
  "Atom One Light"
  "Belafonte Day"
  "Breadog"
  "Dayfox"
  "Farmhouse Light"
  "Gruvbox Light Hard"
  "iTerm2 Solarized Light"
  "Modus Operandi Tinted"
  "Monokai Pro Light"
  "Monokai Pro Light Sun"
  "Neobones Light"
  "One Double Light"
  "One Half Light"
  "Primary"
  "Pro Light"
  "Raycast Light"
  "Tomorrow"
  "Xcode Light hc"
  "Zenbones Light"
  "Zenwritten Light"
)

# Dark themes
dark_themes=(
  "Apple System Colors"
  "Arthur"
  "Atom"
  "Atom One Dark"
  "Cursor Dark"
  "Cutie Pro"
  "Darkside"
  "Farmhouse Dark"
  "Gruber Darker"
  "Guezwhoz"
  "Neobones Dark"
  "Spacegray Eighties Dull"
  "Square"
  "Teerb"
  "Tomorrow Night"
  "Vague"
  "Xcode Dark hc"
  "Zenbones Dark"
)

# Parse the current active theme from config
get_current_theme() {
  local mode="$1" # light or dark
  local theme_value
  theme_value=$(grep "^theme = " "$config_file" | sed 's/^theme = //')
  if echo "$theme_value" | grep -q "light:"; then
    if [ "$mode" = "light" ]; then
      echo "$theme_value" | sed 's/.*light:\([^,]*\),.*/\1/'
    else
      echo "$theme_value" | sed 's/.*dark:\(.*\)/\1/'
    fi
  else
    echo "$theme_value"
  fi
}

# --- Subcommands: called by fzf reload/execute-silent ---

# Generate theme list with ✓ marker on active theme
cmd_list() {
  local mode="$1"
  local current
  current=$(get_current_theme "$mode")
  local themes_var="${mode}_themes[@]"
  local sorted
  sorted=$(printf '%s\n' "${!themes_var}" | sort -u)
  while IFS= read -r t; do
    if [ "$t" = "$current" ]; then
      echo "✓ $t"
    else
      echo "  $t"
    fi
  done <<< "$sorted"
}

# Apply selected theme to config
cmd_apply() {
  local mode="$1"   # light or dark
  local style="$2"  # auto or fixed
  local selected="$3"
  local theme
  theme=$(echo "$selected" | sed 's/^. //')
  if [ "$style" = "fixed" ]; then
    sed "s|^theme = .*|theme = ${theme}|" "$config_file" > "${config_file}.tmp"
  else
    local theme_value current_light current_dark
    theme_value=$(grep "^theme = " "$config_file" | sed 's/^theme = //')
    if echo "$theme_value" | grep -q "light:"; then
      current_light=$(echo "$theme_value" | sed 's/.*light:\([^,]*\),.*/\1/')
      current_dark=$(echo "$theme_value" | sed 's/.*dark:\(.*\)/\1/')
    else
      current_light="$theme_value"
      current_dark="$theme_value"
    fi
    if [ "$mode" = "light" ]; then
      sed "s|^theme = .*|theme = light:${theme},dark:${current_dark}|" "$config_file" > "${config_file}.tmp"
    else
      sed "s|^theme = .*|theme = light:${current_light},dark:${theme}|" "$config_file" > "${config_file}.tmp"
    fi
  fi
  mv "${config_file}.tmp" "$config_file"
}

# Apply theme and return fzf actions (reload + pos to keep cursor)
cmd_right() {
  local mode="$1" style="$2" selected="$3" pos="$4"
  cmd_apply "$mode" "$style" "$selected"
  echo "reload(bash $0 _list $mode)+pos($((pos + 1)))"
}

# Dispatch subcommands and exit
case "${1:-}" in
  _list)  shift; cmd_list "$@"; exit ;;
  _apply) shift; cmd_apply "$@"; exit ;;
  _right) shift; cmd_right "$@"; exit ;;
esac

# --- Main flow ---

self="$0"

detect_system_theme() {
  if defaults read -g AppleInterfaceStyle &>/dev/null; then
    echo "Dark"
  else
    echo "Light"
  fi
}

show_main_menu() {
  local sys_theme
  sys_theme=$(detect_system_theme)
  echo -e "Follow Operating System (Current: $sys_theme)\nLight Theme\nDark Theme" | fzf \
    --height=15% \
    --border \
    --border-label=" THEME SETTINGS " \
    --pointer="▶" \
    --no-sort \
    --no-info \
    --no-input \
    --layout=reverse \
    --cycle \
    --highlight-line \
    --header="← exit | → enter" \
    --bind "left:abort" \
    --bind "right:accept"
}

# Theme selector (mode: light|dark, style: auto|fixed)
select_theme() {
  local mode="$1"
  local style="$2"
  local label
  if [ "$mode" = "light" ]; then
    label=" SELECT LIGHT THEME "
  else
    label=" SELECT DARK THEME "
  fi

  # Find line number of active theme for initial cursor position
  local list_output current_pos
  list_output=$(bash "$self" _list "$mode")
  current_pos=$(echo "$list_output" | grep -n "^✓" | cut -d: -f1)
  current_pos=${current_pos:-1}

  local selected
  selected=$(echo "$list_output" | fzf \
    --ansi \
    --height=50% \
    --border \
    --border-label="$label" \
    --pointer="▶" \
    --no-sort \
    --no-info \
    --no-input \
    --layout=reverse \
    --cycle \
    --highlight-line \
    --color="current-bg:237" \
    --header="↑↓ select | → apply | ← back | Enter apply & exit" \
    --sync \
    --bind "start:pos($current_pos)" \
    --bind "left:abort" \
    --bind "right:transform(bash $self _right $mode $style {} {n})" \
    --bind "enter:execute-silent(bash $self _apply $mode $style {})+accept")
  local ret=$?
  if [ $ret -eq 0 ] && [ -n "$selected" ]; then
    local theme_name
    theme_name=$(echo "$selected" | sed 's/^. //')
    if [ "$mode" = "light" ]; then
      printf "Light Theme:\t%s\n" "$theme_name" >&2
    else
      printf "Dark Theme:\t%s\n" "$theme_name" >&2
    fi
  fi
  return $ret
}

# Main loop
while true; do
  operation=$(show_main_menu)

  if [ -z "$operation" ]; then
    exit 0
  fi

  case "$operation" in
    Follow\ Operating\ System*)
      # Select both light and dark themes
      select_theme light auto
      [ $? -ne 0 ] && continue
      select_theme dark auto
      [ $? -eq 0 ] && break
      continue
      ;;

    "Light Theme")
      select_theme light fixed
      [ $? -eq 0 ] && break
      ;;

    "Dark Theme")
      select_theme dark fixed
      [ $? -eq 0 ] && break
      ;;
  esac
done

echo "" >&2
echo "🔄 Press ⌘ + Shift + , to apply changes in Ghostty" >&2
