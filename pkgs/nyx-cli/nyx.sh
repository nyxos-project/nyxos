# nyx: short commands for the Nix package manager on NyxOS. Each one runs a single
# nix command; anything nyx doesn't know goes to nix unchanged.

usage() {
  cat <<'EOF'
nyx install PKG…          install packages for your user
nyx remove PKG…           remove them (also: uninstall)
nyx update [PKG…]         update all your packages, or the ones named
nyx list                  your installed packages
nyx search TERM…          search the package collection
nyx run PKG [ARGS…]       run a program without installing it
nyx shell PKG… [-c CMD]   open a shell with packages available
nyx rollback              undo the last install, remove or update
nyx history               past installs, removals and updates
nyx clean                 delete old versions to free disk space
nyx icons …               theme launcher icons (nyx icons --help)
nyx share FILE…           share through the Share Sheet
nyx plugin …              bar plugins: list, add, configure, update… (nyx plugin help)

PKG is a package name (firefox), a Nyx app (nyx-pdf) or any flake reference.
Any other command goes to nix: nyx build, nyx flake, nyx develop…
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
    (($#)) || set -- --all
    exec nix profile upgrade "$@" ;;
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
  plugin | plugins)
    shift
    command -v nyx-plugin >/dev/null || { echo "Plugins come with Nyx Bar, which isn't installed on this system." >&2; exit 1; }
    exec nyx-plugin "$@" ;;
  "" | -h | --help | help)
    usage ;;
  *)
    exec nix "$@" ;;
esac
