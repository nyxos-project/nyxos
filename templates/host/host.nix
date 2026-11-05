# This computer's own NyxOS settings, written by the installer. Settings, Welcome and the
# Store keep their changes in /etc/nyxos/overrides instead.
{ ... }:
{
  system.stateVersion = "26.05";
  networking.hostName = "HOSTNAME";
  nyx.system.host = "HOSTNAME";

  nyxos = {
    user = {
      name = "USERNAME";
      description = "FULL NAME";
    };
    snapshots.enable = true;
  };
}
