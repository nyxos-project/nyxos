{
  config,
  lib,
  inputs,
  ...
}:
let
  user = config.nyxos.user;
in
{
  # The name in /etc/os-release and the boot menu; the ID stays "nixos" for tools that
  # check it.
  system.nixos.distroName = "NyxOS";

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      # Nyx packages built by CI.
      extra-substituters = [ "https://nyxos.cachix.org" ];
      extra-trusted-public-keys = [ "nyxos.cachix.org-1:Kq51mQ7B9BhkeatzFfCiIkz6FoeaRFkLFtpkK2iJMPQ=" ];
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Compressed swap in RAM, so a memory spike slows things down instead of
  # triggering the OOM killer.
  zramSwap.enable = lib.mkDefault true;

  # Older generations stay bootable from the boot menu.
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 20;

  time.timeZone = lib.mkDefault "America/Chicago";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  users.users.${user.name} = {
    isNormalUser = true;
    inherit (user) description initialPassword;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    openssh.authorizedKeys.keys = user.authorizedKeys;
  };

  # Configuration layers: distribution defaults live in this flake, system overrides
  # under /etc/nyxos/overrides, user settings under ~/.config/nyx.
  systemd.tmpfiles.rules = [ "d /etc/nyxos/overrides 0755 root root -" ];
}
