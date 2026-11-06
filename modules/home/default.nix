# Per-user defaults for the primary user.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
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

  # NyxOS's skills in every coding agent's skills folder (as links, so they follow
  # updates); `nyx agent` links them again before it starts one.
  home.activation.nyxAgentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.nyx-cli}/bin/nyx agent skills
  '';
}
