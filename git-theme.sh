#!/usr/bin/env bash
# git-theme — Auto-assign terminal + VS Code color palettes per Git repo
# Syncs mapping via ${XDG_DATA_HOME}/git-theme/map (plain text, git-friendly)
#
# Supported: Konsole (native), Alacritty, Kitty, Ptyxis, foot, wezterm, + OSC fallback
# VS Code: auto-updates .vscode/settings.json (excluded from git)
# Source this file in your .bashrc / .zshrc

# Guard against double-sourcing
[[ -n "${_GT_LOADED-}" ]] && return 0
_GT_LOADED=1

# ─── Paths (XDG-compliant) ──────────────────────────────────────────
GIT_THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/git-theme"
GIT_THEME_MAP="$GIT_THEME_DIR/map"
GIT_THEME_CURRENT=""

# ─── Palettes ────────────────────────────────────────────────────────
# Low-fatigue palettes for long coding sessions.
# Format: name|bg|fg|black|red|green|yellow|blue|magenta|cyan|white
#          |bright_black|bright_red|bright_green|bright_yellow|bright_blue|bright_magenta|bright_cyan|bright_white

declare -a GIT_THEME_PALETTES=(
  "mocha|1e1e2e|cdd6f4|45475a|f38ba8|a6e3a1|f9e2af|89b4fa|cba6f7|94e2d5|bac2de|585b70|f38ba8|a6e3a1|f9e2af|89b4fa|cba6f7|94e2d5|a6adc8"
  "macchiato|24273a|cad3f5|494d64|ed8796|a6da95|eed49f|8aadf4|c6a0f6|8bd5ca|b8c0e0|5b6078|ed8796|a6da95|eed49f|8aadf4|c6a0f6|8bd5ca|a5adcb"
  "frappe|303446|c6d0f5|51576d|e78284|a6d189|e5c890|8caaee|ca9ee6|81c8be|b5bfe2|626880|e78284|a6d189|e5c890|8caaee|ca9ee6|81c8be|a5adce"
  "rosepine|191724|e0def4|26233a|eb6f92|31748f|f6c177|9ccfd8|c4a7e7|ebbcba|e0def4|6e6a86|eb6f92|31748f|f6c177|9ccfd8|c4a7e7|ebbcba|e0def4"
  "rosepine-moon|232136|e0def4|2a273f|eb6f92|3e8fb0|f6c177|9ccfd8|c4a7e7|ea9a97|e0def4|6e6a86|eb6f92|3e8fb0|f6c177|9ccfd8|c4a7e7|ea9a97|e0def4"
  "tokyonight|1a1b26|c0caf5|414868|f7768e|9ece6a|e0af68|7aa2f7|bb9af7|7dcfff|a9b1d6|565f89|ff7a93|b9f27c|ff9e64|7da6ff|bb9af7|0db9d7|c0caf5"
  "kanagawa|1f1f28|dcd7ba|2a2a37|c34043|76946a|c0a36e|7e9cd8|957fb8|6a9589|c8c093|625e5a|e82424|98bb6c|e6c384|7fb4ca|a292a3|7aa89f|d5cea3"
  "gruvbox|282828|ebdbb2|3c3836|cc241d|98971a|d79921|458588|b16286|689d6a|a89984|504945|fb4934|b8bb26|fabd2f|83a598|d3869b|8ec07c|bdae93"
  "everforest|2d353b|d3c6aa|475258|e67e80|a7c080|dbbc7f|7fbbb3|d699b6|83c092|9da9a0|374145|e67e80|a7c080|dbbc7f|7fbbb3|d699b6|83c092|bdc3af"
  "nord|2e3440|eceff4|3b4252|bf616a|a3be8c|ebcb8b|81a1c1|b48ead|88c0d0|e5e9f0|4c566a|bf616a|a3be8c|ebcb8b|81a1c1|b48ead|8fbcbb|eceff4"
  "dracula|282a36|f8f8f2|44475a|ff5555|50fa7b|f1fa8c|6272a4|bd93f9|8be9fd|f8f8f2|6272a4|ff6e6e|69ff94|ffffa5|d6acff|ff92df|a4ffff|ffffff"
  "solarized|002b36|839496|073642|dc322f|859900|b58900|268bd2|6c71c4|2aa198|93a1a1|586e75|cb4b16|859900|b58900|268bd2|6c71c4|2aa198|eee8d5"
)

PALETTE_COUNT=${#GIT_THEME_PALETTES[@]}

# ─── Palette field names (parse once, use everywhere) ────────────────
declare -a _GT_FIELDS=(
  name bg fg black red green yellow blue magenta cyan white
  br_black br_red br_green br_yellow br_blue br_magenta br_cyan br_white
)
readonly _GT_FIELD_COUNT=${#_GT_FIELDS[@]}

# Parse palette string into associative array _GT_P[fieldname]=value
declare -A _GT_P
_gt_parse_palette() {
  _GT_P=()
  local IFS='|'
  local -a values
  read -ra values <<< "$1"

  if (( ${#values[@]} != _GT_FIELD_COUNT )); then
    echo "[git-theme] ERROR: palette has ${#values[@]} fields, expected ${_GT_FIELD_COUNT}" >&2
    return 1
  fi

  local i
  for ((i = 0; i < _GT_FIELD_COUNT; i++)); do
    _GT_P[${_GT_FIELDS[$i]}]="${values[$i]}"
  done
}

# ─── Core functions ──────────────────────────────────────────────────

_gt_ensure_dir() {
  [[ -d "$GIT_THEME_DIR" ]] || mkdir -p "$GIT_THEME_DIR"
  [[ -f "$GIT_THEME_MAP" ]] || touch "$GIT_THEME_MAP"
}

_gt_repo_id() {
  local remote
  remote=$(git -C "$1" config --get remote.origin.url 2>/dev/null)
  if [[ -n "$remote" ]]; then
    echo "$remote" | sed -E 's|.*[:/]([^/]+/[^/]+?)(\.git)?$|\1|'
  else
    basename "$1"
  fi
}

_gt_hash_to_index() {
  local hash
  hash=$(echo -n "$1" | md5sum | cut -c1-8)
  echo $(( 16#$hash % PALETTE_COUNT ))
}

# Fix #4: awk for exact matching instead of grep (repo_id may contain regex chars)
_gt_lookup() {
  awk -F'|' -v id="$1" '$1 == id { print $2; exit }' "$GIT_THEME_MAP" 2>/dev/null
}

# Fix #3: sed delimiter '#' to avoid collision with '|' field separator
_gt_save() {
  local repo_id="$1" theme="$2"
  _gt_ensure_dir
  if awk -F'|' -v id="$repo_id" '$1 == id { found=1; exit } END { exit !found }' "$GIT_THEME_MAP" 2>/dev/null; then
    sed -i "\#^${repo_id}|#d" "$GIT_THEME_MAP"
  fi
  echo "${repo_id}|${theme}" >> "$GIT_THEME_MAP"
  sort -o "$GIT_THEME_MAP" "$GIT_THEME_MAP"
}

_gt_get_palette() {
  for p in "${GIT_THEME_PALETTES[@]}"; do
    if [[ "$p" == "${1}|"* ]]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

# ─── Color utilities ────────────────────────────────────────────────

_gt_hex2rgb() {
  printf "%d,%d,%d" "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"
}

_gt_lighten_hex() {
  local hex="$1" factor="${2:-15}"
  local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
  r=$(( r + (255 - r) * factor / 100 ))
  g=$(( g + (255 - g) * factor / 100 ))
  b=$(( b + (255 - b) * factor / 100 ))
  printf "%02x%02x%02x" "$r" "$g" "$b"
}

_gt_darken_hex() {
  local hex="$1" factor="${2:-15}"
  local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
  r=$(( r * (100 - factor) / 100 ))
  g=$(( g * (100 - factor) / 100 ))
  b=$(( b * (100 - factor) / 100 ))
  printf "%02x%02x%02x" "$r" "$g" "$b"
}

# ─── JSON merge utility ─────────────────────────────────────────────

_gt_json_merge_key() {
  local file="$1" key="$2" value_json="$3"

  if command -v jq &>/dev/null; then
    if [[ -f "$file" ]]; then
      local existing
      existing=$(cat "$file")
      echo "$existing" | jq --arg k "$key" --argjson v "$value_json" '.[$k] = $v' > "$file"
    else
      jq -n --arg k "$key" --argjson v "$value_json" '{($k): $v}' > "$file"
    fi
    return
  fi

  if command -v python3 &>/dev/null && [[ -f "$file" ]]; then
    python3 -c "
import json
with open('$file') as f: data = json.load(f)
data['$key'] = json.loads('''$value_json''')
with open('$file', 'w') as f: json.dump(data, f, indent=2)
" 2>/dev/null
    return
  fi

  echo "{\"${key}\": ${value_json}}" > "$file"
}

_gt_json_remove_key() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0

  if command -v jq &>/dev/null; then
    local tmp
    tmp=$(jq --arg k "$key" 'del(.[$k])' "$file")
    echo "$tmp" > "$file"
  elif command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$file') as f: data = json.load(f)
data.pop('$key', None)
with open('$file', 'w') as f: json.dump(data, f, indent=2)
" 2>/dev/null
  fi
}

# ─── Konsole adapter ────────────────────────────────────────────────

_gt_write_konsole_colorscheme() {
  local scheme_dir="$HOME/.local/share/konsole"
  mkdir -p "$scheme_dir"
  local scheme_file="$scheme_dir/git-theme-active.colorscheme"

  cat > "$scheme_file" << EOF
[General]
Description=git-theme (${_GT_P[name]})
Opacity=1
Wallpaper=

[Background]
Color=$(_gt_hex2rgb "${_GT_P[bg]}")
[BackgroundIntense]
Color=$(_gt_hex2rgb "${_GT_P[bg]}")
[BackgroundFaint]
Color=$(_gt_hex2rgb "${_GT_P[bg]}")

[Foreground]
Color=$(_gt_hex2rgb "${_GT_P[fg]}")
[ForegroundIntense]
Color=$(_gt_hex2rgb "${_GT_P[br_white]}")
Bold=true
[ForegroundFaint]
Color=$(_gt_hex2rgb "${_GT_P[br_black]}")

[Color0]
Color=$(_gt_hex2rgb "${_GT_P[black]}")
[Color0Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_black]}")
[Color0Faint]
Color=$(_gt_hex2rgb "${_GT_P[black]}")

[Color1]
Color=$(_gt_hex2rgb "${_GT_P[red]}")
[Color1Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_red]}")
[Color1Faint]
Color=$(_gt_hex2rgb "${_GT_P[red]}")

[Color2]
Color=$(_gt_hex2rgb "${_GT_P[green]}")
[Color2Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_green]}")
[Color2Faint]
Color=$(_gt_hex2rgb "${_GT_P[green]}")

[Color3]
Color=$(_gt_hex2rgb "${_GT_P[yellow]}")
[Color3Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_yellow]}")
[Color3Faint]
Color=$(_gt_hex2rgb "${_GT_P[yellow]}")

[Color4]
Color=$(_gt_hex2rgb "${_GT_P[blue]}")
[Color4Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_blue]}")
[Color4Faint]
Color=$(_gt_hex2rgb "${_GT_P[blue]}")

[Color5]
Color=$(_gt_hex2rgb "${_GT_P[magenta]}")
[Color5Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_magenta]}")
[Color5Faint]
Color=$(_gt_hex2rgb "${_GT_P[magenta]}")

[Color6]
Color=$(_gt_hex2rgb "${_GT_P[cyan]}")
[Color6Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_cyan]}")
[Color6Faint]
Color=$(_gt_hex2rgb "${_GT_P[cyan]}")

[Color7]
Color=$(_gt_hex2rgb "${_GT_P[white]}")
[Color7Intense]
Color=$(_gt_hex2rgb "${_GT_P[br_white]}")
[Color7Faint]
Color=$(_gt_hex2rgb "${_GT_P[white]}")
EOF
}

_gt_reload_konsole() {
  if command -v qdbus &>/dev/null && [[ -n "$KONSOLE_DBUS_SESSION" ]]; then
    qdbus "$KONSOLE_DBUS_SERVICE" "$KONSOLE_DBUS_SESSION" \
      org.kde.konsole.Session.setProfile "git-theme-active" 2>/dev/null
  fi
}

_gt_apply_konsole() {
  _gt_write_konsole_colorscheme
  _gt_reload_konsole
  _gt_send_osc_sequences
}

# ─── OSC escape sequences (universal fallback) ──────────────────────

_gt_send_osc_sequences() {
  printf '\033]11;#%s\033\\' "${_GT_P[bg]}"
  printf '\033]10;#%s\033\\' "${_GT_P[fg]}"

  local -a ansi_order=(
    black red green yellow blue magenta cyan white
    br_black br_red br_green br_yellow br_blue br_magenta br_cyan br_white
  )
  local i=0
  for field in "${ansi_order[@]}"; do
    printf '\033]4;%d;#%s\033\\' "$i" "${_GT_P[$field]}"
    ((i++))
  done
}

# ─── Alacritty adapter ──────────────────────────────────────────────

_gt_apply_alacritty() {
  local conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
  mkdir -p "$conf_dir"

  cat > "$conf_dir/git-theme-colors.toml" << EOF
# Auto-generated by git-theme — palette: ${_GT_P[name]}
[colors.primary]
background = "0x${_GT_P[bg]}"
foreground = "0x${_GT_P[fg]}"
[colors.normal]
black = "0x${_GT_P[black]}"
red = "0x${_GT_P[red]}"
green = "0x${_GT_P[green]}"
yellow = "0x${_GT_P[yellow]}"
blue = "0x${_GT_P[blue]}"
magenta = "0x${_GT_P[magenta]}"
cyan = "0x${_GT_P[cyan]}"
white = "0x${_GT_P[white]}"
[colors.bright]
black = "0x${_GT_P[br_black]}"
red = "0x${_GT_P[br_red]}"
green = "0x${_GT_P[br_green]}"
yellow = "0x${_GT_P[br_yellow]}"
blue = "0x${_GT_P[br_blue]}"
magenta = "0x${_GT_P[br_magenta]}"
cyan = "0x${_GT_P[br_cyan]}"
white = "0x${_GT_P[br_white]}"
EOF
}

# ─── Kitty adapter ──────────────────────────────────────────────────

_gt_apply_kitty() {
  if command -v kitty &>/dev/null && [[ "$TERM" == "xterm-kitty" ]]; then
    kitty @ set-colors \
      background="#${_GT_P[bg]}" foreground="#${_GT_P[fg]}" \
      color0="#${_GT_P[black]}" color1="#${_GT_P[red]}" color2="#${_GT_P[green]}" color3="#${_GT_P[yellow]}" \
      color4="#${_GT_P[blue]}" color5="#${_GT_P[magenta]}" color6="#${_GT_P[cyan]}" color7="#${_GT_P[white]}" \
      color8="#${_GT_P[br_black]}" color9="#${_GT_P[br_red]}" color10="#${_GT_P[br_green]}" color11="#${_GT_P[br_yellow]}" \
      color12="#${_GT_P[br_blue]}" color13="#${_GT_P[br_magenta]}" color14="#${_GT_P[br_cyan]}" color15="#${_GT_P[br_white]}" \
      2>/dev/null
  fi
}

# ─── VS Code adapter ────────────────────────────────────────────────

_gt_build_vscode_json() {
  local bg_light=$(_gt_lighten_hex "${_GT_P[bg]}" 8)
  local bg_lighter=$(_gt_lighten_hex "${_GT_P[bg]}" 15)
  local bg_dark=$(_gt_darken_hex "${_GT_P[bg]}" 10)
  local accent="${_GT_P[blue]}"

  cat << ENDJSON
{
  "titleBar.activeBackground": "#${bg_dark}",
  "titleBar.activeForeground": "#${_GT_P[fg]}",
  "titleBar.inactiveBackground": "#${bg_dark}",
  "titleBar.inactiveForeground": "#${_GT_P[br_black]}",
  "activityBar.background": "#${bg_dark}",
  "activityBar.foreground": "#${_GT_P[fg]}",
  "activityBar.activeBorder": "#${accent}",
  "activityBarBadge.background": "#${accent}",
  "statusBar.background": "#${bg_dark}",
  "statusBar.foreground": "#${_GT_P[fg]}",
  "statusBar.debuggingBackground": "#${_GT_P[red]}",
  "statusBar.noFolderBackground": "#${bg_dark}",
  "sideBar.background": "#${bg_light}",
  "sideBar.foreground": "#${_GT_P[fg]}",
  "sideBarSectionHeader.background": "#${bg_lighter}",
  "tab.activeBackground": "#${_GT_P[bg]}",
  "tab.inactiveBackground": "#${bg_light}",
  "tab.activeBorderTop": "#${accent}",
  "editorGroupHeader.tabsBackground": "#${bg_dark}",
  "panel.background": "#${_GT_P[bg]}",
  "panel.border": "#${bg_lighter}",
  "terminal.background": "#${_GT_P[bg]}",
  "terminal.foreground": "#${_GT_P[fg]}",
  "terminal.ansiBlack": "#${_GT_P[black]}",
  "terminal.ansiRed": "#${_GT_P[red]}",
  "terminal.ansiGreen": "#${_GT_P[green]}",
  "terminal.ansiYellow": "#${_GT_P[yellow]}",
  "terminal.ansiBlue": "#${_GT_P[blue]}",
  "terminal.ansiMagenta": "#${_GT_P[magenta]}",
  "terminal.ansiCyan": "#${_GT_P[cyan]}",
  "terminal.ansiWhite": "#${_GT_P[white]}",
  "terminal.ansiBrightBlack": "#${_GT_P[br_black]}",
  "terminal.ansiBrightRed": "#${_GT_P[br_red]}",
  "terminal.ansiBrightGreen": "#${_GT_P[br_green]}",
  "terminal.ansiBrightYellow": "#${_GT_P[br_yellow]}",
  "terminal.ansiBrightBlue": "#${_GT_P[br_blue]}",
  "terminal.ansiBrightMagenta": "#${_GT_P[br_magenta]}",
  "terminal.ansiBrightCyan": "#${_GT_P[br_cyan]}",
  "terminal.ansiBrightWhite": "#${_GT_P[br_white]}"
}
ENDJSON
}

_gt_exclude_from_git() {
  local exclude_file="$1/.git/info/exclude"
  if [[ -f "$exclude_file" ]] && ! grep -qF ".vscode/settings.json" "$exclude_file" 2>/dev/null; then
    echo ".vscode/settings.json" >> "$exclude_file"
  fi
}

_gt_apply_vscode() {
  local git_root="$1"
  [[ -z "$git_root" ]] && return 0

  local settings_file="$git_root/.vscode/settings.json"
  mkdir -p "$git_root/.vscode"

  local color_json
  color_json=$(_gt_build_vscode_json)

  _gt_json_merge_key "$settings_file" "workbench.colorCustomizations" "$color_json"
  _gt_exclude_from_git "$git_root"
}

_gt_clean_vscode() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$git_root" ]] && [[ -f "$git_root/.vscode/settings.json" ]]; then
    _gt_json_remove_key "$git_root/.vscode/settings.json" "workbench.colorCustomizations"
  fi
}

# ─── Terminal detection and dispatch ─────────────────────────────────
# Fix #5: detect Ptyxis, foot, wezterm — all route to OSC

_gt_detect_terminal() {
  # Ptyxis (GNOME terminal on Fedora 42+) — VTE-based, full OSC support
  if [[ -n "${PTYXIS_PID-}" ]]; then
    echo "osc"; return
  fi
  # foot (Wayland terminal)
  if [[ "$TERM" == "foot" || "$TERM" == "foot-extra" ]]; then
    echo "osc"; return
  fi
  # wezterm
  if [[ -n "${WEZTERM_EXECUTABLE-}" ]]; then
    echo "osc"; return
  fi
  # Konsole
  if [[ -n "$KONSOLE_DBUS_SESSION" ]] || [[ -n "$KONSOLE_VERSION" ]]; then
    echo "konsole"; return
  fi
  # Kitty
  if [[ "$TERM" == "xterm-kitty" ]]; then
    echo "kitty"; return
  fi
  # Alacritty
  if [[ -n "$ALACRITTY_SOCKET" ]] || [[ -n "$ALACRITTY_LOG" ]]; then
    echo "alacritty"; return
  fi
  # Fallback: OSC works on most modern terminals
  echo "osc"
}

_gt_apply_terminal() {
  case "$(_gt_detect_terminal)" in
    konsole)   _gt_apply_konsole ;;
    kitty)     _gt_apply_kitty ;;
    alacritty) _gt_apply_alacritty; _gt_send_osc_sequences ;;
    *)         _gt_send_osc_sequences ;;
  esac
}

# ─── Main entry point ───────────────────────────────────────────────

_gt_apply() {
  local palette_data="$1"
  local git_root="$2"

  _gt_parse_palette "$palette_data" || return 1

  [[ -n "$git_root" ]] && _gt_apply_vscode "$git_root"
  _gt_apply_terminal
}

# ─── Theme update (called by hook) ──────────────────────────────────

_gt_update_theme() {
  _gt_ensure_dir

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0

  local repo_id
  repo_id=$(_gt_repo_id "$git_root")
  [[ -z "$repo_id" ]] && return 0

  [[ "$repo_id" == "$GIT_THEME_CURRENT" ]] && return 0
  GIT_THEME_CURRENT="$repo_id"

  local theme
  theme=$(_gt_lookup "$repo_id")

  if [[ -z "$theme" ]]; then
    local idx
    idx=$(_gt_hash_to_index "$repo_id")
    theme=$(echo "${GIT_THEME_PALETTES[$idx]}" | cut -d'|' -f1)
    _gt_save "$repo_id" "$theme"
    echo -e "\033[2m[git-theme] New repo → ${theme}\033[0m"
  fi

  local palette_data
  palette_data=$(_gt_get_palette "$theme") || return 0
  _gt_apply "$palette_data" "$git_root"
}

# ─── User commands ───────────────────────────────────────────────────

git-theme() {
  case "${1:-}" in
    ls|list)
      echo "Available palettes:"
      for raw in "${GIT_THEME_PALETTES[@]}"; do
        _gt_parse_palette "$raw" || continue
        printf "  \033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm %-18s \033[0m\n" \
          "0x${_GT_P[bg]:0:2}" "0x${_GT_P[bg]:2:2}" "0x${_GT_P[bg]:4:2}" \
          "0x${_GT_P[fg]:0:2}" "0x${_GT_P[fg]:2:2}" "0x${_GT_P[fg]:4:2}" \
          "${_GT_P[name]}"
      done
      ;;

    set)
      [[ -z "${2:-}" ]] && echo "Usage: git-theme set <palette>" && return 1
      local git_root
      git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [[ -z "$git_root" ]] && echo "Not in a git repo" && return 1
      _gt_get_palette "$2" >/dev/null || { echo "Unknown: $2. Run 'git-theme ls'"; return 1; }
      local repo_id
      repo_id=$(_gt_repo_id "$git_root")
      _gt_save "$repo_id" "$2"
      GIT_THEME_CURRENT=""
      _gt_update_theme
      echo "Set $repo_id → $2"
      ;;

    current)
      local git_root
      git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [[ -z "$git_root" ]] && echo "Not in a git repo" && return 1
      local repo_id
      repo_id=$(_gt_repo_id "$git_root")
      local theme
      theme=$(_gt_lookup "$repo_id")
      if [[ -n "$theme" ]]; then
        echo "$repo_id → $theme"
      else
        echo "$repo_id → (no theme assigned)"
      fi
      ;;

    map)
      [[ -s "$GIT_THEME_MAP" ]] && column -t -s'|' < "$GIT_THEME_MAP" || echo "No mappings yet."
      ;;

    reset)
      local git_root
      git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [[ -z "$git_root" ]] && echo "Not in a git repo" && return 1
      local repo_id
      repo_id=$(_gt_repo_id "$git_root")
      sed -i "\#^${repo_id}|#d" "$GIT_THEME_MAP" 2>/dev/null
      GIT_THEME_CURRENT=""
      echo "Reset theme for $repo_id"
      ;;

    preview)
      echo "Previewing all palettes (3s each)..."
      for raw in "${GIT_THEME_PALETTES[@]}"; do
        _gt_parse_palette "$raw" || continue
        echo -e "\n─── ${_GT_P[name]} ───"
        _gt_apply_terminal
        sleep 3
      done
      echo -e "\nDone. 'git-theme set <name>' to pick."
      ;;

    off)
      printf '\033[0m\033]110\033\\\033]111\033\\'
      for i in $(seq 0 15); do printf '\033]104;%d\033\\' "$i"; done
      _gt_clean_vscode
      GIT_THEME_CURRENT=""
      echo "Colors reset."
      ;;

    *)
      cat << 'USAGE'
git-theme — auto-assign terminal + VS Code palettes per git repo

Commands:
  ls|list      Show available palettes with color preview
  set <name>   Assign a palette to the current repo
  current      Show the theme for the current repo
  map          Show all repo → palette assignments
  reset        Remove assignment for current repo
  preview      Cycle through all palettes (3s each)
  off          Reset terminal + VS Code to default colors

Terminal: Konsole, Alacritty, Kitty, Ptyxis, foot, wezterm, + any OSC-compatible
VS Code:  auto-updates .vscode/settings.json (excluded from git)
Sync:     ~/.local/share/git-theme/map → add to your dotfiles
USAGE
      ;;
  esac
}

# ─── Shell hooks ─────────────────────────────────────────────────────
# Fix #1: starship_precmd_user_func instead of cd override
# Fix #2: _GT_LAST_PWD cache to skip when PWD hasn't changed

_GT_LAST_PWD=""

_gt_prompt_hook() {
  [[ "$PWD" == "$_GT_LAST_PWD" ]] && return
  _GT_LAST_PWD="$PWD"
  # Chain to previous precmd user func if one existed
  [[ -n "${_GT_PREV_PRECMD_FUNC-}" ]] && "$_GT_PREV_PRECMD_FUNC"
  _gt_update_theme
}

if [[ -n "${ZSH_VERSION-}" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _gt_update_theme
elif [[ -n "${BASH_VERSION-}" ]]; then
  # Prefer starship_precmd_user_func if Starship is active
  if [[ "$(type -t starship_precmd 2>/dev/null)" == "function" ]] || [[ "${STARSHIP_SHELL-}" == "bash" ]]; then
    # Chain with any existing precmd user function
    if [[ -n "${starship_precmd_user_func-}" && "$starship_precmd_user_func" != "_gt_prompt_hook" ]]; then
      _GT_PREV_PRECMD_FUNC="$starship_precmd_user_func"
    fi
    starship_precmd_user_func="_gt_prompt_hook"
  else
    # Fallback: append to PROMPT_COMMAND array
    PROMPT_COMMAND+=("_gt_prompt_hook")
  fi
fi

# Apply on source if already in a repo
_gt_update_theme
