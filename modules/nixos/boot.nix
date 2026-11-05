# The boot menu and splash: Limine in NyxOS's look (the boot theme's wallpaper, every
# generation and its NyxOS Recovery entry, Windows when it's beside NyxOS, Secure Boot
# when asked for), then Nyx Plymouth in the boot theme with the kernel and udev quiet.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.nyxos.boot;
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
  wallpaper = nyxPkgs.nyx-wallpapers.passthru.defaults.${config.nyxos.theme.boot} or null;
in
{
  options.nyxos.boot = {
    loader = lib.mkOption {
      type = lib.types.enum [
        "limine"
        "systemd-boot"
      ];
      default = "limine";
      description = "The boot menu.";
    };
    windows = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}");
      default = null;
      description = ''
        Windows Boot Manager's EFI partition (its GPT partition GUID), to offer Windows
        in the boot menu. NyxOS has its own EFI partition beside it; the installer sets
        this when it installs beside Windows.
      '';
    };
    secureBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Sign the boot menu and kernels with this machine's own keys (sbctl). The keys
        are made and enrolled when the firmware is in Setup Mode; Microsoft's stay, so
        Windows and firmware updates still boot.
      '';
    };
  };

  config = lib.mkMerge [
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

    (lib.mkIf (cfg.loader == "limine") {
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.loader.limine = {
        enable = true;
        efiSupport = true;
        maxGenerations = lib.mkDefault 20;
        style = {
          wallpapers = lib.optional (wallpaper != null) wallpaper;
          wallpaperStyle = "stretched";
          backdrop = "0B0B0E";
          interface.branding = "NyxOS";
          interface.brandingColor = "7";
        };
        extraEntries = lib.mkIf (cfg.windows != null) ''
          /Windows
            protocol: efi
            path: guid(${cfg.windows}):/EFI/Microsoft/Boot/bootmgfw.efi
        '';
        secureBoot = lib.mkIf cfg.secureBoot {
          enable = true;
          autoGenerateKeys = true;
          autoEnrollKeys.enable = true;
        };
      };
    })
  ];
}
