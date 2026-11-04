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
in
{
  options.nyxos.desktop.autoLogin = lib.mkEnableOption "logging the primary user straight into Hyprland at boot";

  config = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      # With workspace swipe wrap-around, which Nyx Settings' Loop around uses.
      package = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    };

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    security.polkit.enable = true;
    hardware.graphics.enable = true;
    hardware.bluetooth.enable = true;
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

    # Temporary login path until Nyx Greeter exists.
    services.greetd = {
      enable = true;
      settings = {
        default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd '${session}'";
        initial_session = lib.mkIf cfg.autoLogin {
          user = config.nyxos.user.name;
          command = session;
        };
      };
    };
  };
}
