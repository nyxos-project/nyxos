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
  # The example on real hardware: an AMD and an Intel laptop, each with NVIDIA graphics
  # beside the processor's (nouveau; NVIDIA's own driver isn't offered at install). A real
  # computer's system needs what the example (a machine with no hardware of its own)
  # doesn't: microcode, firmware updates, the TPM tools, its graphics. Without them on the
  # USB, an offline install falls back to building compilers from source, and fails.
  onHardware =
    hardware:
    (nyxos.nixosConfigurations.example.extendModules {
      modules = [ { nyxos.hardware = hardware; } ];
    }).config;
  systems = [
    example
    (onHardware {
      cpu = "amd";
      battery = true;
      bluetooth = true;
      gpus = [
        {
          vendor = "amd";
          bus = "PCI:101:0:0";
        }
        {
          vendor = "nvidia";
          bus = "PCI:1:0:0";
        }
      ];
    })
    (onHardware {
      cpu = "intel";
      battery = true;
      bluetooth = true;
      gpus = [
        {
          vendor = "intel";
          bus = "PCI:0:2:0";
        }
        {
          vendor = "nvidia";
          bus = "PCI:1:0:0";
        }
      ];
    })
  ];
  # What building a machine's own pieces needs (its /etc, units, initrd, account and home
  # files differ from the example's): each one's build inputs, so an install builds them
  # without the network.
  buildInputs = map (d: d.inputDerivation or d) (
    lib.concatMap (
      c:
      [
        c.system.build.toplevel
        c.system.build.etc
        c.system.build.initialRamdisk
        c.system.path
        c.environment.etc."systemd/system".source
        c.environment.etc."systemd/user".source
        c.environment.etc."udev/rules.d".source
        c.environment.etc."udev/hwdb.bin".source
        c.environment.etc.hosts.source
      ]
      ++ map (u: u.unit) (lib.attrValues c.systemd.units)
      ++ map (u: u.unit) (lib.attrValues c.systemd.user.units)
      ++ lib.mapAttrsToList (_: h: h.home.activationPackage) c.home-manager.users
    ) systems
  );
  # cage draws at one pixel per pixel, so on a dense laptop panel the installer is small:
  # scale each screen by its density first (from its size in millimetres), then start it.
  installerSession = pkgs.writeShellScript "nyx-installer-session" ''
    ${lib.getExe pkgs.wlr-randr} --json |
      ${lib.getExe pkgs.jq} -r '.[] | select(.enabled) | [.name, ((.modes[] | select(.current)) // .modes[0]).width, .physical_size.width] | @tsv' |
      while IFS=$'\t' read -r name px mm; do
        [ "''${mm:-0}" -gt 0 ] || continue
        dpi=$(( px * 254 / (mm * 10) ))
        if [ "$dpi" -ge 250 ]; then scale=2
        elif [ "$dpi" -ge 175 ]; then scale=1.5
        elif [ "$dpi" -ge 140 ]; then scale=1.25
        else continue; fi
        ${lib.getExe pkgs.wlr-randr} --output "$name" --scale "$scale" || true
      done
    exec ${lib.getExe nyxPkgs.nyx-installer}
  '';
in
{
  imports = [
    ./live-image.nix
    ./boot-menu.nix
    ../modules/nixos/release.nix
    # For testing in Incus; it waits for Incus's share and does nothing elsewhere.
    "${modulesPath}/virtualisation/incus-agent.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  virtualisation.incus.agent.enable = true;
  # NyxOS installs on Btrfs; ZFS only makes the image bigger.
  boot.supportedFilesystems.zfs = lib.mkForce false;
  networking.hostName = "nyxos-live";

  nyxos.liveImage = {
    storeContents =
      map (c: c.system.build.toplevel) systems
      ++ [
        # The patched nixpkgs a machine's system is built from.
        nyxos.lib.nixosSource
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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.systemPackages = [
    nyxPkgs.nyx-installer
    pkgs.adwaita-icon-theme
    # lspci, for the hardware report the installer saves when an install fails.
    pkgs.pciutils
    # For testing the installer in a VM (keys sent from the host).
    pkgs.ydotool
  ];

  # The installer, full screen, as root (it partitions disks) as soon as the USB starts.
  # The text consoles (Ctrl+Alt+F2…) still have a shell.
  services.cage = {
    enable = true;
    user = "root";
    program = installerSession;
    # -s: Ctrl+Alt+F2 (Fn as well on many laptops) still reaches a text console.
    extraArguments = [
      "-d"
      "-s"
    ];
    environment = {
      # Cairo draws the same on any graphics, before a machine's own driver is set up.
      GSK_RENDERER = "cairo";
      # It looks like the system it installs.
      NYX_INSTALLER_THEME = example.nyxos.theme.system;
      # Choosing a keyboard starts the installer again in that layout (cage reads it only
      # when it starts), with the first page's choices kept in /run/nyx-installer.
      NYX_INSTALLER_RESTART = "1";
      NYX_INSTALLER_FULLSCREEN = "1";
    };
  };
  systemd.services.cage-tty1.serviceConfig = {
    EnvironmentFile = "-/run/nyx-installer/keyboard.env";
    # nyx-installer's choices::RESTART_FOR_KEYBOARD.
    RestartForceExitStatus = "75";
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
    "rd.systemd.show_status=false"
    "systemd.show_status=false"
    "vt.global_cursor_default=0"
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
