# Nyx prompt: user@host over SSH, directory, Git branch and state, background jobs,
# and a status-coloured arrow. Colours come from the NYX_PROMPT_* variables.

autoload -Uz vcs_info add-zsh-hook
setopt prompt_subst

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats ' %b%u%c'
zstyle ':vcs_info:git:*' actionformats ' %b|%a%u%c'

_nyx_prompt_precmd() {
  vcs_info
}
add-zsh-hook precmd _nyx_prompt_precmd

_nyx_prompt_host=''
[[ -n $SSH_CONNECTION ]] && _nyx_prompt_host="%F{$NYX_PROMPT_DIM}%n@%m%f "

PROMPT='${_nyx_prompt_host}%F{$NYX_PROMPT_DIR}%~%f%F{$NYX_PROMPT_GIT}${vcs_info_msg_0_}%f%(1j. %F{$NYX_PROMPT_DIM}%j&%f.)
%(?.%F{$NYX_PROMPT_ACCENT}.%F{$NYX_PROMPT_ERROR})❯%f '
RPROMPT=''
