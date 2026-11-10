# Base tier: Nyx components every NyxOS install ships. Options come from nyx-packages.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
  # Standalone Nyx apps NyxOS used to install for everyone. On a machine installed
  # since they're per user, Welcome puts them in each person's profile instead.
  forEveryone = config.nyxos.standaloneApps == "system";
in
{
  options.nyxos.standaloneApps = lib.mkOption {
    type = lib.types.enum [
      "system"
      "per-user"
    ];
    default = "system";
    description = ''
      Where the standalone Nyx apps NyxOS preinstalls (Notepad, Calculator, Archive,
      Photos) go: "system" installs them for everyone, as NyxOS did before; "per-user"
      leaves them to each person's Nix profile (Welcome offers them, already chosen).
      The installer writes "per-user"; machines installed earlier keep "system" until
      their apps are moved to people's accounts (Settings › Software).
    '';
  };

  config = {
    environment.systemPackages = [
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.nyx-cli
    ];

    # Skills that teach coding agents NyxOS; `nyx agent skills` links them for each agent.
    environment.etc."nyxos/agents/skills".source = ../../agents/skills;

    nyx = {
      icons = {
        enable = lib.mkDefault true;
        followTheme = lib.mkDefault true;
      };
      accounts.enable = lib.mkDefault true;
      notepad.enable = lib.mkDefault forEveryone;
      calculator.enable = lib.mkDefault forEveryone;
      archive.enable = lib.mkDefault forEveryone;
      files.enable = lib.mkDefault true;
      capture.enable = lib.mkDefault true;
      photos.enable = lib.mkDefault forEveryone;
      activity.enable = lib.mkDefault true;
      backup.enable = lib.mkDefault true;
      share.enable = lib.mkDefault true;
      # The desktop shell.
      bar.enable = lib.mkDefault true;
      glimpse.enable = lib.mkDefault true;
      notification-center.enable = lib.mkDefault true;
      dock.enable = lib.mkDefault true;
      control-center.enable = lib.mkDefault true;
      switcher.enable = lib.mkDefault true;
      # Nyx Shell Core and nyx-shell-qs, which draws the OSD, the Control Center's panel,
      # Desktop Widgets and the window menu; window controls need it too.
      shell.enable = lib.mkDefault true;
      settings.enable = lib.mkDefault true;
      wallpapers.enable = lib.mkDefault true;
      store.enable = lib.mkDefault true;
      welcome.enable = lib.mkDefault true;
      # System services: the System Manager and the theme service.
      system = {
        enable = lib.mkDefault true;
        flake = lib.mkDefault "/etc/nyxos/flake";
      };
      themes.enable = lib.mkDefault true;
      # Nyx AI Core: the local model runtime the apps share (starts on first use).
      ai.enable = lib.mkDefault true;
      locker.enable = lib.mkDefault true;
      prompt.enable = lib.mkDefault true;
      # Nyx Connect: upstream Flux's fluxd, shown in Settings › Devices and the Control Center.
      connect.enable = lib.mkDefault true;
    };

    # Flux's own defaults let a paired phone browse the whole home folder and update fluxd
    # from GitHub. On NyxOS, Browse PC starts off (Settings › Devices turns it on) and
    # fluxd comes from the system, so a new user's config.toml says so; fluxd fills in the
    # rest.
    system.userActivationScripts.nyx-connect-defaults = lib.mkIf config.nyx.connect.enable ''
      if [ ! -e "$HOME/.config/flux/config.toml" ]; then
        mkdir -p "$HOME/.config/flux"
        printf 'share_home = false\ncheck_updates = false\n' > "$HOME/.config/flux/config.toml"
      fi
    '';

    # Nyx apps take the system theme from the appearance layers (/etc/nyxos/defaults, under
    # the administrator's overrides) until the user chooses one, so a new default reaches
    # everyone who didn't. A new user's file only says to use an installed theme rather
    # than Omarchy's.
    system.userActivationScripts.nyx-theme-default = ''
      if [ ! -e "$HOME/.config/nyx/theme.toml" ]; then
        mkdir -p "$HOME/.config/nyx"
        printf 'mode = "theme"\n' > "$HOME/.config/nyx/theme.toml"
      fi
    '';
  };
}
