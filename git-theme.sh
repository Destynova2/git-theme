#!/bin/sh
# git-theme — Auto-assign terminal + VS Code + Claude Code palettes per Git repo
# Compatible with: sh, dash, bash, zsh, ksh
# Source this file in your .bashrc / .zshrc / .profile

# Guard against double-sourcing
[ -n "${_GT_LOADED-}" ] && return 0
_GT_LOADED=1

# ─── Paths (XDG-compliant) ──────────────────────────────────────────
GIT_THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/git-theme"
GIT_THEME_MAP="$GIT_THEME_DIR/map"
GIT_THEME_CURRENT=""

# Max repos that can share the same auto-assigned palette before we look elsewhere
GIT_THEME_MAX_USES="${GIT_THEME_MAX_USES:-2}"

# ─── Palettes ────────────────────────────────────────────────────────
# Format: name|bg|fg|black|red|green|yellow|blue|magenta|cyan|white
#          |br_black|br_red|br_green|br_yellow|br_blue|br_magenta|br_cyan|br_white
# Dark variants (auto-pickable). 12 entries — keep PALETTE_COUNT in sync.
GIT_THEME_PALETTES="mocha|1e1e2e|eef1fb|45475a|f38ba8|a6e3a1|f9e2af|89b4fa|cba6f7|94e2d5|bac2de|a0a3b4|f38ba8|a6e3a1|f9e2af|89b4fa|cba6f7|94e2d5|a6adc8
ayu-mirage|1f2430|f5f5f4|3c4653|f28779|d5ff80|ffd173|73d0ff|dfbfff|95e6cb|cbccc6|a3a9b5|ffa759|bae67e|ffcc66|5ccfe6|d4bfff|95e6cb|ffffff
monokai|272822|f8f8f2|49483e|fa4d8b|a6e22e|f4bf75|66d9ef|ae81ff|a1efe4|f8f8f2|afac9c|fa4d8b|a6e22e|e6db74|66d9ef|ae81ff|a1efe4|f9f8f5
rosepine|191724|eeedf9|3d3b4f|eb6f92|3b8bab|f6c177|9ccfd8|c4a7e7|ebbcba|e0def4|9e9bb1|eb6f92|3b8bab|f6c177|9ccfd8|c4a7e7|ebbcba|e0def4
oxocarbon|161616|f2f4f8|3b3b3b|ff7eb6|42be65|ee5396|33b1ff|be95ff|3ddbd9|dde1e6|9b9b9b|ff7eb6|42be65|ee5396|33b1ff|be95ff|3ddbd9|ffffff
tokyonight|1a1b26|eceffc|414868|f7768e|9ece6a|e0af68|7aa2f7|bb9af7|7dcfff|a9b1d6|989fbe|ff7a93|b9f27c|ff9e64|7da6ff|bb9af7|0db9d7|c0caf5
kanagawa|1f1f28|f2f1e6|41414d|d0696b|76946a|c0a36e|7e9cd8|957fb8|6a9589|c8c093|a8a3a0|ec5252|98bb6c|e6c384|7fb4ca|a292a3|7aa89f|d5cea3
gruvbox|282828|fbf7ef|4b4746|fb5744|98971a|d79921|519b9f|be7c9b|689d6a|a89984|b3aba6|fb5744|b8bb26|fabd2f|83a598|d3869b|8ec07c|bdae93
everforest|293035|ffffff|475258|e67f81|a7c080|dbbc7f|7fbbb3|d699b6|83c092|9da9a0|b7bdb6|e67f81|a7c080|dbbc7f|7fbbb3|d699b6|83c092|bdc3af
nord|282d37|ffffff|4c5361|d08a91|a3be8c|ebcb8b|81a1c1|b692af|88c0d0|e5e9f0|b3bcc9|d08a91|a3be8c|ebcb8b|81a1c1|b692af|8fbcbb|eceff4
dracula|282a36|fcfcf9|44475a|ff5858|50fa7b|f1fa8c|8592b8|bd93f9|8be9fd|f8f8f2|a5afcb|ff6e6e|69ff94|ffffa5|d6acff|ff92df|a4ffff|ffffff
solarized|002b36|fcfcfd|244e58|e56764|859900|b58900|3395da|8589ce|2aa198|93a1a1|9bafb5|e86731|859900|b58900|3395da|8589ce|2aa198|eee8d5
mocha-light|eff1f5|4c4f69|5c5f77|d20f39|147d00|a45800|1860ef|8839ef|00787f|686a80|5b5d73|c0002b|006f00|964a00|0551e0|7d28e2|006971|4c4f69
ayu-light|fcfcfc|52565b|5c6166|c3494c|567e00|a46400|0077bd|8961b0|008260|6d737b|5d6673|c02a31|497000|ac4500|006e8c|a04e1f|007452|1f2430
monokai-light|faf4f2|29242a|6e6770|c4265e|487b05|a95900|5c6ba7|9150c1|007894|726f5a|65624e|bb1b57|3b6d00|9a4c00|505e99|8343b2|006a86|29242a
rosepine-light|faf4ed|534d74|706c7d|a5556d|286983|a55c00|397782|7b6593|a75754|575279|625e7a|964860|135872|964e00|2a6974|6e5885|984948|534d74
oxocarbon-light|fffbf6|161616|737272|cd337b|007f7e|0076c0|0f62fe|8a3ffc|0076c0|525252|525252|bd1f6e|007170|0068b0|0056f1|8030f0|0068b0|161616
tokyonight-light|e1e2e7|1c409d|5c617c|c60042|4f6b30|7d5d2f|055fc9|8139d6|006a90|505f9c|43538e|af0031|435e22|6f5022|0050b9|7527c7|005c81|2950ae
kanagawa-light|f2ecbc|4b4a5a|696860|bc354a|576f35|6f6938|4d699b|a24b6a|4d6e69|545464|5c5b53|b11e2c|436334|6c5834|405b8c|933e5d|3c6258|43436c
gruvbox-light|fbf1c7|3c3836|76695f|cc241d|716f00|995e00|357579|a05276|447747|76695f|6b5c4e|9d0006|666100|8c5000|076678|8f3f71|306948|3c3836
everforest-light|fdf6e3|47555c|677265|d22e33|657600|9d6200|1076a6|b54294|007f57|5c6a72|576657|c21724|596900|8f5400|006897|a63386|007049|57646c
github-light|ffffff|1f2328|1f2328|cf222e|1a7f37|9a6700|0969da|8250df|0550ae|59636e|424a53|a40e26|0a3622|633c01|0550ae|5a26ad|033d8b|606871
dracula-light|f8f8f2|1f1f1f|282a36|cb3a2a|14710a|846f00|035bd6|644ac9|005a8e|5b6268|4d4d4c|bc2a1c|006200|766100|0049c4|583bba|00578b|1f1f1f
solarized-light|fdf6e3|41565e|073642|d52929|657600|926700|0073b9|ca2d7b|007d74|746f5e|002b36|b43400|50656c|50656d|556567|565aaa|586465|686151"

# Number of dark base palettes for auto-pick. Light variants live below this
# index in GIT_THEME_PALETTES and are reached only by name (resolver, set).
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

# Linear blend of two hex colors. $3 = percent toward $2 (0 = pure $1, 100 = pure $2)
_gt_blend_hex() {
  local _hex1="$1" _hex2="$2" _pct="${3:-50}"
  local _r1 _g1 _b1 _r2 _g2 _b2 _r _g _b
  _r1=$(printf '%d' "0x$(printf '%s' "$_hex1" | cut -c1-2)")
  _g1=$(printf '%d' "0x$(printf '%s' "$_hex1" | cut -c3-4)")
  _b1=$(printf '%d' "0x$(printf '%s' "$_hex1" | cut -c5-6)")
  _r2=$(printf '%d' "0x$(printf '%s' "$_hex2" | cut -c1-2)")
  _g2=$(printf '%d' "0x$(printf '%s' "$_hex2" | cut -c3-4)")
  _b2=$(printf '%d' "0x$(printf '%s' "$_hex2" | cut -c5-6)")
  _r=$(( _r1 + (_r2 - _r1) * _pct / 100 ))
  _g=$(( _g1 + (_g2 - _g1) * _pct / 100 ))
  _b=$(( _b1 + (_b2 - _b1) * _pct / 100 ))
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

# ─── Light/dark mode resolution ─────────────────────────────────────
# `_gt_macos_mode` returns "light" or "dark". On non-Darwin (or when the key
# is absent, which on macOS implicitly means light), defaults to "dark" so
# existing behavior is preserved.
# `_gt_resolve_palette <base>` maps a base palette name to the variant that
# should be applied right now: `<base>-light` if macOS is in light mode and
# the pendant exists, otherwise `<base>`. A user-supplied `<base>-light` is
# normalized back to `<base>` first.

_gt_macos_mode() {
  if [ "$(uname -s)" != "Darwin" ]; then
    printf 'dark'
    return
  fi
  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark; then
    printf 'dark'
  else
    printf 'light'
  fi
}

# Dark base → light variant name. Default is `<base>-light`; bases without a
# viable namesake light theme (Nord and Ayu Mirage are dark-mode-first designs
# whose pastels fail WCAG AA on near-white) are routed to curated substitutes.
_gt_light_pendant() {
  case "$1" in
    nord)       printf 'github-light' ;;
    ayu-mirage) printf 'ayu-light' ;;
    *)          printf '%s-light' "$1" ;;
  esac
}

_gt_strip_light_suffix() {
  case "$1" in
    github-light) printf 'nord' ;;
    ayu-light)    printf 'ayu-mirage' ;;
    *-light)      printf '%s' "${1%-light}" ;;
    *)            printf '%s' "$1" ;;
  esac
}

_gt_resolve_palette() {
  local _base _light
  _base=$(_gt_strip_light_suffix "$1")
  if [ "$(_gt_macos_mode)" = "light" ]; then
    _light=$(_gt_light_pendant "$_base")
    if printf '%s\n' "$GIT_THEME_PALETTES" | grep -q "^${_light}|"; then
      printf '%s' "$_light"
      return
    fi
  fi
  printf '%s' "$_base"
}

_gt_count_theme_uses() {
  awk -F'|' -v t="$1" '$2 == t { n++ } END { print n+0 }' "$GIT_THEME_MAP" 2>/dev/null
}

# Pick a palette for a repo, walking forward from the hash-derived index.
# Skip any palette already used >= GIT_THEME_MAX_USES times, and any name
# passed as $2 (used by `roll` to force a change). Falls back to the
# least-used palette if every option is saturated.
_gt_pick_theme() {
  local _repo_id="$1" _exclude="${2-}"
  local _start _i _idx _name _uses _best="" _best_uses=999
  _start=$(_gt_hash_to_index "$_repo_id")
  _i=0
  while [ "$_i" -lt "$PALETTE_COUNT" ]; do
    _idx=$(( (_start + _i) % PALETTE_COUNT ))
    _name=$(printf '%s\n' "$GIT_THEME_PALETTES" | sed -n "$(( _idx + 1 ))p" | cut -d'|' -f1)
    if [ "$_name" != "$_exclude" ]; then
      _uses=$(_gt_count_theme_uses "$_name")
      if [ "$_uses" -lt "$GIT_THEME_MAX_USES" ]; then
        printf '%s' "$_name"
        return 0
      fi
      if [ "$_uses" -lt "$_best_uses" ]; then
        _best="$_name"
        _best_uses="$_uses"
      fi
    fi
    _i=$(( _i + 1 ))
  done
  printf '%s' "$_best"
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
  printf '\033]12;#%s\033\\' "$_GT_P_fg"
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
# One Dynamic Profile per BASE palette, written to
# ~/Library/Application Support/iTerm2/DynamicProfiles/git-theme-<base>.json.
#
# Each profile carries TWO color sets — `(Light)` and `(Dark)` keys — plus
# `Use Separate Colors for Light and Dark Mode: true`. iTerm2 then swaps
# colors natively when macOS toggles appearance, with no further git-theme
# involvement. SetProfile pins the current session to the new profile once.
#
# Profiles inherit from $GIT_THEME_ITERM2_PARENT_PROFILE (default "Default")
# so user font/keybinds/etc. are preserved.

_gt_hex2iterm2_color() {
  local _r _g _b
  _r=$(printf '%d' "0x$(printf '%s' "$1" | cut -c1-2)")
  _g=$(printf '%d' "0x$(printf '%s' "$1" | cut -c3-4)")
  _b=$(printf '%d' "0x$(printf '%s' "$1" | cut -c5-6)")
  LC_ALL=C awk -v r="$_r" -v g="$_g" -v b="$_b" 'BEGIN {
    printf "{\"Red Component\":%.6f,\"Green Component\":%.6f,\"Blue Component\":%.6f,\"Alpha Component\":1,\"Color Space\":\"sRGB\"}", r/255, g/255, b/255
  }'
}

# Emit the per-mode color block for one palette line. $1 = palette line,
# $2 = mode suffix ("Light" or "Dark"). Trailing comma intentional so the
# caller can chain Light + Dark blocks; final closing field comes from the
# template wrapper.
_gt_iterm2_emit_mode_block() {
  local _line="$1" _mode="$2"
  local _bg _fg _black _red _green _yellow _blue _magenta _cyan _white
  local _br_black _br_red _br_green _br_yellow _br_blue _br_magenta _br_cyan _br_white
  _bg=$(printf '%s' "$_line" | cut -d'|' -f2)
  _fg=$(printf '%s' "$_line" | cut -d'|' -f3)
  _black=$(printf '%s' "$_line" | cut -d'|' -f4)
  _red=$(printf '%s' "$_line" | cut -d'|' -f5)
  _green=$(printf '%s' "$_line" | cut -d'|' -f6)
  _yellow=$(printf '%s' "$_line" | cut -d'|' -f7)
  _blue=$(printf '%s' "$_line" | cut -d'|' -f8)
  _magenta=$(printf '%s' "$_line" | cut -d'|' -f9)
  _cyan=$(printf '%s' "$_line" | cut -d'|' -f10)
  _white=$(printf '%s' "$_line" | cut -d'|' -f11)
  _br_black=$(printf '%s' "$_line" | cut -d'|' -f12)
  _br_red=$(printf '%s' "$_line" | cut -d'|' -f13)
  _br_green=$(printf '%s' "$_line" | cut -d'|' -f14)
  _br_yellow=$(printf '%s' "$_line" | cut -d'|' -f15)
  _br_blue=$(printf '%s' "$_line" | cut -d'|' -f16)
  _br_magenta=$(printf '%s' "$_line" | cut -d'|' -f17)
  _br_cyan=$(printf '%s' "$_line" | cut -d'|' -f18)
  _br_white=$(printf '%s' "$_line" | cut -d'|' -f19)
  cat <<ENDBLOCK
    "Background Color ($_mode)": $(_gt_hex2iterm2_color "$_bg"),
    "Foreground Color ($_mode)": $(_gt_hex2iterm2_color "$_fg"),
    "Cursor Color ($_mode)": $(_gt_hex2iterm2_color "$_fg"),
    "Cursor Text Color ($_mode)": $(_gt_hex2iterm2_color "$_bg"),
    "Smart Cursor Color ($_mode)": false,
    "Ansi 0 Color ($_mode)": $(_gt_hex2iterm2_color "$_black"),
    "Ansi 1 Color ($_mode)": $(_gt_hex2iterm2_color "$_red"),
    "Ansi 2 Color ($_mode)": $(_gt_hex2iterm2_color "$_green"),
    "Ansi 3 Color ($_mode)": $(_gt_hex2iterm2_color "$_yellow"),
    "Ansi 4 Color ($_mode)": $(_gt_hex2iterm2_color "$_blue"),
    "Ansi 5 Color ($_mode)": $(_gt_hex2iterm2_color "$_magenta"),
    "Ansi 6 Color ($_mode)": $(_gt_hex2iterm2_color "$_cyan"),
    "Ansi 7 Color ($_mode)": $(_gt_hex2iterm2_color "$_white"),
    "Ansi 8 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_black"),
    "Ansi 9 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_red"),
    "Ansi 10 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_green"),
    "Ansi 11 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_yellow"),
    "Ansi 12 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_blue"),
    "Ansi 13 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_magenta"),
    "Ansi 14 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_cyan"),
    "Ansi 15 Color ($_mode)": $(_gt_hex2iterm2_color "$_br_white")
ENDBLOCK
}

_gt_apply_iterm2() {
  local _base="${1:-$_GT_P_name}"
  _base=$(_gt_strip_light_suffix "$_base")

  local _dark_line _light_line
  _dark_line=$(_gt_get_palette "$_base") || return 1
  _light_line=$(_gt_get_palette "$(_gt_light_pendant "$_base")")
  # When no light pendant exists, write the dark colors to both slots so the
  # profile remains coherent across mode switches (no surprise "default"
  # iTerm2 colors leaking through).
  [ -z "$_light_line" ] && _light_line="$_dark_line"

  local _dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  mkdir -p "$_dir"
  local _parent="${GIT_THEME_ITERM2_PARENT_PROFILE:-Default}"
  local _final="$_dir/git-theme-$_base.json"
  # Temp file MUST live outside the watched dir: iTerm2 reads every file
  # in DynamicProfiles regardless of extension, including our .tmp, and
  # FSEvents can fire while `cat` is still writing — surfacing as
  # "invalid JSON". Building in $TMPDIR then mv(2) into the watched dir
  # gives iTerm2 a single atomic event with the complete file (rename(2)
  # is atomic when source and destination are on the same filesystem,
  # which $TMPDIR and ~/Library are by default on macOS).
  local _tmp
  _tmp=$(mktemp "${TMPDIR:-/tmp}/git-theme-iterm2.XXXXXX") || return 1

  cat > "$_tmp" <<EOF
{
  "Profiles": [{
    "Name": "git-theme:$_base",
    "Guid": "git-theme-$_base",
    "Dynamic Profile Parent Name": "$_parent",
    "Use Separate Colors for Light and Dark Mode": true,
$(_gt_iterm2_emit_mode_block "$_dark_line" "Dark"),
$(_gt_iterm2_emit_mode_block "$_light_line" "Light")
  }]
}
EOF
  mv "$_tmp" "$_final"

  # iTerm2 watches the dir; brief delay so SetProfile finds the new entry
  sleep 0.2
  printf '\033]1337;SetProfile=git-theme:%s\007' "$_base"
}

_gt_clean_iterm2() {
  rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/"git-theme-*.json
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
      background="#$_GT_P_bg" foreground="#$_GT_P_fg" cursor="#$_GT_P_fg" \
      color0="#$_GT_P_black" color1="#$_GT_P_red" color2="#$_GT_P_green" color3="#$_GT_P_yellow" \
      color4="#$_GT_P_blue" color5="#$_GT_P_magenta" color6="#$_GT_P_cyan" color7="#$_GT_P_white" \
      color8="#$_GT_P_br_black" color9="#$_GT_P_br_red" color10="#$_GT_P_br_green" color11="#$_GT_P_br_yellow" \
      color12="#$_GT_P_br_blue" color13="#$_GT_P_br_magenta" color14="#$_GT_P_br_cyan" color15="#$_GT_P_br_white" \
      2>/dev/null
  fi
}

# ─── VS Code adapter ────────────────────────────────────────────────

_gt_build_vscode_json() {
  local _bg_recede _bg_recede_more _bg_chrome _accent
  # Panel separation must MOVE AWAY from the editor bg. Lightening a near-white
  # light-theme bg has no headroom and collapses the sidebar/tab/header into
  # the editor — visually "tout est blanc". For light palettes we darken; for
  # dark palettes we lighten. Chrome (title/status) always darkens.
  case "$_GT_P_name" in
    *-light)
      _bg_recede=$(_gt_darken_hex "$_GT_P_bg" 4)
      _bg_recede_more=$(_gt_darken_hex "$_GT_P_bg" 8)
      ;;
    *)
      _bg_recede=$(_gt_lighten_hex "$_GT_P_bg" 8)
      _bg_recede_more=$(_gt_lighten_hex "$_GT_P_bg" 15)
      ;;
  esac
  _bg_chrome=$(_gt_darken_hex "$_GT_P_bg" 10)
  _accent="$_GT_P_blue"

  cat <<ENDJSON
{
  "editor.background": "#${_GT_P_bg}",
  "editor.foreground": "#${_GT_P_fg}",
  "editorGutter.background": "#${_GT_P_bg}",
  "editor.lineHighlightBackground": "#${_bg_recede}",
  "editor.selectionBackground": "#${_accent}40",
  "editor.selectionHighlightBackground": "#${_accent}25",
  "editor.wordHighlightBackground": "#${_accent}25",
  "editor.findMatchBackground": "#${_GT_P_yellow}66",
  "editor.findMatchHighlightBackground": "#${_GT_P_yellow}33",
  "editorCursor.foreground": "#${_GT_P_fg}",
  "editorLineNumber.foreground": "#${_GT_P_br_black}",
  "editorLineNumber.activeForeground": "#${_GT_P_fg}",
  "breadcrumb.background": "#${_GT_P_bg}",
  "breadcrumb.foreground": "#${_GT_P_br_black}",
  "breadcrumb.focusForeground": "#${_GT_P_fg}",
  "breadcrumb.activeSelectionForeground": "#${_accent}",
  "breadcrumbPicker.background": "#${_bg_recede}",
  "editorWidget.background": "#${_bg_recede}",
  "editorWidget.foreground": "#${_GT_P_fg}",
  "editorWidget.border": "#${_bg_recede_more}",
  "input.background": "#${_bg_recede}",
  "input.foreground": "#${_GT_P_fg}",
  "input.border": "#${_bg_recede_more}",
  "input.placeholderForeground": "#${_GT_P_br_black}",
  "inputOption.activeBackground": "#${_accent}",
  "inputOption.activeForeground": "#${_GT_P_bg}",
  "quickInput.background": "#${_bg_recede}",
  "quickInput.foreground": "#${_GT_P_fg}",
  "list.activeSelectionBackground": "#${_bg_recede_more}",
  "list.activeSelectionForeground": "#${_GT_P_fg}",
  "list.inactiveSelectionBackground": "#${_bg_recede}",
  "list.hoverBackground": "#${_bg_recede}",
  "list.focusBackground": "#${_bg_recede_more}",
  "titleBar.activeBackground": "#${_bg_chrome}",
  "titleBar.activeForeground": "#${_GT_P_fg}",
  "titleBar.inactiveBackground": "#${_bg_chrome}",
  "titleBar.inactiveForeground": "#${_GT_P_br_black}",
  "activityBar.background": "#${_bg_chrome}",
  "activityBar.foreground": "#${_GT_P_fg}",
  "activityBar.activeBorder": "#${_accent}",
  "activityBarBadge.background": "#${_accent}",
  "statusBar.background": "#${_bg_chrome}",
  "statusBar.foreground": "#${_GT_P_fg}",
  "statusBar.debuggingBackground": "#${_GT_P_red}",
  "statusBar.noFolderBackground": "#${_bg_chrome}",
  "sideBar.background": "#${_bg_recede}",
  "sideBar.foreground": "#${_GT_P_fg}",
  "sideBarSectionHeader.background": "#${_bg_recede_more}",
  "tab.activeBackground": "#${_GT_P_bg}",
  "tab.inactiveBackground": "#${_bg_recede}",
  "tab.activeBorderTop": "#${_accent}",
  "editorGroupHeader.tabsBackground": "#${_bg_chrome}",
  "panel.background": "#${_GT_P_bg}",
  "panel.border": "#${_bg_recede_more}",
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

# ─── Claude Code adapter ────────────────────────────────────────────
# Writes ~/.claude/themes/git-theme.json. User selects "custom:git-theme"
# once via /theme; subsequent palette changes hot-reload automatically
# (Claude Code watches ~/.claude/themes/).

_gt_build_claude_code_json() {
  local _diff_added _diff_removed _diff_added_dim _diff_removed_dim
  local _bash_msg_bg _user_msg_bg _user_msg_bg_hover _msg_actions_bg
  local _rainbow_orange _rainbow_indigo
  local _rainbow_orange_shimmer _rainbow_indigo_shimmer
  local _rate_limit_empty _selection_bg _memory_bg _base _subtle
  local _diff_blend _diff_dim_blend

  # Match the inheritance base to the palette polarity: a "dark" base under
  # a light palette leaves un-overridden tokens (mascot, niche UI) rendering
  # with dark defaults on top of a near-white background. Light palettes also
  # need lower diff saturation — the bg has high luminance, so the same
  # blend % reads as a much louder tint than on a dark bg.
  case "$_GT_P_name" in
    *-light) _base="light"; _diff_blend=22; _diff_dim_blend=10 ;;
    *)       _base="dark";  _diff_blend=35; _diff_dim_blend=20 ;;
  esac

  # Push subtle/inactive grays halfway from br_black toward fg. The palette's
  # br_black hits ~4.5:1 on light bg — at the WCAG AA floor for body text,
  # which renders the model badge and code punctuation as "too pale".
  _subtle=$(_gt_blend_hex "$_GT_P_br_black" "$_GT_P_fg" 50)

  _diff_added=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_green" "$_diff_blend")
  _diff_removed=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_red" "$_diff_blend")
  _diff_added_dim=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_green" "$_diff_dim_blend")
  _diff_removed_dim=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_red" "$_diff_dim_blend")
  _bash_msg_bg=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_fg" 6)
  _user_msg_bg=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_fg" 12)
  _user_msg_bg_hover=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_fg" 18)
  _msg_actions_bg=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_blue" 15)
  _rainbow_orange=$(_gt_blend_hex "$_GT_P_red" "$_GT_P_yellow" 50)
  _rainbow_indigo=$(_gt_blend_hex "$_GT_P_blue" "$_GT_P_magenta" 50)
  _rainbow_orange_shimmer=$(_gt_blend_hex "$_GT_P_br_red" "$_GT_P_br_yellow" 50)
  _rainbow_indigo_shimmer=$(_gt_blend_hex "$_GT_P_br_blue" "$_GT_P_br_magenta" 50)
  _rate_limit_empty=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_blue" 30)
  _selection_bg=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_blue" 35)
  _memory_bg=$(_gt_blend_hex "$_GT_P_bg" "$_GT_P_cyan" 8)

  cat <<ENDJSON
{
  "name": "git-theme ($_GT_P_name)",
  "base": "$_base",
  "overrides": {
    "text": "#${_GT_P_fg}",
    "inverseText": "#${_GT_P_bg}",
    "background": "#${_GT_P_bg}",
    "subtle": "#${_subtle}",
    "inactive": "#${_subtle}",
    "inactiveShimmer": "#${_GT_P_white}",
    "claude": "#${_GT_P_br_magenta}",
    "claudeShimmer": "#${_GT_P_br_magenta}",
    "claudeBlue_FOR_SYSTEM_SPINNER": "#${_GT_P_blue}",
    "claudeBlueShimmer_FOR_SYSTEM_SPINNER": "#${_GT_P_br_blue}",
    "bashBorder": "#${_GT_P_magenta}",
    "bashMessageBackgroundColor": "#${_bash_msg_bg}",
    "userMessageBackground": "#${_user_msg_bg}",
    "userMessageBackgroundHover": "#${_user_msg_bg_hover}",
    "messageActionsBackground": "#${_msg_actions_bg}",
    "memoryBackgroundColor": "#${_memory_bg}",
    "selectionBg": "#${_selection_bg}",
    "promptBorder": "#${_GT_P_br_black}",
    "promptBorderShimmer": "#${_GT_P_white}",
    "success": "#${_GT_P_green}",
    "error": "#${_GT_P_red}",
    "warning": "#${_GT_P_yellow}",
    "warningShimmer": "#${_GT_P_br_yellow}",
    "merged": "#${_GT_P_magenta}",
    "suggestion": "#${_GT_P_blue}",
    "permission": "#${_GT_P_blue}",
    "permissionShimmer": "#${_GT_P_br_blue}",
    "remember": "#${_GT_P_blue}",
    "autoAccept": "#${_GT_P_magenta}",
    "planMode": "#${_GT_P_cyan}",
    "ide": "#${_GT_P_br_blue}",
    "fastMode": "#${_GT_P_br_red}",
    "fastModeShimmer": "#${_GT_P_br_yellow}",
    "rate_limit_fill": "#${_GT_P_blue}",
    "rate_limit_empty": "#${_rate_limit_empty}",
    "diffAdded": "#${_diff_added}",
    "diffRemoved": "#${_diff_removed}",
    "diffAddedDimmed": "#${_diff_added_dim}",
    "diffRemovedDimmed": "#${_diff_removed_dim}",
    "diffAddedWord": "#${_GT_P_green}",
    "diffRemovedWord": "#${_GT_P_red}",
    "rainbow_red": "#${_GT_P_red}",
    "rainbow_orange": "#${_rainbow_orange}",
    "rainbow_yellow": "#${_GT_P_yellow}",
    "rainbow_green": "#${_GT_P_green}",
    "rainbow_blue": "#${_GT_P_blue}",
    "rainbow_indigo": "#${_rainbow_indigo}",
    "rainbow_violet": "#${_GT_P_magenta}",
    "rainbow_red_shimmer": "#${_GT_P_br_red}",
    "rainbow_orange_shimmer": "#${_rainbow_orange_shimmer}",
    "rainbow_yellow_shimmer": "#${_GT_P_br_yellow}",
    "rainbow_green_shimmer": "#${_GT_P_br_green}",
    "rainbow_blue_shimmer": "#${_GT_P_br_blue}",
    "rainbow_indigo_shimmer": "#${_rainbow_indigo_shimmer}",
    "rainbow_violet_shimmer": "#${_GT_P_br_magenta}",
    "red_FOR_SUBAGENTS_ONLY": "#${_GT_P_red}",
    "blue_FOR_SUBAGENTS_ONLY": "#${_GT_P_blue}",
    "green_FOR_SUBAGENTS_ONLY": "#${_GT_P_green}",
    "yellow_FOR_SUBAGENTS_ONLY": "#${_GT_P_yellow}",
    "purple_FOR_SUBAGENTS_ONLY": "#${_GT_P_magenta}",
    "orange_FOR_SUBAGENTS_ONLY": "#${_GT_P_br_red}",
    "pink_FOR_SUBAGENTS_ONLY": "#${_GT_P_br_magenta}",
    "cyan_FOR_SUBAGENTS_ONLY": "#${_GT_P_cyan}",
    "briefLabelYou": "#${_GT_P_blue}",
    "briefLabelClaude": "#${_GT_P_br_magenta}"
  }
}
ENDJSON
}

_gt_apply_claude_code() {
  local _theme_dir="$HOME/.claude/themes"
  mkdir -p "$_theme_dir"
  _gt_build_claude_code_json > "$_theme_dir/git-theme.json"
}

_gt_clean_claude_code() {
  rm -f "$HOME/.claude/themes/git-theme.json"
}

# ─── Tmux adapter ──────────────────────────────────────────────────

_gt_apply_tmux() {
  # Window and pane background/foreground
  tmux set -g window-style "bg=#$_GT_P_bg,fg=#$_GT_P_fg"
  tmux set -g window-active-style "bg=#$_GT_P_bg,fg=#$_GT_P_fg"

  # Status bar
  local _status_bg
  _status_bg=$(_gt_darken_hex "$_GT_P_bg" 20)
  tmux set -g status-style "bg=#$_status_bg,fg=#$_GT_P_fg"
  tmux set -g status-left-style "bg=#$_GT_P_blue,fg=#$_GT_P_bg,bold"
  tmux set -g status-right-style "bg=#$_status_bg,fg=#$_GT_P_br_black"

  # Active/inactive window tabs
  tmux set -g window-status-current-style "bg=#$_GT_P_bg,fg=#$_GT_P_blue,bold"
  tmux set -g window-status-style "bg=#$_status_bg,fg=#$_GT_P_br_black"

  # Pane borders
  tmux set -g pane-border-style "fg=#$_GT_P_br_black"
  tmux set -g pane-active-border-style "fg=#$_GT_P_blue"

  # Message and command prompt
  tmux set -g message-style "bg=#$_GT_P_yellow,fg=#$_GT_P_bg"
  tmux set -g message-command-style "bg=#$_GT_P_bg,fg=#$_GT_P_yellow"

  # Pass full OSC palette through to the host terminal (iTerm2, etc.)
  printf '\033Ptmux;\033\033]11;#%s\033\033\\\033\\' "$_GT_P_bg"
  printf '\033Ptmux;\033\033]10;#%s\033\033\\\033\\' "$_GT_P_fg"
  printf '\033Ptmux;\033\033]12;#%s\033\033\\\033\\' "$_GT_P_fg"
  printf '\033Ptmux;\033\033]4;0;#%s\033\033\\\033\\' "$_GT_P_black"
  printf '\033Ptmux;\033\033]4;1;#%s\033\033\\\033\\' "$_GT_P_red"
  printf '\033Ptmux;\033\033]4;2;#%s\033\033\\\033\\' "$_GT_P_green"
  printf '\033Ptmux;\033\033]4;3;#%s\033\033\\\033\\' "$_GT_P_yellow"
  printf '\033Ptmux;\033\033]4;4;#%s\033\033\\\033\\' "$_GT_P_blue"
  printf '\033Ptmux;\033\033]4;5;#%s\033\033\\\033\\' "$_GT_P_magenta"
  printf '\033Ptmux;\033\033]4;6;#%s\033\033\\\033\\' "$_GT_P_cyan"
  printf '\033Ptmux;\033\033]4;7;#%s\033\033\\\033\\' "$_GT_P_white"
  printf '\033Ptmux;\033\033]4;8;#%s\033\033\\\033\\' "$_GT_P_br_black"
  printf '\033Ptmux;\033\033]4;9;#%s\033\033\\\033\\' "$_GT_P_br_red"
  printf '\033Ptmux;\033\033]4;10;#%s\033\033\\\033\\' "$_GT_P_br_green"
  printf '\033Ptmux;\033\033]4;11;#%s\033\033\\\033\\' "$_GT_P_br_yellow"
  printf '\033Ptmux;\033\033]4;12;#%s\033\033\\\033\\' "$_GT_P_br_blue"
  printf '\033Ptmux;\033\033]4;13;#%s\033\033\\\033\\' "$_GT_P_br_magenta"
  printf '\033Ptmux;\033\033]4;14;#%s\033\033\\\033\\' "$_GT_P_br_cyan"
  printf '\033Ptmux;\033\033]4;15;#%s\033\033\\\033\\' "$_GT_P_br_white"
}

# ─── Terminal detection and dispatch ─────────────────────────────────

_gt_detect_terminal() {
  if [ -n "${TMUX-}" ]; then
    printf 'tmux'; return
  fi
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
  local _base="${1:-}"
  case "$(_gt_detect_terminal)" in
    tmux)      _gt_apply_tmux ;;
    iterm2)    _gt_apply_iterm2 "$_base" ;;
    konsole)   _gt_apply_konsole ;;
    kitty)     _gt_apply_kitty ;;
    alacritty) _gt_apply_alacritty; _gt_send_osc_sequences ;;
    *)         _gt_send_osc_sequences ;;
  esac
}

# ─── Main entry point ───────────────────────────────────────────────
# `_gt_apply` receives the ACTIVE-variant palette data (already resolved by
# the caller for the current macOS mode) plus the BASE name. The base lets
# iTerm2 write a single dynamic profile containing both light AND dark color
# sets, so iTerm2's native auto-switch handles future macOS mode toggles
# without re-running git-theme. Other adapters use the active variant only.

_gt_apply() {
  local _palette_data="$1" _git_root="$2" _base="${3:-}"
  _gt_parse_palette "$_palette_data" || return 1
  [ -n "$_git_root" ] && _gt_apply_vscode "$_git_root"
  _gt_apply_claude_code
  _gt_apply_terminal "$_base"
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
    _theme=$(_gt_pick_theme "$_repo_id")
    _gt_save "$_repo_id" "$_theme"
    printf '\033[2m[git-theme] New repo → %s\033[0m\n' "$_theme"
  fi

  # Map saves the BASE name; resolve to the active variant for this mode
  local _active _palette_data
  _active=$(_gt_resolve_palette "$_theme")
  _palette_data=$(_gt_get_palette "$_active") || return 0
  _gt_apply "$_palette_data" "$_git_root" "$(_gt_strip_light_suffix "$_theme")"
}

# ─── User commands ───────────────────────────────────────────────────
# Function uses underscore (POSIX-safe); alias provides hyphenated name

git_theme() {
  case "${1:-}" in
    ls|list)
      # Default: hide -light variants (they auto-pair with their base). Pass
      # `--all` to show every palette including light pendants.
      local _show_all=0
      [ "${2:-}" = "--all" ] && _show_all=1
      printf 'Available palettes:\n'
      while IFS= read -r _raw; do
        [ -z "$_raw" ] && continue
        _gt_parse_palette "$_raw" || continue
        case "$_GT_P_name" in
          *-light) [ "$_show_all" -eq 0 ] && continue ;;
        esac
        _bg_r=$(printf '%s' "$_GT_P_bg" | cut -c1-2)
        _bg_g=$(printf '%s' "$_GT_P_bg" | cut -c3-4)
        _bg_b=$(printf '%s' "$_GT_P_bg" | cut -c5-6)
        _fg_r=$(printf '%s' "$_GT_P_fg" | cut -c1-2)
        _fg_g=$(printf '%s' "$_GT_P_fg" | cut -c3-4)
        _fg_b=$(printf '%s' "$_GT_P_fg" | cut -c5-6)
        # Mark base palettes that have a light pendant available
        local _suffix=""
        case "$_GT_P_name" in
          *-light) _suffix="" ;;
          *)
            if printf '%s\n' "$GIT_THEME_PALETTES" | grep -q "^$(_gt_light_pendant "$_GT_P_name")|"; then
              _suffix="  ↔ light"
            fi
            ;;
        esac
        printf "  \033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm %-18s \033[0m%s\n" \
          "0x$_bg_r" "0x$_bg_g" "0x$_bg_b" \
          "0x$_fg_r" "0x$_fg_g" "0x$_fg_b" \
          "$_GT_P_name" "$_suffix"
done <<PALETTES
$GIT_THEME_PALETTES
PALETTES
      ;;

    set)
      [ -z "${2:-}" ] && printf 'Usage: git-theme set <palette>\n' && return 1
      local _git_root
      _git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [ -z "$_git_root" ] && printf 'Not in a git repo\n' && return 1
      # Normalize -light suffix: the map stores BASE names; the resolver
      # picks the variant per macOS mode. User can pass either form.
      local _name
      _name=$(_gt_strip_light_suffix "$2")
      _gt_get_palette "$_name" >/dev/null || { printf 'Unknown: %s. Run "git-theme ls"\n' "$2"; return 1; }
      local _repo_id
      _repo_id=$(_gt_repo_id "$_git_root")
      _gt_save "$_repo_id" "$_name"
      GIT_THEME_CURRENT=""
      _gt_update_theme
      printf 'Set %s → %s\n' "$_repo_id" "$_name"
      ;;

    refresh)
      # Re-apply current repo's theme (re-resolves variant for current mode).
      # Useful after toggling macOS Light/Dark for adapters that don't
      # auto-switch (VS Code, Claude Code, Konsole, generic OSC). iTerm2
      # already handles mode toggles natively via its dual-color profile.
      GIT_THEME_CURRENT=""
      _gt_update_theme
      ;;

    current)
      local _git_root
      _git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [ -z "$_git_root" ] && printf 'Not in a git repo\n' && return 1
      local _repo_id _theme _active _mode
      _repo_id=$(_gt_repo_id "$_git_root")
      _theme=$(_gt_lookup "$_repo_id")
      if [ -n "$_theme" ]; then
        _active=$(_gt_resolve_palette "$_theme")
        _mode=$(_gt_macos_mode)
        if [ "$_active" != "$_theme" ]; then
          printf '%s → %s (mode=%s, active=%s)\n' "$_repo_id" "$_theme" "$_mode" "$_active"
        else
          printf '%s → %s (mode=%s)\n' "$_repo_id" "$_theme" "$_mode"
        fi
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

    roll)
      local _git_root
      _git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      [ -z "$_git_root" ] && printf 'Not in a git repo\n' && return 1
      _gt_ensure_dir
      local _repo_id _current _new
      _repo_id=$(_gt_repo_id "$_git_root")
      _current=$(_gt_lookup "$_repo_id")
      # Drop existing mapping so it doesn't count toward usage
      if [ -n "$_current" ]; then
        awk -F'|' -v id="$_repo_id" '$1 != id' "$GIT_THEME_MAP" > "${GIT_THEME_MAP}.tmp" && mv "${GIT_THEME_MAP}.tmp" "$GIT_THEME_MAP"
      fi
      _new=$(_gt_pick_theme "$_repo_id" "$_current")
      if [ -z "$_new" ]; then
        printf 'No alternative palette available\n'
        [ -n "$_current" ] && _gt_save "$_repo_id" "$_current"
        return 1
      fi
      _gt_save "$_repo_id" "$_new"
      GIT_THEME_CURRENT=""
      _gt_update_theme
      if [ -n "$_current" ]; then
        printf 'Rolled %s: %s → %s\n' "$_repo_id" "$_current" "$_new"
      else
        printf 'Set %s → %s\n' "$_repo_id" "$_new"
      fi
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
      printf '\033[0m\033]110\033\\\033]111\033\\\033]112\033\\'
      local _i=0
      while [ "$_i" -le 15 ]; do
        printf '\033]104;%d\033\\' "$_i"
        _i=$(( _i + 1 ))
      done
      _gt_clean_vscode
      _gt_clean_claude_code
      _gt_clean_iterm2
      GIT_THEME_CURRENT=""
      printf 'Colors reset.\n'
      ;;

    *)
      cat <<'USAGE'
git-theme — auto-assign terminal + VS Code + Claude Code palettes per git repo

Commands:
  ls|list [--all]  Show palettes (light pendants hidden unless --all)
  set <name>       Assign a palette to the current repo (-light suffix is normalized away)
  current          Show theme + active variant for current macOS mode
  refresh          Re-apply current theme (use after toggling macOS Light/Dark
                   for adapters that don't auto-switch — iTerm2 already does)
  map              Show all repo → palette assignments
  roll             Re-roll: switch to a different (least-used) palette
  reset            Remove assignment for current repo
  preview          Cycle through all palettes (3s each)
  off              Reset terminal + VS Code + Claude + iTerm2 dynamic profiles

Auto-assignment skips palettes already used GIT_THEME_MAX_USES times
(default: 2). Override via env var. Light pendants don't participate in
auto-pick — they're paired automatically with their dark base.

Mode-aware:
  Each base palette ships with a -light pendant (e.g. mocha ↔ mocha-light).
  On macOS the active variant follows AppleInterfaceStyle. iTerm2 dynamic
  profiles ship both color sets so iTerm2 toggles natively. Other adapters
  re-apply on `git-theme refresh`.

Terminals: Konsole, Alacritty, Kitty, iTerm2, Ptyxis, foot, wezterm, tmux, + OSC fallback
VS Code:   auto-updates .vscode/settings.json (excluded from git)
Claude:    ~/.claude/themes/git-theme.json — pick "custom:git-theme" via /theme once
iTerm2:    ~/Library/Application Support/iTerm2/DynamicProfiles/git-theme-<base>.json
           Override parent profile via GIT_THEME_ITERM2_PARENT_PROFILE (default "Default")
Sync:      ~/.local/share/git-theme/map → add to your dotfiles
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
