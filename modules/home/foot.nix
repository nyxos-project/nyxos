{
  config,
  lib,
  osConfig,
  pkgs,
  theme,
  ...
}:
let
  nyxPkgs = osConfig.nyx.packages;
in
{
  # Foot reads the theme's colours from a file nyx-themed writes; write it before the
  # first terminal opens.
  home.activation.nyxTheme = lib.mkIf osConfig.nyx.themes.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "${config.xdg.configHome}/foot/nyx-theme.ini" ] || [ ! -e "${config.xdg.configHome}/hypr/nyx-hyprlock.conf" ]; then
        run ${nyxPkgs.nyx-system}/bin/nyx-themed --once || true
      fi
    ''
  );

  # Super Enter opens the first terminal in this list (xdg-terminal-exec); Settings →
  # Default Apps changes it, so it's the user's file, seeded once.
  home.packages = [ pkgs.xdg-terminal-exec ];
  home.activation.nyxTerminal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${config.xdg.configHome}/xdg-terminals.list" ]; then
      run sh -c 'printf "foot.desktop\n" > "$1"' _ "${config.xdg.configHome}/xdg-terminals.list"
    fi
  '';

  # One Foot in the launcher: the server and client entries open no window of their own.
  xdg.dataFile =
    lib.genAttrs [ "applications/foot-server.desktop" "applications/footclient.desktop" ]
      (_: {
        text = "[Desktop Entry]\nType=Application\nName=Foot\nNoDisplay=true\n";
      });

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
