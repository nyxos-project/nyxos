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
  # The example on common real hardware. A real computer's system needs what the example (a
  # machine with no hardware of its own) doesn't: microcode, firmware updates, the TPM tools,
  # its graphics drivers, power management on a laptop. Without them on the USB, an offline
  # install falls back to building compilers from source, and fails. Laptops and desktops,
  # AMD and Intel processors, AMD, Intel and NVIDIA graphics (nouveau; NVIDIA's own driver
  # isn't offered at install), alone and together: they share almost everything.
  gpu = vendor: bus: { inherit vendor bus; };
  amdGpu = gpu "amd" "PCI:101:0:0";
  intelGpu = gpu "intel" "PCI:0:2:0";
  nvidiaGpu = gpu "nvidia" "PCI:1:0:0";
  onHardware =
    hardware:
    (nyxos.nixosConfigurations.example.extendModules {
      modules = [
        {
          nyxos.hardware = {
            bluetooth = true;
          }
          // hardware;
        }
      ];
    }).config;
  systems = [
    example
    # Laptops: the processor's graphics, with or without NVIDIA's beside.
    (onHardware {
      cpu = "amd";
      battery = true;
      gpus = [
        amdGpu
        nvidiaGpu
      ];
    })
    (onHardware {
      cpu = "amd";
      battery = true;
      gpus = [ amdGpu ];
    })
    (onHardware {
      cpu = "intel";
      battery = true;
      gpus = [
        intelGpu
        nvidiaGpu
      ];
    })
    (onHardware {
      cpu = "intel";
      battery = true;
      gpus = [ intelGpu ];
    })
    # Desktops: a graphics card, or the processor's own.
    (onHardware {
      cpu = "amd";
      gpus = [ nvidiaGpu ];
    })
    (onHardware {
      cpu = "amd";
      gpus = [ amdGpu ];
    })
    (onHardware {
      cpu = "intel";
      gpus = [ nvidiaGpu ];
    })
    (onHardware {
      cpu = "intel";
      gpus = [ amdGpu ];
    })
    (onHardware {
      cpu = "intel";
      gpus = [ intelGpu ];
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
      # What each system puts before its initrd (the processor's microcode): the boot
      # loader joins it on, so nothing the system keeps refers to it, and without it here an
      # install rebuilds it (and libarchive, and the compilers under that) from source.
      ++ lib.concatMap (c: c.boot.initrd.prepend) systems
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
  # With a network (a cable, or Wi-Fi set up with nmtui), what this USB doesn't carry for a
  # computer is downloaded from the binary caches instead of compiled: NixOS's and NyxOS's.
  # Without one, they're skipped quickly.
  nix.settings.extra-substituters = [ "https://nyxos.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "nyxos.cachix.org-1:Kq51mQ7B9BhkeatzFfCiIkz6FoeaRFkLFtpkK2iJMPQ="
  ];
  nix.settings.connect-timeout = 5;
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
      # The pointer: a system service gets no cursor theme, so cage drew none.
      XCURSOR_THEME = "Adwaita";
      XCURSOR_PATH = "/run/current-system/sw/share/icons";
    };
  };
  systemd.services.cage-tty1.serviceConfig = {
    # The installer starts on the computer's own graphics driver, not the firmware's
    # framebuffer (simpledrm) the kernel shows first: started on that, cage keeps the
    # window at the firmware screen's size when the real driver takes over (amdgpu came
    # 10 seconds after it on a Zephyrus G16), and the screen flickers as it does.
    ExecStartPre = pkgs.writeShellScript "wait-for-graphics" ''
      for _ in $(seq 60); do
        for card in /sys/class/drm/card[0-9]*; do
          [ -e "$card/device/driver" ] || continue
          driver=$(basename "$(readlink "$card/device/driver")")
          [ "$driver" != simple-framebuffer ] && exit 0
        done
        sleep 0.5
      done
    '';
    EnvironmentFile = "-/run/nyx-installer/keyboard.env";
    # nyx-installer's choices::RESTART_FOR_KEYBOARD.
    RestartForceExitStatus = "75";
  };
  hardware.graphics.enable = true;
  # The CPU's latest microcode, loaded first (live-image.nix puts it before the initrd):
  # fixes for errata the kernel otherwise reports on screen as it starts.
  hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;
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
