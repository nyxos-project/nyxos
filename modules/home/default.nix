# Per-user defaults for the primary user.
{ config, lib, ... }:
{
  imports = [
    ./foot.nix
    ./zsh.nix
    ./helix.nix
    ./herdr.nix
    ./hyprland.nix
    ./lock.nix
    ./power.nix
  ];

  _module.args.theme = import ../../themes/nyx-dark.nix;

  xdg.enable = true;

  # ~/.config/nyx belongs to the user; Home Manager only makes sure it exists.
  home.activation.nyxUserConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.configHome}/nyx"
  '';
}
