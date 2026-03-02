#!/bin/sh
# git-theme — Auto-assign terminal + VS Code color palettes per Git repo
# Compatible with: sh, dash, bash, zsh, ksh
# Source this file in your .bashrc / .zshrc / .profile

# Guard against double-sourcing
[ -n "${_GT_LOADED-}" ] && return 0
_GT_LOADED=1

# ─── Paths (XDG-compliant) ──────────────────────────────────────────
GIT_THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/git-theme"
GIT_THEME_MAP="$GIT_THEME_DIR/map"
GIT_THEME_CURRENT=""

# ─── Palettes ────────────────────────────────────────────────────────
# Format: name|bg|fg|black|red|green|yellow|blue|magenta|cyan|white
#          |br_black|br_red|br_green|br_yellow|br_blue|br_magenta|br_cyan|br_white
GIT_THEME_PALETTES="mocha|1e1e2e|cdd6f4|45475a|f38ba8|a6e3a1|f9e2af|89b4fa|cba6f7|94e2d5|bac2de|585b70|f38ba8|a6e3a1|f9e2af|89b4fa|cba6f7|94e2d5|a6adc8
macchiato|24273a|cad3f5|494d64|ed8796|a6da95|eed49f|8aadf4|c6a0f6|8bd5ca|b8c0e0|5b6078|ed8796|a6da95|eed49f|8aadf4|c6a0f6|8bd5ca|a5adcb
frappe|303446|c6d0f5|51576d|e78284|a6d189|e5c890|8caaee|ca9ee6|81c8be|b5bfe2|626880|e78284|a6d189|e5c890|8caaee|ca9ee6|81c8be|a5adce
rosepine|191724|e0def4|26233a|eb6f92|31748f|f6c177|9ccfd8|c4a7e7|ebbcba|e0def4|6e6a86|eb6f92|31748f|f6c177|9ccfd8|c4a7e7|ebbcba|e0def4
rosepine-moon|232136|e0def4|2a273f|eb6f92|3e8fb0|f6c177|9ccfd8|c4a7e7|ea9a97|e0def4|6e6a86|eb6f92|3e8fb0|f6c177|9ccfd8|c4a7e7|ea9a97|e0def4
tokyonight|1a1b26|c0caf5|414868|f7768e|9ece6a|e0af68|7aa2f7|bb9af7|7dcfff|a9b1d6|565f89|ff7a93|b9f27c|ff9e64|7da6ff|bb9af7|0db9d7|c0caf5
kanagawa|1f1f28|dcd7ba|2a2a37|c34043|76946a|c0a36e|7e9cd8|957fb8|6a9589|c8c093|625e5a|e82424|98bb6c|e6c384|7fb4ca|a292a3|7aa89f|d5cea3
gruvbox|282828|ebdbb2|3c3836|cc241d|98971a|d79921|458588|b16286|689d6a|a89984|504945|fb4934|b8bb26|fabd2f|83a598|d3869b|8ec07c|bdae93
everforest|2d353b|d3c6aa|475258|e67e80|a7c080|dbbc7f|7fbbb3|d699b6|83c092|9da9a0|374145|e67e80|a7c080|dbbc7f|7fbbb3|d699b6|83c092|bdc3af
nord|2e3440|eceff4|3b4252|bf616a|a3be8c|ebcb8b|81a1c1|b48ead|88c0d0|e5e9f0|4c566a|bf616a|a3be8c|ebcb8b|81a1c1|b48ead|8fbcbb|eceff4
dracula|282a36|f8f8f2|44475a|ff5555|50fa7b|f1fa8c|6272a4|bd93f9|8be9fd|f8f8f2|6272a4|ff6e6e|69ff94|ffffa5|d6acff|ff92df|a4ffff|ffffff
solarized|002b36|839496|073642|dc322f|859900|b58900|268bd2|6c71c4|2aa198|93a1a1|586e75|cb4b16|859900|b58900|268bd2|6c71c4|2aa198|eee8d5"

PALETTE_COUNT=12

# ─── Parsed palette fields (set by _gt_parse_palette) ────────────────
_GT_P_name="" _GT_P_bg="" _GT_P_fg=""
_GT_P_black="" _GT_P_red="" _GT_P_green="" _GT_P_yellow=""
_GT_P_blue="" _GT_P_magenta="" _GT_P_cyan="" _GT_P_white=""
_GT_P_br_black="" _GT_P_br_red="" _GT_P_br_green="" _GT_P_br_yellow=""
_GT_P_br_blue="" _GT_P_br_magenta="" _GT_P_br_cyan="" _GT_P_br_white=""

# ─── Palette parsing ─────────────────────────────────────────────────

_gt_parse_palette() {
  local _old_ifs="$IFS"
  IFS='|'
  # Intentional word-splitting on IFS; palette data contains no globs
  set -f
  # zsh doesn't word-split by default; enable it for this function only
  if [ -n "${ZSH_VERSION-}" ]; then
    setopt localoptions shwordsplit
  fi
  # shellcheck disable=SC2086
  set -- $1
  set +f
  IFS="$_old_ifs"

  if [ $# -ne 19 ]; then
    printf '[git-theme] ERROR: palette has %d fields, expected 19\n' "$#" >&2
    return 1
  fi

  _GT_P_name="$1"; _GT_P_bg="$2"; _GT_P_fg="$3"
  _GT_P_black="$4"; _GT_P_red="$5"; _GT_P_green="$6"; _GT_P_yellow="$7"
  _GT_P_blue="$8"; _GT_P_magenta="$9"
  shift 9
  _GT_P_cyan="$1"; _GT_P_white="$2"
  _GT_P_br_black="$3"; _GT_P_br_red="$4"; _GT_P_br_green="$5"; _GT_P_br_yellow="$6"
  _GT_P_br_blue="$7"; _GT_P_br_magenta="$8"; _GT_P_br_cyan="$9"
  shift 9
  _GT_P_br_white="$1"
}

# ─── Hex utilities ───────────────────────────────────────────────────

_gt_hex2rgb() {
  local _rr _gg _bb
  _rr=$(printf '%s' "$1" | cut -c1-2)
  _gg=$(printf '%s' "$1" | cut -c3-4)
  _bb=$(printf '%s' "$1" | cut -c5-6)
  printf '%d,%d,%d' "0x$_rr" "0x$_gg" "0x$_bb"
}

_gt_lighten_hex() {
  local _hex="$1" _factor="${2:-15}" _rr _gg _bb _r _g _b
  _rr=$(printf '%s' "$_hex" | cut -c1-2)
  _gg=$(printf '%s' "$_hex" | cut -c3-4)
  _bb=$(printf '%s' "$_hex" | cut -c5-6)
  _r=$(printf '%d' "0x$_rr")
  _g=$(printf '%d' "0x$_gg")
  _b=$(printf '%d' "0x$_bb")
  _r=$(( _r + (255 - _r) * _factor / 100 ))
  _g=$(( _g + (255 - _g) * _factor / 100 ))
  _b=$(( _b + (255 - _b) * _factor / 100 ))
  printf '%02x%02x%02x' "$_r" "$_g" "$_b"
}

_gt_darken_hex() {
  local _hex="$1" _factor="${2:-15}" _rr _gg _bb _r _g _b
  _rr=$(printf '%s' "$_hex" | cut -c1-2)
  _gg=$(printf '%s' "$_hex" | cut -c3-4)
  _bb=$(printf '%s' "$_hex" | cut -c5-6)
  _r=$(printf '%d' "0x$_rr")
  _g=$(printf '%d' "0x$_gg")
  _b=$(printf '%d' "0x$_bb")
  _r=$(( _r * (100 - _factor) / 100 ))
  _g=$(( _g * (100 - _factor) / 100 ))
  _b=$(( _b * (100 - _factor) / 100 ))
  printf '%02x%02x%02x' "$_r" "$_g" "$_b"
}

# ─── Core functions ──────────────────────────────────────────────────

_gt_ensure_dir() {
  [ -d "$GIT_THEME_DIR" ] || mkdir -p "$GIT_THEME_DIR"
  [ -f "$GIT_THEME_MAP" ] || touch "$GIT_THEME_MAP"
}

_gt_repo_id() {
  local _remote
  _remote=$(git -C "$1" config --get remote.origin.url 2>/dev/null)
  if [ -n "$_remote" ]; then
    # POSIX BRE: extract user/repo, then strip .git suffix
    printf '%s\n' "$_remote" | sed 's|.*[:/]\([^/][^/]*/[^/][^/]*\)$|\1|; s|\.git$||'
  else
    basename "$1"
  fi
}

_gt_hash_to_index() {
  local _hash
  if command -v md5sum >/dev/null 2>&1; then
    _hash=$(printf '%s' "$1" | md5sum | cut -c1-7)
  elif command -v md5 >/dev/null 2>&1; then
    _hash=$(printf '%s' "$1" | md5 | cut -c1-7)
  else
    # Fallback: cksum
    _hash=$(printf '%s' "$1" | cksum | cut -d' ' -f1)
    echo $(( _hash % PALETTE_COUNT ))
    return
  fi
  echo $(( 0x$_hash % PALETTE_COUNT ))
}

_gt_lookup() {
  awk -F'|' -v id="$1" '$1 == id { print $2; exit }' "$GIT_THEME_MAP" 2>/dev/null
}

_gt_save() {
  local _repo_id="$1" _theme="$2"
  _gt_ensure_dir
  if awk -F'|' -v id="$_repo_id" '$1 == id { found=1; exit } END { exit !found }' "$GIT_THEME_MAP" 2>/dev/null; then
    awk -F'|' -v id="$_repo_id" '$1 != id' "$GIT_THEME_MAP" > "${GIT_THEME_MAP}.tmp" && mv "${GIT_THEME_MAP}.tmp" "$GIT_THEME_MAP"
  fi
  printf '%s|%s\n' "$_repo_id" "$_theme" >> "$GIT_THEME_MAP"
  sort -o "$GIT_THEME_MAP" "$GIT_THEME_MAP"
}

_gt_get_palette() {
  local _line
  _line=$(printf '%s\n' "$GIT_THEME_PALETTES" | grep "^${1}|" | head -n 1)
  if [ -n "$_line" ]; then
    printf '%s\n' "$_line"
    return 0
  fi
  return 1
}

# ─── JSON merge utility ─────────────────────────────────────────────

_gt_json_merge_key() {
  local _file="$1" _key="$2" _value_json="$3"

  if command -v jq >/dev/null 2>&1; then
    if [ -f "$_file" ]; then
      local _existing
      _existing=$(cat "$_file")
      printf '%s' "$_existing" | jq --arg k "$_key" --argjson v "$_value_json" '.[$k] = $v' > "$_file"
    else
      jq -n --arg k "$_key" --argjson v "$_value_json" '{($k): $v}' > "$_file"
    fi
    return
  fi

  if command -v python3 >/dev/null 2>&1 && [ -f "$_file" ]; then
    python3 -c "
import json
with open('$_file') as f: data = json.load(f)
data['$_key'] = json.loads('''$_value_json''')
with open('$_file', 'w') as f: json.dump(data, f, indent=2)
" 2>/dev/null
    return
  fi

  printf '{"%s": %s}\n' "$_key" "$_value_json" > "$_file"
}

_gt_json_remove_key() {
  local _file="$1" _key="$2"
  [ -f "$_file" ] || return 0

  if command -v jq >/dev/null 2>&1; then
    local _tmp
    _tmp=$(jq --arg k "$_key" 'del(.[$k])' "$_file")
    printf '%s\n' "$_tmp" > "$_file"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
with open('$_file') as f: data = json.load(f)
data.pop('$_key', None)
with open('$_file', 'w') as f: json.dump(data, f, indent=2)
" 2>/dev/null
  fi
}

# ─── Konsole adapter ────────────────────────────────────────────────

_gt_write_konsole_colorscheme() {
  local _scheme_dir="$HOME/.local/share/konsole"
  mkdir -p "$_scheme_dir"
  local _scheme_file="$_scheme_dir/git-theme-active.colorscheme"

  cat > "$_scheme_file" <<EOF
[General]
Description=git-theme ($_GT_P_name)
Opacity=1
Wallpaper=

[Background]
Color=$(_gt_hex2rgb "$_GT_P_bg")
[BackgroundIntense]
Color=$(_gt_hex2rgb "$_GT_P_bg")
[BackgroundFaint]
Color=$(_gt_hex2rgb "$_GT_P_bg")

[Foreground]
Color=$(_gt_hex2rgb "$_GT_P_fg")
[ForegroundIntense]
Color=$(_gt_hex2rgb "$_GT_P_br_white")
Bold=true
[ForegroundFaint]
Color=$(_gt_hex2rgb "$_GT_P_br_black")

[Color0]
Color=$(_gt_hex2rgb "$_GT_P_black")
[Color0Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_black")
[Color0Faint]
Color=$(_gt_hex2rgb "$_GT_P_black")

[Color1]
Color=$(_gt_hex2rgb "$_GT_P_red")
[Color1Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_red")
[Color1Faint]
Color=$(_gt_hex2rgb "$_GT_P_red")

[Color2]
Color=$(_gt_hex2rgb "$_GT_P_green")
[Color2Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_green")
[Color2Faint]
Color=$(_gt_hex2rgb "$_GT_P_green")

[Color3]
Color=$(_gt_hex2rgb "$_GT_P_yellow")
[Color3Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_yellow")
[Color3Faint]
Color=$(_gt_hex2rgb "$_GT_P_yellow")

[Color4]
Color=$(_gt_hex2rgb "$_GT_P_blue")
[Color4Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_blue")
[Color4Faint]
Color=$(_gt_hex2rgb "$_GT_P_blue")

[Color5]
Color=$(_gt_hex2rgb "$_GT_P_magenta")
[Color5Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_magenta")
[Color5Faint]
Color=$(_gt_hex2rgb "$_GT_P_magenta")

[Color6]
Color=$(_gt_hex2rgb "$_GT_P_cyan")
[Color6Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_cyan")
[Color6Faint]
Color=$(_gt_hex2rgb "$_GT_P_cyan")

[Color7]
Color=$(_gt_hex2rgb "$_GT_P_white")
[Color7Intense]
Color=$(_gt_hex2rgb "$_GT_P_br_white")
[Color7Faint]
Color=$(_gt_hex2rgb "$_GT_P_white")
EOF
}

_gt_reload_konsole() {
  if command -v qdbus >/dev/null 2>&1 && [ -n "$KONSOLE_DBUS_SESSION" ]; then
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
  printf '\033]11;#%s\033\\' "$_GT_P_bg"
  printf '\033]10;#%s\033\\' "$_GT_P_fg"
  printf '\033]4;0;#%s\033\\' "$_GT_P_black"
  printf '\033]4;1;#%s\033\\' "$_GT_P_red"
  printf '\033]4;2;#%s\033\\' "$_GT_P_green"
  printf '\033]4;3;#%s\033\\' "$_GT_P_yellow"
  printf '\033]4;4;#%s\033\\' "$_GT_P_blue"
  printf '\033]4;5;#%s\033\\' "$_GT_P_magenta"
  printf '\033]4;6;#%s\033\\' "$_GT_P_cyan"
  printf '\033]4;7;#%s\033\\' "$_GT_P_white"
  printf '\033]4;8;#%s\033\\' "$_GT_P_br_black"
  printf '\033]4;9;#%s\033\\' "$_GT_P_br_red"
  printf '\033]4;10;#%s\033\\' "$_GT_P_br_green"
  printf '\033]4;11;#%s\033\\' "$_GT_P_br_yellow"
  printf '\033]4;12;#%s\033\\' "$_GT_P_br_blue"
  printf '\033]4;13;#%s\033\\' "$_GT_P_br_magenta"
  printf '\033]4;14;#%s\033\\' "$_GT_P_br_cyan"
  printf '\033]4;15;#%s\033\\' "$_GT_P_br_white"
}

# ─── iTerm2 adapter ──────────────────────────────────────────────────

_gt_apply_iterm2() {
  printf '\033]1337;SetColors=bg=%s\007' "$_GT_P_bg"
  printf '\033]1337;SetColors=fg=%s\007' "$_GT_P_fg"
  printf '\033]1337;SetColors=black=%s\007' "$_GT_P_black"
  printf '\033]1337;SetColors=red=%s\007' "$_GT_P_red"
  printf '\033]1337;SetColors=green=%s\007' "$_GT_P_green"
  printf '\033]1337;SetColors=yellow=%s\007' "$_GT_P_yellow"
  printf '\033]1337;SetColors=blue=%s\007' "$_GT_P_blue"
  printf '\033]1337;SetColors=magenta=%s\007' "$_GT_P_magenta"
  printf '\033]1337;SetColors=cyan=%s\007' "$_GT_P_cyan"
  printf '\033]1337;SetColors=white=%s\007' "$_GT_P_white"
  printf '\033]1337;SetColors=br_black=%s\007' "$_GT_P_br_black"
  printf '\033]1337;SetColors=br_red=%s\007' "$_GT_P_br_red"
  printf '\033]1337;SetColors=br_green=%s\007' "$_GT_P_br_green"
  printf '\033]1337;SetColors=br_yellow=%s\007' "$_GT_P_br_yellow"
  printf '\033]1337;SetColors=br_blue=%s\007' "$_GT_P_br_blue"
  printf '\033]1337;SetColors=br_magenta=%s\007' "$_GT_P_br_magenta"
  printf '\033]1337;SetColors=br_cyan=%s\007' "$_GT_P_br_cyan"
  printf '\033]1337;SetColors=br_white=%s\007' "$_GT_P_br_white"
}

# ─── Alacritty adapter ──────────────────────────────────────────────

_gt_apply_alacritty() {
  local _conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
  mkdir -p "$_conf_dir"

  cat > "$_conf_dir/git-theme-colors.toml" <<EOF
# Auto-generated by git-theme — palette: $_GT_P_name
[colors.primary]
background = "0x$_GT_P_bg"
foreground = "0x$_GT_P_fg"
[colors.normal]
black = "0x$_GT_P_black"
red = "0x$_GT_P_red"
green = "0x$_GT_P_green"
yellow = "0x$_GT_P_yellow"
blue = "0x$_GT_P_blue"
magenta = "0x$_GT_P_magenta"
cyan = "0x$_GT_P_cyan"
white = "0x$_GT_P_white"
[colors.bright]
black = "0x$_GT_P_br_black"
red = "0x$_GT_P_br_red"
green = "0x$_GT_P_br_green"
yellow = "0x$_GT_P_br_yellow"
blue = "0x$_GT_P_br_blue"
magenta = "0x$_GT_P_br_magenta"
cyan = "0x$_GT_P_br_cyan"
white = "0x$_GT_P_br_white"
EOF
}

# ─── Kitty adapter ──────────────────────────────────────────────────

_gt_apply_kitty() {
  if command -v kitty >/dev/null 2>&1 && [ "$TERM" = "xterm-kitty" ]; then
    kitty @ set-colors \
      background="#$_GT_P_bg" foreground="#$_GT_P_fg" \
      color0="#$_GT_P_black" color1="#$_GT_P_red" color2="#$_GT_P_green" color3="#$_GT_P_yellow" \
      color4="#$_GT_P_blue" color5="#$_GT_P_magenta" color6="#$_GT_P_cyan" color7="#$_GT_P_white" \
      color8="#$_GT_P_br_black" color9="#$_GT_P_br_red" color10="#$_GT_P_br_green" color11="#$_GT_P_br_yellow" \
      color12="#$_GT_P_br_blue" color13="#$_GT_P_br_magenta" color14="#$_GT_P_br_cyan" color15="#$_GT_P_br_white" \
      2>/dev/null
  fi
}

# ─── VS Code adapter ────────────────────────────────────────────────

_gt_build_vscode_json() {
  local _bg_light _bg_lighter _bg_dark _accent
  _bg_light=$(_gt_lighten_hex "$_GT_P_bg" 8)
  _bg_lighter=$(_gt_lighten_hex "$_GT_P_bg" 15)
  _bg_dark=$(_gt_darken_hex "$_GT_P_bg" 10)
  _accent="$_GT_P_blue"

  cat <<ENDJSON
{
  "editor.background": "#${_GT_P_bg}",
  "editor.foreground": "#${_GT_P_fg}",
  "editorLineNumber.foreground": "#${_GT_P_br_black}",
  "editorLineNumber.activeForeground": "#${_GT_P_fg}",
  "titleBar.activeBackground": "#${_bg_dark}",
  "titleBar.activeForeground": "#${_GT_P_fg}",
  "titleBar.inactiveBackground": "#${_bg_dark}",
  "titleBar.inactiveForeground": "#${_GT_P_br_black}",
  "activityBar.background": "#${_bg_dark}",
  "activityBar.foreground": "#${_GT_P_fg}",
  "activityBar.activeBorder": "#${_accent}",
  "activityBarBadge.background": "#${_accent}",
  "statusBar.background": "#${_bg_dark}",
  "statusBar.foreground": "#${_GT_P_fg}",
  "statusBar.debuggingBackground": "#${_GT_P_red}",
  "statusBar.noFolderBackground": "#${_bg_dark}",
  "sideBar.background": "#${_bg_light}",
  "sideBar.foreground": "#${_GT_P_fg}",
  "sideBarSectionHeader.background": "#${_bg_lighter}",
  "tab.activeBackground": "#${_GT_P_bg}",
  "tab.inactiveBackground": "#${_bg_light}",
  "tab.activeBorderTop": "#${_accent}",
  "editorGroupHeader.tabsBackground": "#${_bg_dark}",
  "panel.background": "#${_GT_P_bg}",
  "panel.border": "#${_bg_lighter}",
  "terminal.background": "#${_GT_P_bg}",
  "terminal.foreground": "#${_GT_P_fg}",
  "terminal.ansiBlack": "#${_GT_P_black}",
  "terminal.ansiRed": "#${_GT_P_red}",
  "terminal.ansiGreen": "#${_GT_P_green}",
  "terminal.ansiYellow": "#${_GT_P_yellow}",
  "terminal.ansiBlue": "#${_GT_P_blue}",
  "terminal.ansiMagenta": "#${_GT_P_magenta}",
  "terminal.ansiCyan": "#${_GT_P_cyan}",
  "terminal.ansiWhite": "#${_GT_P_white}",
  "terminal.ansiBrightBlack": "#${_GT_P_br_black}",
  "terminal.ansiBrightRed": "#${_GT_P_br_red}",
  "terminal.ansiBrightGreen": "#${_GT_P_br_green}",
  "terminal.ansiBrightYellow": "#${_GT_P_br_yellow}",
  "terminal.ansiBrightBlue": "#${_GT_P_br_blue}",
  "terminal.ansiBrightMagenta": "#${_GT_P_br_magenta}",
  "terminal.ansiBrightCyan": "#${_GT_P_br_cyan}",
  "terminal.ansiBrightWhite": "#${_GT_P_br_white}"
}
ENDJSON
}

_gt_exclude_from_git() {
  local _exclude_file="$1/.git/info/exclude"
  if [ -f "$_exclude_file" ] && ! grep -qF ".vscode/settings.json" "$_exclude_file" 2>/dev/null; then
    printf '.vscode/settings.json\n' >> "$_exclude_file"
  fi
}

_gt_apply_vscode() {
  local _git_root="$1"
  [ -z "$_git_root" ] && return 0

  local _settings_file="$_git_root/.vscode/settings.json"
  mkdir -p "$_git_root/.vscode"

  local _color_json
  _color_json=$(_gt_build_vscode_json)

  _gt_json_merge_key "$_settings_file" "workbench.colorCustomizations" "$_color_json"
  _gt_exclude_from_git "$_git_root"
}

_gt_clean_vscode() {
  local _git_root
  _git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$_git_root" ] && [ -f "$_git_root/.vscode/settings.json" ]; then
    _gt_json_remove_key "$_git_root/.vscode/settings.json" "workbench.colorCustomizations"
  fi
}

# ─── Terminal detection and dispatch ─────────────────────────────────

_gt_detect_terminal() {
  if [ -n "${PTYXIS_PID-}" ]; then
    printf 'osc'; return
  fi
  if [ "$TERM" = "foot" ] || [ "$TERM" = "foot-extra" ]; then
    printf 'osc'; return
  fi
  if [ -n "${WEZTERM_EXECUTABLE-}" ]; then
    printf 'osc'; return
  fi
  # iTerm2
  if [ "${TERM_PROGRAM-}" = "iTerm.app" ] || [ -n "${ITERM_SESSION_ID-}" ]; then
    printf 'iterm2'; return
  fi
  if [ -n "${KONSOLE_DBUS_SESSION-}" ] || [ -n "${KONSOLE_VERSION-}" ]; then
    printf 'konsole'; return
  fi
  if [ "$TERM" = "xterm-kitty" ]; then
    printf 'kitty'; return
  fi
  if [ -n "${ALACRITTY_SOCKET-}" ] || [ -n "${ALACRITTY_LOG-}" ]; then
    printf 'alacritty'; return
  fi
  printf 'osc'
}

_gt_apply_terminal() {
  case "$(_gt_detect_terminal)" in
    iterm2)    _gt_apply_iterm2 ;;
    konsole)   _gt_apply_konsole ;;
    kitty)     _gt_apply_kitty ;;
    alacritty) _gt_apply_alacritty; _gt_send_osc_sequences ;;
    *)         _gt_send_osc_sequences ;;
  esac
}

# ─── Main entry point ───────────────────────────────────────────────

_gt_apply() {
  local _palette_data="$1" _git_root="$2"
  _gt_parse_palette "$_palette_data" || return 1
  [ -n "$_git_root" ] && _gt_apply_vscode "$_git_root"
  _gt_apply_terminal
}

# ─── Theme update (called by hook) ──────────────────────────────────

_gt_update_theme() {
  _gt_ensure_dir

  local _git_root
  _git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0

  local _repo_id
  _repo_id=$(_gt_repo_id "$_git_root")
  [ -z "$_repo_id" ] && return 0

  [ "$_repo_id" = "$GIT_THEME_CURRENT" ] && return 0
  GIT_THEME_CURRENT="$_repo_id"

  local _theme
  _theme=$(_gt_lookup "$_repo_id")

  if [ -z "$_theme" ]; then
    local _idx
    _idx=$(_gt_hash_to_index "$_repo_id")
    _theme=$(printf '%s\n' "$GIT_THEME_PALETTES" | sed -n "$(( _idx + 1 ))p" | cut -d'|' -f1)
    _gt_save "$_repo_id" "$_theme"
    printf '\033[2m[git-theme] New repo → %s\033[0m\n' "$_theme"
  fi

  local _palette_data
  _palette_data=$(_gt_get_palette "$_theme") || return 0
  _gt_apply "$_palette_data" "$_git_root"
}

# ─── User commands ───────────────────────────────────────────────────
# Function uses underscore (POSIX-safe); alias provides hyphenated name

git_theme() {
  case "${1:-}" in
    ls|list)
      printf 'Available palettes:\n'
      while IFS= read -r _raw; do
        [ -z "$_raw" ] && continue
        _gt_parse_palette "$_raw" || continue
        _bg_r=$(printf '%s' "$_GT_P_bg" | cut -c1-2)
        _bg_g=$(printf '%s' "$_GT_P_bg" | cut -c3-4)
        _bg_b=$(printf '%s' "$_GT_P_bg" | cut -c5-6)
        _fg_r=$(printf '%s' "$_GT_P_fg" | cut -c1-2)
        _fg_g=$(printf '%s' "$_GT_P_fg" | cut -c3-4)
        _fg_b=$(printf '%s' "$_GT_P_fg" | cut -c5-6)
        printf "  \033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm %-18s \033[0m\n" \
          "0x$_bg_r" "0x$_bg_g" "0x$_bg_b" \
          "0x$_fg_r" "0x$_fg_g" "0x$_fg_b" \
          "$_GT_P_name"
done <<PALETTES
$GIT_THEME_PALETTES
PALETTES
      ;;

    set)
      [ -z "${2:-}" ] && printf 'Usage: git-theme set <palette>\n' && return 1
      local _git_root
      _git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [ -z "$_git_root" ] && printf 'Not in a git repo\n' && return 1
      _gt_get_palette "$2" >/dev/null || { printf 'Unknown: %s. Run "git-theme ls"\n' "$2"; return 1; }
      local _repo_id
      _repo_id=$(_gt_repo_id "$_git_root")
      _gt_save "$_repo_id" "$2"
      GIT_THEME_CURRENT=""
      _gt_update_theme
      printf 'Set %s → %s\n' "$_repo_id" "$2"
      ;;

    current)
      local _git_root
      _git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [ -z "$_git_root" ] && printf 'Not in a git repo\n' && return 1
      local _repo_id _theme
      _repo_id=$(_gt_repo_id "$_git_root")
      _theme=$(_gt_lookup "$_repo_id")
      if [ -n "$_theme" ]; then
        printf '%s → %s\n' "$_repo_id" "$_theme"
      else
        printf '%s → (no theme assigned)\n' "$_repo_id"
      fi
      ;;

    map)
      if [ -s "$GIT_THEME_MAP" ]; then
        if command -v column >/dev/null 2>&1; then
          column -t -s'|' < "$GIT_THEME_MAP"
        else
          cat "$GIT_THEME_MAP"
        fi
      else
        printf 'No mappings yet.\n'
      fi
      ;;

    reset)
      local _git_root
      _git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [ -z "$_git_root" ] && printf 'Not in a git repo\n' && return 1
      local _repo_id
      _repo_id=$(_gt_repo_id "$_git_root")
      awk -F'|' -v id="$_repo_id" '$1 != id' "$GIT_THEME_MAP" > "${GIT_THEME_MAP}.tmp" && mv "${GIT_THEME_MAP}.tmp" "$GIT_THEME_MAP"
      GIT_THEME_CURRENT=""
      printf 'Reset theme for %s\n' "$_repo_id"
      ;;

    preview)
      printf 'Previewing all palettes (3s each)...\n'
      while IFS= read -r _raw; do
        [ -z "$_raw" ] && continue
        _gt_parse_palette "$_raw" || continue
        printf '\n─── %s ───\n' "$_GT_P_name"
        _gt_apply_terminal
        sleep 3
done <<PALETTES
$GIT_THEME_PALETTES
PALETTES
      printf '\nDone. Run "git-theme set <name>" to pick.\n'
      ;;

    off)
      printf '\033[0m\033]110\033\\\033]111\033\\'
      local _i=0
      while [ "$_i" -le 15 ]; do
        printf '\033]104;%d\033\\' "$_i"
        _i=$(( _i + 1 ))
      done
      _gt_clean_vscode
      GIT_THEME_CURRENT=""
      printf 'Colors reset.\n'
      ;;

    *)
      cat <<'USAGE'
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

# Alias: allow both git-theme and git_theme
alias git-theme='git_theme'

# ─── Shell hooks ─────────────────────────────────────────────────────
# Auto-switch only works in bash/zsh (sh has no prompt hook mechanism)

_GT_LAST_PWD=""

_gt_prompt_hook() {
  [ "$PWD" = "$_GT_LAST_PWD" ] && return
  _GT_LAST_PWD="$PWD"
  [ -n "${_GT_PREV_PRECMD_FUNC-}" ] && "$_GT_PREV_PRECMD_FUNC"
  _gt_update_theme
}

if [ -n "${ZSH_VERSION-}" ]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _gt_update_theme
elif [ -n "${BASH_VERSION-}" ]; then
  if [ "$(type -t starship_precmd 2>/dev/null)" = "function" ] || [ "${STARSHIP_SHELL-}" = "bash" ]; then
    if [ -n "${starship_precmd_user_func-}" ] && [ "$starship_precmd_user_func" != "_gt_prompt_hook" ]; then
      _GT_PREV_PRECMD_FUNC="$starship_precmd_user_func"
    fi
    starship_precmd_user_func="_gt_prompt_hook"
  else
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_gt_prompt_hook"
  fi
fi

# Apply on source if already in a repo
_gt_update_theme
