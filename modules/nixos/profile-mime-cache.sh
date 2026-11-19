# Nix links the desktop entries into each profile generation. GLib reads
# mimeinfo.cache for their associations, and the immutable profile has no cache.
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
state_home=${XDG_STATE_HOME:-$HOME/.local/state}
applications=$data_home/applications
mkdir -p "$applications"

# Stage on the same filesystem for an atomic replacement. The applications
# directory can contain local launchers, so those take precedence over Nix.
stage=$(mktemp -d "$data_home/.nyx-mime.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
for source in "$applications" "$HOME/.nix-profile/share/applications" "$state_home/nix/profile/share/applications"; do
  [[ -d $source ]] || continue
  while IFS= read -r -d '' file; do
    id=${file#"$source"/}
    id=${id//\//-}
    [[ -L $stage/$id ]] || ln -s -- "$file" "$stage/$id"
  done < <(find -L "$source/" -type f -name '*.desktop' -print0)
done

update-desktop-database "$stage"
if ! cmp -s "$stage/mimeinfo.cache" "$applications/mimeinfo.cache"; then
  mv -fT -- "$stage/mimeinfo.cache" "$applications/mimeinfo.cache"
fi
