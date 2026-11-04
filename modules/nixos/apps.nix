# Base tier: Nyx components every NyxOS install ships. Options come from nyx-packages.
{
  lib,
  pkgs,
  inputs,
  ...
}:
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
    # The desktop shell.
    bar.enable = lib.mkDefault true;
    glimpse.enable = lib.mkDefault true;
    notification-center.enable = lib.mkDefault true;
    dock.enable = lib.mkDefault true;
    control-center.enable = lib.mkDefault true;
  };

  # Without a suite theme file Nyx apps fall back to Omarchy's theme, then Tokyo Night.
  # Seed Nyx Dark once; the file stays the user's to change.
  system.userActivationScripts.nyx-theme-default = ''
    if [ ! -e "$HOME/.config/nyx/theme.toml" ]; then
      mkdir -p "$HOME/.config/nyx"
      printf 'mode = "theme"\ntheme = "nyx-dark"\n' > "$HOME/.config/nyx/theme.toml"
    fi
  '';
}
