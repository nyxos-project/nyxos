{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.nyxos.desktop;
  session = "uwsm start hyprland-uwsm.desktop";
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
  greeter = nyxPkgs.nyx-greeter;
  loginTheme = config.nyxos.theme.login;
  # The greeter's session with this computer's keyboard, and hyprctl found without PATH.
  greeterSession = pkgs.runCommand "nyx-greeter-hyprland.lua" { } ''
    sed -e 's/kb_layout = "us"/kb_layout = "${config.services.xserver.xkb.layout}"/' \
      -e 's|; hyprctl eval|; ${config.programs.hyprland.package}/bin/hyprctl eval|' \
      ${greeter}/share/nyx-greeter/hyprland.lua > $out
  '';
in
{
  options.nyxos.desktop.autoLogin = lib.mkEnableOption "logging the primary user straight into Hyprland at boot";

  config = {
    # The lock screen (its PAM service); the user's config is in modules/home/lock.nix.
    programs.hyprlock.enable = lib.mkDefault true;

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      # With workspace swipe wrap-around, which Nyx Settings' Loop around uses.
      package = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    };

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    security.polkit.enable = true;
    hardware.graphics.enable = true;
    services.udisks2.enable = true;

    # The Incus VM profile is built on the minimal profile, which turns these off.
    xdg = {
      autostart.enable = true;
      icons.enable = true;
      mime.enable = true;
      sounds.enable = true;
    };
    documentation.man.enable = true;

    fonts = {
      packages = with pkgs; [
        inter
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
      ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Inter" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # GTK's standard symbolic icons; without them apps show missing-image placeholders.
    environment.systemPackages = [ pkgs.adwaita-icon-theme ];

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.etc."nyx-greeter/config.toml".text = ''
      theme = "${loginTheme}"
      ${lib.optionalString (nyxPkgs.nyx-wallpapers.passthru.defaults ? ${loginTheme}) ''wallpaper = "${nyxPkgs.nyx-wallpapers.passthru.defaults.${loginTheme}}"''}
      mark = "${greeter}/share/nyx-greeter/mark.png"
      default_session = "hyprland-uwsm"
      style = "${config.nyxos.signinStyle}"
    '';
    # Who signed in last, and with which session.
    systemd.tmpfiles.rules = [ "d /var/cache/nyx-greeter 0755 greeter greeter -" ];
    # A home of its own, for GTK's and fontconfig's caches (greetd gives it /var/empty).
    users.users.greeter = lib.mkIf config.services.greetd.enable {
      home = "/var/lib/nyx-greeter";
      createHome = true;
    };

    # Nyx Greeter, in its own bare Hyprland session, in the login theme.
    services.greetd = {
      enable = true;
      settings = {
        # start-hyprland is the watchdog Hyprland expects (it warns on screen without it).
        default_session.command = "${lib.getExe' config.programs.hyprland.package "start-hyprland"} -- --config ${greeterSession}";
        initial_session = lib.mkIf cfg.autoLogin {
          user = config.nyxos.user.name;
          command = session;
        };
      };
    };
  };
}
