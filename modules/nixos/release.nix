# NyxOS's name and version (VERSION) where the system says what it is: /etc/os-release
# (Settings' About), /etc/lsb-release, generation and boot entry names. NixOS's own
# release stays in BUILD_ID; the ID stays "nixos" for tools that check it. Installed
# systems and the live USB both import this.
{ lib, config, ... }:
let
  version = lib.fileContents ../../VERSION;
  home = "https://github.com/nyxos-project/nyxos";
in
{
  system.nixos = {
    distroName = "NyxOS";
    vendorName = "NyxOS";
    label = version;
    extraOSReleaseArgs = {
      VERSION = version;
      VERSION_ID = version;
      VERSION_CODENAME = "";
      PRETTY_NAME = "NyxOS ${version}";
      BUILD_ID = config.system.nixos.version;
      HOME_URL = home;
      DOCUMENTATION_URL = home;
      SUPPORT_URL = "${home}/issues";
      BUG_REPORT_URL = "${home}/issues";
      VENDOR_URL = home;
    };
    extraLSBReleaseArgs = {
      DISTRIB_RELEASE = version;
      DISTRIB_CODENAME = "";
      DISTRIB_DESCRIPTION = "NyxOS ${version}";
    };
  };
}
