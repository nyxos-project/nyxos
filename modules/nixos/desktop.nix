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
    # Screen readers speak through speech-dispatcher; espeak's mbrola voices are another
    # 645 MB.
    services.speechd.package = pkgs.speechd.override {
      espeak = pkgs.espeak-ng.override { mbrolaSupport = false; };
    };
    hardware.graphics.enable = true;
    services.udisks2.enable = true;
    # Trash, network places, phones and cameras in Files and the file dialogs.
    services.gvfs.enable = true;

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
        adwaita-fonts
        inter
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
      ];
      fontconfig.defaultFonts = {
        sansSerif = [ "Adwaita Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # Umbra, the suite's icon theme (in Nyx Dark's colours), over Adwaita's standard
    # symbolic icons, which fill in what Umbra doesn't draw.
    environment.systemPackages = [
      nyxPkgs.umbra-icons
      pkgs.adwaita-icon-theme
      # The dock, Control Center, notifications and Home start apps with gtk-launch, as on
      # Omarchy; only that command, not the rest of GTK 3's tools.
      (pkgs.runCommand "gtk-launch" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.gtk3}/bin/gtk-launch $out/bin/gtk-launch
      '')
    ];
    # Every account's default; a choice in Settings (the user's own dconf) wins, and
    # `gsettings reset` goes back to these. Fonts and cursor size are the reference
    # desktop's (docs/audit/desktop-defaults.md).
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            icon-theme = "Umbra";
            font-name = "Adwaita Sans 11";
            document-font-name = "Adwaita Sans 12";
            monospace-font-name = "JetBrainsMono Nerd Font 11";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        }
      ];
    };
    environment.etc."xdg/gtk-3.0/settings.ini".text = "[Settings]\ngtk-icon-theme-name=Umbra\n";
    environment.etc."xdg/gtk-4.0/settings.ini".text = "[Settings]\ngtk-icon-theme-name=Umbra\n";

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.etc."nyx-greeter/config.toml".text = ''
      theme = "${loginTheme}"
      ${lib.optionalString (nyxPkgs.nyx-wallpapers.passthru.defaults ? ${loginTheme})
        ''wallpaper = "${nyxPkgs.nyx-wallpapers.passthru.defaults.${loginTheme}}"''
      }
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
