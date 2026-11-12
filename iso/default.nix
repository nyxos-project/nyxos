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
  example = nyxos.nixosConfigurations.example.config;
  # What building a machine's own pieces needs (its /etc, units, initrd, account and home
  # files differ from the example's): each one's build inputs, so an install builds them
  # without the network.
  buildInputs = map (d: d.inputDerivation or d) (
    [
      example.system.build.toplevel
      example.system.build.etc
      example.system.build.initialRamdisk
      example.system.path
      example.environment.etc."systemd/system".source
      example.environment.etc."systemd/user".source
      example.environment.etc."udev/rules.d".source
      example.environment.etc."udev/hwdb.bin".source
      example.environment.etc.hosts.source
    ]
    ++ map (u: u.unit) (lib.attrValues example.systemd.units)
    ++ map (u: u.unit) (lib.attrValues example.systemd.user.units)
    ++ lib.mapAttrsToList (_: h: h.home.activationPackage) example.home-manager.users
  );
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ./boot-menu.nix
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
    storeContents = [
      example.system.build.toplevel
      pkgs.stdenv
      pkgs.stdenvNoCC
      # Outputs the machine's pieces build from that nothing installed keeps
      # (scripts/offline-check finds them).
      pkgs.kmod.dev
      pkgs.libxslt.bin
      pkgs.getconf
      pkgs.emptyDirectory
      pkgs.libfido2
    ]
    ++ buildInputs
    ++ lib.unique (sources nyxos);
  };
  image.baseName = lib.mkForce "nyxos-installer";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.systemPackages = [
    nyxPkgs.nyx-installer
    pkgs.adwaita-icon-theme
    # For testing the installer in a VM (keys sent from the host).
    pkgs.ydotool
  ];

  # The installer, full screen, as root (it partitions disks) as soon as the USB starts.
  # The text consoles (Ctrl+Alt+F2…) still have a shell.
  services.cage = {
    enable = true;
    user = "root";
    program = lib.getExe nyxPkgs.nyx-installer;
    extraArguments = [ "-d" ];
    environment = {
      # Cairo draws the same on any graphics, before a machine's own driver is set up.
      GSK_RENDERER = "cairo";
      # It looks like the system it installs.
      NYX_INSTALLER_THEME = example.nyxos.theme.system;
    };
  };
  hardware.graphics.enable = true;
  # A quiet boot behind Nyx Plymouth, as on an installed NyxOS (modules/nixos/boot.nix),
  # in the boot theme NyxOS installs. The text consoles still show what's wrong.
  boot.plymouth = {
    enable = true;
    themePackages = [ nyxPkgs.nyx-plymouth ];
    theme = example.nyxos.theme.boot;
  };
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];
  fonts = {
    packages = [
      pkgs.inter
      nyxPkgs.nyx-fonts
    ];
    # The minimal profile turns fontconfig off; without it GTK can't find Inter.
    fontconfig = {
      enable = lib.mkForce true;
      defaultFonts.sansSerif = [ "Inter" ];
    };
  };
  environment.pathsToLink = [ "/share/icons" ];
  # Where the installer finds the NyxOS it installs.
  environment.etc."nyxos/source".text = "${nyxos}\n";
}
