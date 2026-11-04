# NyxOS distribution defaults. Hosts import this and set `nyxos.*`.
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.nyxos;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nyx-packages.nixosModules.default
    ./apps.nix
    ./base.nix
    ./boot.nix
    ./network.nix
    ./audio.nix
    ./desktop.nix
    ./shell.nix
    ./packages.nix
    ./overrides.nix
  ];

  options.nyxos.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Login name of the primary user.";
    };
    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Full name of the primary user.";
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys allowed to log in as the primary user.";
    };
    initialPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Password set when the account is first created.";
    };
  };

  config.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-backup";
    users.${cfg.user.name} = {
      imports = [ ../home ];
      home.stateVersion = config.system.stateVersion;
    };
  };
}
