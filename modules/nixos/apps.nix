# Base tier: Nyx components every NyxOS install ships. Options come from nyx-packages.
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  environment.systemPackages = [ inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.nyx-cli ];

  nyx = {
    icons = {
      enable = lib.mkDefault true;
      followTheme = lib.mkDefault true;
    };
    accounts.enable = lib.mkDefault true;
    notepad.enable = lib.mkDefault true;
    calculator.enable = lib.mkDefault true;
    archive.enable = lib.mkDefault true;
    files.enable = lib.mkDefault true;
    capture.enable = lib.mkDefault true;
    photos.enable = lib.mkDefault true;
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
    locker.enable = lib.mkDefault true;
  };

  # Without a suite theme file Nyx apps fall back to Omarchy's theme, then Tokyo Night.
  # Seed the theme a new user starts with (the distribution's, or the administrator's
  # from the overrides layer) once; the file stays the user's to change.
  system.userActivationScripts.nyx-theme-default = ''
    if [ ! -e "$HOME/.config/nyx/theme.toml" ]; then
      theme=$(${nyxPkgs.nyx-system}/bin/nyx-system config get appearance theme --below-user || echo nyx-dark)
      mkdir -p "$HOME/.config/nyx"
      printf 'mode = "theme"\ntheme = "%s"\n' "$theme" > "$HOME/.config/nyx/theme.toml"
    fi
  '';
}
