# For the flake check and the live USB: host.nix exactly as the installer writes it for an
# encrypted install, so the USB carries what such a machine builds from.
{ config, lib, ... }:
{
  system.stateVersion = "26.05";
  networking.hostName = "example";
  nyx.system.host = "example";
  boot.loader.efi.canTouchEfiVariables = true;

  # The encrypted disk, opened before the system starts.
  boot.initrd.systemd.enable = true;

  # Btrfs with compression; hibernating to the swap file.
  fileSystems = lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_: {
    options = [
      "compress=zstd"
      "noatime"
    ];
  });
  swapDevices = [ { device = "/swap/swapfile"; } ];
  boot.resumeDevice = config.fileSystems."/".device;
  boot.kernelParams = [ "resume_offset=${lib.trim (builtins.readFile ./example-resume-offset)}" ];

  nyxos = {
    user = {
      name = "amy";
      description = "Amy Example";
    };
    snapshots.enable = true;
  };
}
