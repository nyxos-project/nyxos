# nyx: short commands for the Nix package manager on NyxOS. Each one runs a single
# nix command; anything nyx doesn't know goes to nix unchanged.

usage() {
  cat <<'EOF'
nyx install PKG…          install packages for your user
nyx remove PKG…           remove them (also: uninstall)
nyx update [WHAT…]        update everything, or system, apps, tools, firmware, or
                          one thing by name (nyx update --help)
nyx list                  your installed packages
nyx search TERM…          search the package collection
nyx run PKG [ARGS…]       run a program without installing it
nyx shell PKG… [-c CMD]   open a shell with packages available
nyx rollback              undo the last install, remove or update
nyx history               past installs, removals and updates
nyx clean                 delete old versions to free disk space
nyx icons …               theme launcher icons (nyx icons --help)
nyx share FILE…           share through the Share Sheet
nyx display virtual …     split a wide screen into virtual monitors (nyx display --help)
nyx plugin …              bar plugins: list, add, configure, update… (nyx plugin help)
nyx system …              the system: settings, packages for everyone, update, rollback
                          (nyx system help)
nyx service NAME on|off   system services NyxOS manages (nyx system services)
nyx agent [ARGS…]         start your default coding agent (nyx agent help)
nyx apps                  what Nyx apps can do from here (nyx apps help APP)
nyx APP [ACTION] [ARGS…]  an app's action: nyx notes create "Ideas", nyx music jazz
                          (nyx APP --help lists them)
nyx completion SHELL      completions for bash, zsh or fish

PKG is a package name (firefox), a Nyx app (nyx-pdf) or any flake reference.
Any other command goes to an app that answers to it, else to nix: nyx build,
nyx flake, nyx develop…
EOF
}

# firefox → nixpkgs#firefox, nyx-pdf → the Nyx app; flake references and options as given.
ref() {
  case $1 in
    -* | *'#'* | *:*) printf '%s' "$1" ;;
    nyx-*) printf 'github:nyxos-project/nyx-packages#%s' "$1" ;;
    *) printf 'nixpkgs#%s' "$1" ;;
  esac
}

# ----- Coding agents -----

# The agents `nyx agent` starts: command, name, and the flags that let it work without
# stopping to ask, since it's started for a task you hand it. Run by name, an agent
# keeps its own prompts.
known_agents() {
  cat <<'EOF'
claude	Claude Code	--permission-mode auto
codex	Codex CLI	--dangerously-bypass-approvals-and-sandbox
agy	Antigravity CLI	--dangerously-skip-permissions
cursor-agent	Cursor Agent	--yolo --trust
grok	Grok Build	--permission-mode bypassPermissions
crush	Crush	--yolo
opencode	OpenCode	
omp	oh-my-pi	--auto-approve
gemini	Gemini CLI	--yolo
pi	Pi	
EOF
}

agent_file="${XDG_CONFIG_HOME:-$HOME/.config}/nyx/agent"
skills_source=/etc/nyxos/agents/skills

agent_usage() {
  cat <<'EOF'
nyx agent [ARGS…]          start the default agent, here or in a new terminal
nyx agent default [CMD]    show the default agent, or make CMD it (none clears it)
nyx agent list [--all]     installed agents as command and name (--all: every one nyx knows)
nyx agent skills           link NyxOS's skills into every agent's skills folder

From a terminal the agent starts in it; otherwise (a shortcut) in a new terminal.
ARGS go to the agent after its flags. Settings and Welcome choose the default too.
EOF
}

agent_line() {
  known_agents | awk -F'\t' -v c="$1" '$1 == c'
}

current_agent() {
  [[ -f $agent_file ]] && head -n1 "$agent_file" | tr -d '[:space:]'
  return 0
}

# Every agent reads one of these; a skill of the user's own by the same name stays.
link_skills() {
  [[ -d $skills_source ]] || return 0
  local config=${XDG_CONFIG_HOME:-$HOME/.config} dir skill name link
  local dirs=(
    "$HOME/.agents/skills"
    "$config/agents/skills"
    "$HOME/.claude/skills"
    "$config/opencode/skills"
    "$HOME/.grok/skills"
    "$HOME/.gemini/config/skills"
    "$HOME/.gemini/antigravity-cli/skills"
  )
  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    for link in "$dir"/*; do
      if [[ -L $link && $(readlink "$link") == "$skills_source"/* && ! -e $link ]]; then
        rm -f "$link"
      fi
    done
    for skill in "$skills_source"/*/; do
      [[ -d $skill ]] || continue
      name=$(basename "$skill")
      if [[ -e $dir/$name && ! -L $dir/$name ]]; then
        continue
      fi
      ln -sfn "$skills_source/$name" "$dir/$name"
    done
  done
}

agent() {
  case ${1:-} in
    help | -h | --help)
      agent_usage
      return ;;
    list)
      local cmd name _flags
      while IFS=$'\t' read -r cmd name _flags; do
        if [[ ${2:-} == --all ]] || command -v "$cmd" >/dev/null; then
          printf '%s\t%s\n' "$cmd" "$name"
        fi
      done < <(known_agents)
      return ;;
    default)
      if (($# < 2)); then
        current_agent
        return
      fi
      if [[ $2 == none ]]; then
        rm -f "$agent_file"
        return
      fi
      [[ -n $(agent_line "$2") ]] || { echo "nyx doesn't know an agent called $2 (nyx agent list --all)" >&2; exit 1; }
      mkdir -p "$(dirname "$agent_file")"
      printf '%s\n' "$2" >"$agent_file"
      return ;;
    skills)
      link_skills
      return ;;
  esac

  local cmd
  cmd=$(current_agent)
  if [[ -z $cmd ]]; then
    if [[ -t 1 ]]; then
      echo "No default coding agent yet. Choose one in Settings > Default Apps, or: nyx agent default CMD" >&2
      exit 1
    fi
    exec nyx-settings --section apps
  fi
  if ! command -v "$cmd" >/dev/null; then
    if [[ -t 1 ]]; then
      echo "$cmd isn't installed. Install it in Nyx Store, or choose another agent in Settings." >&2
      exit 1
    fi
    exec nyx-settings --section apps
  fi
  if ! [[ -t 0 && -t 1 ]]; then
    exec xdg-terminal-exec nyx agent "$@"
  fi

  # Agents won't remember that they trust your home folder, so start in a work folder.
  if [[ $PWD == "$HOME" ]]; then
    for d in "$HOME/Work" "$HOME/Projects"; do
      if [[ -d $d ]]; then
        cd "$d"
        break
      fi
    done
  fi
  link_skills
  local flags
  flags=$(agent_line "$cmd" | cut -f3)
  # shellcheck disable=SC2086 # flags are words
  exec "$cmd" $flags "$@"
}

# ----- Nyx apps' actions (nyx-actions) -----

builtins="install add remove uninstall update upgrade list search run shell rollback history clean icons share display system service agent agents plugin plugins apps completion help"

apps() {
  command -v nyx-actions >/dev/null || { echo "nyx-actions isn't installed on this system." >&2; exit 1; }
  case ${1:-} in
    help) shift; exec nyx-actions help "$@" ;;
    list) shift; exec nyx-actions apps "$@" ;;
    *) exec nyx-actions apps "$@" ;;
  esac
}

# Package arguments until the first option; the rest pass through untouched.
refs=()
expand() {
  refs=()
  while (($#)) && [[ $1 != -* ]]; do
    refs+=("$(ref "$1")")
    shift
  done
  refs+=("$@")
}

case ${1:-} in
  install | add)
    shift
    expand "$@"
    exec nix profile add "${refs[@]}" ;;
  remove | uninstall)
    shift
    exec nix profile remove "$@" ;;
  update | upgrade)
    shift
    command -v nyx-system >/dev/null || { echo "The Nyx System Manager isn't installed on this system." >&2; exit 1; }
    exec nyx-system update "$@" ;;
  list)
    shift
    exec nix profile list "$@" ;;
  search)
    shift
    exec nix search nixpkgs "$@" ;;
  run)
    shift
    (($#)) || { usage >&2; exit 1; }
    package=$(ref "$1")
    shift
    [[ ${1:-} == -- ]] && shift
    exec nix run "$package" -- "$@" ;;
  shell)
    shift
    expand "$@"
    exec nix shell "${refs[@]}" ;;
  rollback)
    shift
    exec nix profile rollback "$@" ;;
  history)
    shift
    exec nix profile history "$@" ;;
  clean)
    shift
    exec nix-collect-garbage -d "$@" ;;
  icons)
    shift
    exec nyx-icons "$@" ;;
  share)
    shift
    command -v nyx-share >/dev/null || { echo "Share isn't installed on this system." >&2; exit 1; }
    exec nyx-share "$@" ;;
  display)
    shift
    command -v nyx-display >/dev/null || { echo "nyx display comes with Nyx Settings, which isn't installed on this system." >&2; exit 1; }
    exec nyx-display "$@" ;;
  system)
    shift
    command -v nyx-system >/dev/null || { echo "The Nyx System Manager isn't installed on this system." >&2; exit 1; }
    exec nyx-system "$@" ;;
  service)
    shift
    command -v nyx-system >/dev/null || { echo "The Nyx System Manager isn't installed on this system." >&2; exit 1; }
    exec nyx-system service "$@" ;;
  agent | agents)
    shift
    agent "$@" ;;
  plugin | plugins)
    shift
    command -v nyx-plugin >/dev/null || { echo "Plugins come with Nyx Bar, which isn't installed on this system." >&2; exit 1; }
    exec nyx-plugin "$@" ;;
  apps)
    shift
    apps "$@" ;;
  completion)
    shift
    command -v nyx-actions >/dev/null || { echo "nyx-actions isn't installed on this system." >&2; exit 1; }
    # shellcheck disable=SC2086 # the built-in commands are words
    exec nyx-actions completion "${1:-bash}" $builtins ;;
  "" | -h | --help | help)
    usage ;;
  *)
    if command -v nyx-actions >/dev/null && nyx-actions has "$1"; then
      exec nyx-actions run "$@"
    fi
    exec nix "$@" ;;
esac
