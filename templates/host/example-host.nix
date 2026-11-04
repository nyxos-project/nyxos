# For the flake check only: host.nix as the installer fills it in.
{ ... }:
{
  system.stateVersion = "26.05";
  networking.hostName = "example";
  nyx.system.host = "example";

  nyxos = {
    user = {
      name = "amy";
      description = "Amy Example";
    };
    snapshots.enable = true;
    boot.windows = false;
  };
}
