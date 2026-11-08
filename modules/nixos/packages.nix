{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # The tools NyxOS packages from pins (pkgs/tools): the channel's, or a newer one
  # `nyx update NAME` put in the overrides layer.
  pins = import ../../pkgs/tools/pins.nix {
    inherit lib;
    overrides = inputs.nyxos-overrides;
  };
  installed = map lib.getName config.environment.systemPackages;
in
{
  # The coding agents and the packages the catalog offers that nixpkgs doesn't have,
  # under the names it uses.
  nixpkgs.overlays = [ (import ../../pkgs/tools/overlay.nix { inherit pins; }) ];

  # What `nyx update` compares with the channel: each tool's pin as built, and whether
  # this system installs it.
  environment.etc."nyxos/tools.json".text = builtins.toJSON (
    lib.mapAttrs (
      name: pin:
      {
        inherit (pin)
          name
          version
          recipe
          aliases
          ;
        installed = lib.elem name installed;
      }
      // lib.optionalAttrs (pin ? coreVersion) { inherit (pin) coreVersion; }
    ) pins
  );

  environment.systemPackages = with pkgs; [
    bat
    btop
    curl
    eza
    fd
    file
    git
    helix
    jq
    pciutils
    ripgrep
    rsync
    unzip
    usbutils
    wget

    grim
    wl-clipboard
  ];
}
