# Per-user defaults for the primary user.
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
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

  # The system theme's colours, for what's built before nyx-themed writes the user's own.
  _module.args.theme = import ../../themes {
    inherit lib;
    inherit (inputs.nyx-packages.inputs) nyx-design;
  } osConfig.nyxos.theme.system;

  xdg.enable = true;

  # Without user-dirs.dirs GLib knows only Desktop, so Files' Places would leave out
  # the rest. Desktop is made too because Places lists it.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    publicShare = null;
    templates = null;
    extraConfig.GAMES = "${config.home.homeDirectory}/Games";
  };

  # Where `uv tool install`, pipx and others put the commands they install.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # uuctl picks units through a dmenu-style menu NyxOS doesn't have: in the app drawer
  # it did nothing. (Not uwsm without it: a new uwsm restarts its units and ends the
  # session on switch.)
  xdg.dataFile."applications/uuctl.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=uuctl
    Exec=uuctl
    NoDisplay=true
  '';

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
