# The prompt in the user's Nyx theme: nyx-themed writes its colours to
# ~/.config/zsh/nyx-theme.zsh when the theme changes, and every open shell takes them
# at its next prompt.

zmodload -F zsh/stat b:zstat
_nyx_theme_zsh=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/nyx-theme.zsh
_nyx_theme_mtime=0

_nyx_theme_precmd() {
  local -a m
  zstat -A m +mtime -- $_nyx_theme_zsh 2>/dev/null || return
  (( m[1] == _nyx_theme_mtime )) && return
  _nyx_theme_mtime=$m[1]
  source $_nyx_theme_zsh
}
add-zsh-hook precmd _nyx_theme_precmd
_nyx_theme_precmd
