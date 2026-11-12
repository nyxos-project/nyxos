# The boot menu and splash: Limine, plain and quiet (the boot theme's background and
# text, no wallpaper or help, three seconds; every generation and its NyxOS Recovery entry,
# Windows when it's beside NyxOS, Secure Boot when asked for), then Nyx Plymouth in the
# boot theme with the kernel and udev quiet.
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
  bootTheme = import ../../themes {
    inherit lib;
    inherit (inputs.nyx-packages.inputs) nyx-design;
  } config.nyxos.theme.boot;
  c = bootTheme.colors;
  s = bootTheme.swatches;
  palette = lib.concatStringsSep ";";
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
      type = lib.types.nullOr (
        lib.types.strMatching "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
      );
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
        # The system logo, in each theme's colours, when one is set.
        themePackages = [
          (
            if config.nyxos.logo == null then
              nyxPkgs.nyx-plymouth
            else
              nyxPkgs.nyx-plymouth.override { logo = config.nyxos.logo; }
          )
        ];
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
      boot.loader.timeout = lib.mkDefault 3;
      boot.loader.limine = {
        enable = true;
        efiSupport = true;
        maxGenerations = lib.mkDefault 20;
        style = {
          wallpapers = [ ];
          # The splash's background, so the menu and the splash are one colour.
          backdrop = c.backdrop;
          interface = {
            branding = "NyxOS";
            brandingColor = c.text;
            helpColor = c.dimText;
            helpColorBright = c.accent;
            helpHidden = true;
          };
          graphicalTerminal = {
            background = c.backdrop;
            foreground = c.text;
            brightBackground = c.card;
            brightForeground = c.text;
            palette = palette [
              c.bg
              s.red
              s.green
              s.amber
              s.blue
              s.violet
              s.teal
              c.dimText
            ];
            brightPalette = palette [
              c.border
              s.red
              s.green
              s.amber
              s.blue
              s.violet
              s.teal
              c.text
            ];
          };
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
