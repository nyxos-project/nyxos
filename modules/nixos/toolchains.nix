# Toolchains a person installs for their projects with mise and uv (Node, Python, Go,
# Zig, Python tools…). Those come as prebuilt Linux programs that expect a dynamic linker
# and libraries where other distributions keep them; nix-ld puts them there, so they run.
# NyxOS's own packages don't need it. What NyxOS installs stays NyxOS's to update; what
# mise and uv install is the user's, and `nyx update tools` updates it as the user.
{
  lib,
  options,
  pkgs,
  ...
}:
{
  programs.nix-ld = {
    enable = lib.mkDefault true;
    # NixOS's set (zlib, openssl, curl, the C++ runtime…) and what Node's and Python's
    # native modules commonly link.
    libraries =
      options.programs.nix-ld.libraries.default
      ++ (with pkgs; [
        expat
        gmp
        icu
        libffi
        ncurses
        readline
        sqlite
      ]);
  };
}
