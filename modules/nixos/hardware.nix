# Hardware: drivers, power and firmware for what the computer has. The System Manager
# detects it (nyx-system hardware apply; the installer does it first) into the overrides
# layer, which sets nyxos.hardware; a host can set it too.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nyxos.hardware;
  has = vendor: builtins.any (g: g.vendor == vendor) cfg.gpus;
  busOf = vendor: (lib.findFirst (g: g.vendor == vendor) { bus = ""; } cfg.gpus).bus;
  physical = cfg.virtualMachine == null;
  nvidia = has "nvidia" && cfg.nvidia.proprietary;
  # A laptop with NVIDIA graphics beside the processor's: the other one drives the
  # screen and NVIDIA's wakes for what asks for it.
  offload = nvidia && cfg.battery && (has "intel" || has "amd");
in
{
  options.nyxos.unfree = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Unfree packages (by name) the administrator accepted.";
  };

  options.nyxos.hardware = {
    gpus = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            vendor = lib.mkOption {
              type = lib.types.enum [
                "amd"
                "intel"
                "nvidia"
                "virtio"
                "other"
              ];
            };
            bus = lib.mkOption {
              type = lib.types.strMatching "PCI:[0-9]+:[0-9]+:[0-9]+";
              description = "Its PCI address in NixOS's form.";
            };
          };
        }
      );
      default = [ ];
      description = "The graphics cards.";
    };
    cpu = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "amd"
          "intel"
        ]
      );
      default = null;
    };
    battery = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "It runs on a battery (a laptop or tablet).";
    };
    bluetooth = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    virtualMachine = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The hypervisor, when it's a virtual machine.";
    };
    nvidia.proprietary = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "NVIDIA's own driver (unfree, open kernel modules) instead of nouveau.";
    };
  };

  config = lib.mkMerge [
    {
      nixpkgs.config.allowUnfreePredicate = lib.mkIf (config.nyxos.unfree != [ ]) (
        pkg: builtins.elem (lib.getName pkg) config.nyxos.unfree
      );
      # What Nyx AI Core's worker needs (CUDA's runtime, on NVIDIA's own driver).
      nyxos.unfree = lib.mkIf config.nyx.ai.enable config.nyx.ai.unfree;

      # Firmware for Wi-Fi, Bluetooth, graphics and sound, and the processor's fixes.
      hardware.enableRedistributableFirmware = lib.mkDefault true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault (cfg.cpu == "intel" && physical);
      hardware.cpu.amd.updateMicrocode = lib.mkDefault (cfg.cpu == "amd" && physical);
      # Firmware updates from LVFS, for real hardware.
      services.fwupd.enable = lib.mkDefault physical;

      hardware.bluetooth.enable = lib.mkDefault cfg.bluetooth;

      # Power: profiles (Settings' Power), the battery, the screen's brightness, and
      # Intel's thermal management.
      services.power-profiles-daemon.enable = lib.mkDefault true;
      services.upower.enable = lib.mkDefault true;
      services.thermald.enable = lib.mkDefault (cfg.cpu == "intel" && physical);
      environment.systemPackages = [ pkgs.brightnessctl ];

      hardware.graphics.extraPackages = lib.optionals (has "intel") [
        pkgs.intel-media-driver
        pkgs.vpl-gpu-rt
      ];
      hardware.amdgpu.initrd.enable = lib.mkDefault (has "amd");
    }

    (lib.mkIf nvidia {
      nyxos.unfree = [
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-persistenced"
      ];
      # Nyx AI Core runs Prism's prebuilt CUDA build of llama.cpp on NVIDIA's own driver.
      nyx.ai.acceleration = lib.mkDefault "cuda";
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        open = lib.mkDefault true;
        modesetting.enable = true;
        nvidiaSettings = lib.mkDefault false;
        powerManagement.enable = lib.mkDefault cfg.battery;
        powerManagement.finegrained = lib.mkDefault offload;
        prime = lib.mkIf offload {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          nvidiaBusId = busOf "nvidia";
          intelBusId = lib.mkIf (has "intel") (busOf "intel");
          amdgpuBusId = lib.mkIf (has "amd") (busOf "amd");
        };
      };
      # Hyprland on NVIDIA's driver.
      environment.sessionVariables = lib.mkIf (!offload) {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
      };
    })
  ];
}
