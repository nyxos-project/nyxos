{
  config,
  lib,
  osConfig,
  inputs,
  pkgs,
  theme,
  ...
}:
let
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Foot reads the theme's colours from a file nyx-themed writes; write it before the
  # first terminal opens.
  home.activation.nyxTheme = lib.mkIf osConfig.nyx.themes.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "${config.xdg.configHome}/foot/nyx-theme.ini" ]; then
        run ${nyxPkgs.nyx-system}/bin/nyx-themed --once || true
      fi
    ''
  );

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "${theme.font.mono}:size=11";
        pad = "12x12";
        # The user's Nyx theme's colours, from nyx-themed.
        include = "${config.xdg.configHome}/foot/nyx-theme.ini";
      };
      scrollback.lines = 10000;
      mouse.hide-when-typing = "yes";
    };
  };
}
