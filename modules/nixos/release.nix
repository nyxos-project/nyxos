# NyxOS's name, version (VERSION) and codename (CODENAME, NixOS's library carries it:
# flake.nix) wherever the system says what it is: /etc/os-release (Settings' About),
# /etc/lsb-release, nixos-version, generation and boot entry names. The ID is nyxos, like
# NixOS for tools that know NixOS (ID_LIKE). Installed systems and the live USB both
# import this.
{ lib, ... }:
let
  version = lib.fileContents ../../VERSION;
  codename = lib.fileContents ../../CODENAME;
  home = "https://github.com/nyxos-project/nyxos";
in
{
  system.nixos = {
    distroId = "nyxos";
    distroName = "NyxOS";
    vendorId = "nyxos";
    vendorName = "NyxOS";
    inherit version;
    label = version;
    extraOSReleaseArgs = {
      ID_LIKE = "nixos";
      VERSION = "${version} (${codename})";
      VERSION_ID = version;
      VERSION_CODENAME = lib.toLower codename;
      PRETTY_NAME = "NyxOS ${version}";
      CPE_NAME = "cpe:/o:nyxos:nyxos:${version}";
      BUILD_ID = "";
      LOGO = "";
      SUPPORT_END = "";
      ANSI_COLOR = "0;38;2;137;180;250";
      HOME_URL = home;
      DOCUMENTATION_URL = home;
      SUPPORT_URL = "${home}/issues";
      BUG_REPORT_URL = "${home}/issues";
      VENDOR_URL = home;
    };
    extraLSBReleaseArgs = {
      LSB_VERSION = "${version} (${codename})";
      DISTRIB_RELEASE = version;
      DISTRIB_CODENAME = lib.toLower codename;
      DISTRIB_DESCRIPTION = "NyxOS ${version} (${codename})";
    };
  };

  # NixOS's own manual, its launcher entry and nixos-help: NyxOS has its own help.
  documentation.nixos.enable = false;

  # The keys that sign releases: `nyx update` moves a stable machine only to a revision
  # with a known-good tag one of them signed.
  environment.etc."nyxos/release-signers".source = ../../release-signers;
}
