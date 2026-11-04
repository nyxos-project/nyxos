# The NyxOS live USB: boots on UEFI and installs NyxOS without the network. It carries
# a whole NyxOS system (what the installer installs, built ahead) and every source the
# machine's flake needs, so an install only builds the few files that are the machine's
# own (its hardware, name and person).
{
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
let
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
  # A flake's source and its inputs', all the way down.
  sources = flake: [ flake.outPath ] ++ lib.concatMap sources (lib.attrValues (flake.inputs or { }));
  nyxos = inputs.self;
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    # For testing in Incus; it waits for Incus's share and does nothing elsewhere.
    "${modulesPath}/virtualisation/incus-agent.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  virtualisation.incus.agent.enable = true;
  # NyxOS installs on Btrfs; ZFS only makes the image bigger.
  boot.supportedFilesystems.zfs = lib.mkForce false;
  networking.hostName = "nyxos-live";
  system.nixos.distroName = "NyxOS";

  isoImage = {
    volumeID = "NYXOS";
    edition = "installer";
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 15";
    storeContents = [ nyxos.checks.x86_64-linux.installed ] ++ lib.unique (sources nyxos);
  };
  image.baseName = lib.mkForce "nyxos-installer";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.systemPackages = [ nyxPkgs.nyx-installer ];
  # Where the installer finds the NyxOS it installs.
  environment.etc."nyxos/source".text = "${nyxos}\n";
}
