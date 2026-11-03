# nyx: the Nyx command line on NyxOS. Same commands as the Omarchy CLI, but apps
# belong to the system configuration here, so nothing is installed from source into
# ~/.local/bin.

ALL=(settings contacts activity torrents pdf notepad music media-player theater chat fonts archive office photos glimpse store git passwords weather news capture pulse containers files cloud notes calculator home maps transfer mail calendar reminders share dock control-center notification-center clipboard)
# Apps nyx-packages builds for this NyxOS release.
read -r -a PACKAGED <<<"@packaged@"

# The program that shows an app is installed.
program() {
  case $1 in
    office) echo nyx-office ;;
    photos) echo nyx-photos ;;
    cloud) echo nyx-cloudd ;;
    *) echo "nyx-$1" ;;
  esac
}

packaged() {
  local app
  for app in "${PACKAGED[@]}"; do [[ $app == "$1" ]] && return 0; done
  return 1
}

usage() {
  cat <<'EOF'
nyx icons check | generate | sync | restore | follow on|off   theme launcher icons
nyx list                   the apps, and which are installed
nyx install | uninstall    how to add or remove apps on NyxOS
nyx update                 how to update NyxOS and its apps
nyx share FILE…            share through the Share Sheet (nyx share --help)
EOF
}

configure() {
  local verb=$1 app value options=()
  shift
  (($#)) || { echo "Usage: nyx $verb APP…" >&2; exit 1; }
  [[ $verb == install ]] && value=true || value=false
  for app in "$@"; do
    if packaged "$app"; then
      options+=("  nyx.$app.enable = $value;")
    else
      echo "$app isn't packaged for NyxOS yet." >&2
    fi
  done
  ((${#options[@]})) || exit 1
  echo "Apps are part of the NyxOS system configuration. Set these in your"
  echo "configuration, then apply it with: sudo nixos-rebuild switch"
  echo
  printf '%s\n' "${options[@]}"
}

case ${1:-} in
  icons)
    shift
    exec nyx-icons "$@" ;;
  share)
    shift
    command -v nyx-share >/dev/null || { echo "Share isn't installed on this system." >&2; exit 1; }
    exec nyx-share "$@" ;;
  list)
    for a in "${ALL[@]}"; do
      if command -v "$(program "$a")" >/dev/null; then
        printf '  %-20s installed\n' "$a"
      elif packaged "$a"; then
        printf '  %-20s available\n' "$a"
      else
        printf '  %s\n' "$a"
      fi
    done ;;
  install | uninstall | remove)
    verb=$1
    [[ $verb == remove ]] && verb=uninstall
    shift
    configure "$verb" "$@" ;;
  update)
    echo "NyxOS updates the system and its apps together: update the configuration's"
    echo "flake inputs, then apply them with: sudo nixos-rebuild switch" ;;
  "" | -h | --help | help)
    usage ;;
  *)
    usage >&2
    exit 1 ;;
esac
