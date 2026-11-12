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
  # The greeter's session with this computer's keyboard, hyprctl found without PATH, and
  # the system's cursors (greetd's environment has no XCURSOR_PATH, and libXcursor's own
  # path doesn't reach the system profile).
  greeterSession = pkgs.runCommand "nyx-greeter-hyprland.lua" { } ''
    sed -e 's/kb_layout = "us"/kb_layout = "${config.services.xserver.xkb.layout}"/' \
      -e 's|; hyprctl eval|; ${config.programs.hyprland.package}/bin/hyprctl eval|' \
      -e 's|^hl.env("XCURSOR_SIZE", "24")$|&\nhl.env("XCURSOR_PATH", "/run/current-system/sw/share/icons")|' \
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
        sansSerif = [ "Inter" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # Umbra, the suite's icon theme (in Nyx Dark's colours), over Adwaita's standard
    # symbolic icons, which fill in what Umbra doesn't draw.
    environment.systemPackages = [
      nyxPkgs.umbra-icons
      pkgs.adwaita-icon-theme
      # GTK 3 windows' theme (and GTK 4's where Nyx's stylesheet doesn't reach), as on
      # Omarchy; nyx-themed picks adw-gtk3 or adw-gtk3-dark for the theme's appearance.
      pkgs.adw-gtk3
      # The dock, Control Center, notifications and Home start apps with gtk-launch, as on
      # Omarchy; only that command, not the rest of GTK 3's tools.
      (pkgs.runCommand "gtk-launch" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.gtk3}/bin/gtk-launch $out/bin/gtk-launch
      '')
    ];
    # Every account's default; a choice in Settings (the user's own dconf) wins, and
    # `gsettings reset` goes back to these. Inter is the suite's font (the Nyx themes'
    # own); cursor size is the reference desktop's (docs/audit/desktop-defaults.md).
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            icon-theme = "Umbra";
            gtk-theme = "adw-gtk3-dark";
            font-name = "Inter 11";
            document-font-name = "Inter 12";
            monospace-font-name = "JetBrainsMono Nerd Font 11";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        }
      ];
    };
    # Adwaita's pointer, as on the reference desktop: Hyprland, Qt and X11 apps load the
    # `default` cursor theme, which on Arch inherits Adwaita and on NixOS doesn't exist
    # until this makes it (else Hyprland draws its built-in fallback).
    xdg.icons.fallbackCursorThemes = [ "Adwaita" ];
    environment.etc."xdg/gtk-3.0/settings.ini".text =
      "[Settings]\ngtk-icon-theme-name=Umbra\ngtk-theme-name=adw-gtk3-dark\n";
    environment.etc."xdg/gtk-4.0/settings.ini".text = "[Settings]\ngtk-icon-theme-name=Umbra\n";
    # Quickshell reads no GTK setting: nyx-shell-qs (the OSD, the Control Center's
    # panel, the window menu) is told the theme, else it has only hicolor.
    systemd.user.services.nyx-shell-qs = lib.mkIf config.nyx.shell.enable {
      environment.QS_ICON_THEME = "Umbra";
      # Qt keeps compiled QML by path and modification time; the components load from
      # /run/current-system, the same path every generation, with the store's fixed
      # mtime, so an update kept running the last generation's QML.
      environment.QML_DISABLE_DISK_CACHE = "1";
      # The components (the bar, dock, Control Center…) are files in the system profile,
      # not part of this unit: restart when they change, else a switch leaves the old QML
      # running.
      restartTriggers = [ config.system.path ];
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # The login screen has the lock screen's wallpaper (N, Y and X stacked on the right),
    # undarkened, as the lock screen shows it.
    environment.etc."nyx-greeter/config.toml".text = ''
      theme = "${loginTheme}"
      ${lib.optionalString (nyxPkgs.nyx-wallpapers.passthru.locks ? ${loginTheme}) ''
        wallpaper = "${nyxPkgs.nyx-wallpapers.passthru.locks.${loginTheme}}"
        dim = 0.0
      ''}
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
