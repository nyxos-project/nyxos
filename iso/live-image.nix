# The NyxOS live USB as an image: the live system (the USB's store as a squashfs under a
# tmpfs, found by its label) and the image itself, started by Limine on UEFI and BIOS,
# from a USB stick or a disc. NyxOS's own, in place of NixOS's installation-cd modules,
# so nothing of NixOS's boot menu (GRUB, syslinux, rEFInd, Memtest86+) comes along.
{
  config,
  lib,
  options,
  pkgs,
  modulesPath,
  ...
}:
let
  cfg = config.nyxos.liveImage;
  version = lib.fileContents ../VERSION;
  # Limine with the El Torito images a disc and a hybrid USB image start from.
  limine = pkgs.limine.override { buildCDs = true; };
  squashfs = pkgs.callPackage "${modulesPath}/../lib/make-squashfs.nix" {
    inherit (cfg) storeContents;
    comp = cfg.squashfsCompression;
  };
  kernel = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";
  initrd = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
  limineConf = pkgs.writeText "limine.conf" cfg.limineConfig;
  graft = f: lib.escapeShellArg "${f.target}=${f.source}";
in
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/installation-device.nix"
  ];

  options.nyxos.liveImage = {
    volumeID = lib.mkOption {
      type = lib.types.strMatching "[A-Z0-9_]{1,32}";
      default = "NYXOS";
      description = "The image's label, which the live system finds it by.";
    };
    storeContents = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      default = [ ];
      description = "What the USB's store carries, with everything it needs.";
    };
    squashfsCompression = lib.mkOption {
      type = lib.types.str;
      default = "zstd -Xcompression-level 15";
      description = "mksquashfs's compression for the store.";
    };
    limineConfig = lib.mkOption {
      type = lib.types.lines;
      description = "limine.conf: the boot menu (iso/boot-menu.nix).";
    };
    contents = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            source = lib.mkOption { type = lib.types.path; };
            target = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = [ ];
      description = "Other files on the image (the menu's wallpaper), at `target`.";
    };
  };

  config = {
    nyxos.liveImage.storeContents = [ config.system.build.toplevel ];

    # The live file systems: the image found by its label, its store read-only with a
    # tmpfs over it, and everything else in memory.
    fileSystems = lib.mkImageMediaOverride {
      "/" = {
        fsType = "tmpfs";
        options = [ "mode=0755" ];
      };
      "/iso" = {
        device =
          if config.boot.initrd.systemd.enable then "/dev/disk/by-label/${cfg.volumeID}" else "/dev/root";
        fsType = "iso9660";
        neededForBoot = true;
        noCheck = true;
      };
      "/nix/.ro-store" = {
        fsType = "squashfs";
        device = "${lib.optionalString config.boot.initrd.systemd.enable "/sysroot"}/iso/nix-store.squashfs";
        options = [
          "loop"
          "threads=multi"
        ];
        neededForBoot = true;
      };
      "/nix/.rw-store" = {
        fsType = "tmpfs";
        options = [ "mode=0755" ];
        neededForBoot = true;
      };
      "/nix/store" = {
        overlay = {
          lowerdir = [ "/nix/.ro-store" ];
          upperdir = "/nix/.rw-store/store";
          workdir = "/nix/.rw-store/work";
        };
      };
    };
    swapDevices = lib.mkImageMediaOverride [ ];
    boot.initrd.luks.devices = lib.mkImageMediaOverride { };
    # The scripted stage 1 finds the image by the label on the command line.
    boot.kernelParams = lib.optionals (!config.boot.initrd.systemd.enable) [
      "boot.shell_on_fail"
      "root=LABEL=${cfg.volumeID}"
    ];
    boot.initrd.availableKernelModules = [
      "squashfs"
      "iso9660"
      "uas"
      "overlay"
    ];
    boot.initrd.kernelModules = [
      "loop"
      "overlay"
    ];
    boot.initrd.supportedFilesystems = [ "vfat" ];
    boot.initrd.systemd.emergencyAccess = lib.mkIf config.boot.initrd.systemd.enable true;
    # The live system has no boot loader of its own to install.
    boot.loader.grub.enable = lib.mkImageMediaOverride false;

    # The store on the image, registered in the Nix database in memory.
    systemd.services.register-nix-paths = {
      description = "Register Nix Store Paths";
      unitConfig.DefaultDependencies = false;
      wantedBy = [ "sysinit.target" ];
      before = [
        "sysinit.target"
        "shutdown.target"
        "nix-daemon.socket"
        "nix-daemon.service"
      ];
      after = [ "local-fs.target" ];
      conflicts = [ "shutdown.target" ];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${lib.getExe' config.nix.package.out "nix-store"} --load-db < /nix/store/nix-path-registration
        # nixos-rebuild also wants a system profile and /etc/NIXOS.
        touch /etc/NIXOS
        ${lib.getExe' config.nix.package.out "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system
      '';
    };

    # From NixOS's installer profile: every driver, a console font for HiDPI screens.
    hardware.enableAllHardware = true;
    console.packages = options.console.packages.default ++ [ pkgs.terminus_font ];
    documentation.man.enable = lib.mkOverride 500 true;
    documentation.doc.enable = lib.mkOverride 500 true;
    environment.defaultPackages = [ pkgs.rsync ];
    programs.git.enable = lib.mkDefault true;
    system.stateVersion = lib.mkDefault lib.trivial.release;

    # The image: Limine's hybrid layout, so the same file starts from a USB stick or a
    # disc, on UEFI or BIOS. The kernel, initrd and store are grafted in, not copied.
    system.build.isoImage =
      pkgs.runCommand "nyxos-${version}-installer.iso"
        {
          nativeBuildInputs = [
            pkgs.buildPackages.xorriso
            limine
          ];
        }
        ''
          mkdir -p tree/boot/limine
          cp ${limine}/share/limine/{limine-bios-cd.bin,limine-uefi-cd.bin,limine-bios.sys} tree/boot/limine/
          cp ${limineConf} tree/boot/limine/limine.conf
          xorriso -as mkisofs -R -r -J -V ${cfg.volumeID} \
            -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
            --efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image \
            --protective-msdos-label \
            -graft-points /=tree \
            boot/bzImage=${kernel} boot/initrd=${initrd} nix-store.squashfs=${squashfs} \
            ${lib.concatMapStringsSep " " graft cfg.contents} \
            -o $out
          limine bios-install $out
        '';
  };
}
