# The boot splash: Nyx Plymouth in the boot theme (the system theme unless set on its
# own), with the kernel and udev quiet so it isn't drawn over.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  boot.plymouth = {
    enable = lib.mkDefault true;
    themePackages = [ nyxPkgs.nyx-plymouth ];
    theme = config.nyxos.theme.boot;
  };
  boot.consoleLogLevel = lib.mkDefault 3;
  boot.initrd.verbose = lib.mkDefault false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];
}
