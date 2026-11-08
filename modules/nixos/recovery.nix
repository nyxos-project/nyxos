# NyxOS Recovery: a boot entry beside each generation that starts a text console instead
# of the desktop, without the network, and runs nyx-recovery as root on the first
# console (generations, configuration repair, health, accounts, restoring from a backup).
# Each generation also carries the settings layer and flake.lock it was built from, so
# going back to it can put them back even if /var/lib is lost.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.nyxos.recovery;
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
  settings = "${inputs.nyxos-overrides}/system.json";
  toolPins = "${inputs.nyxos-overrides}/tools.json";
in
{
  options.nyxos.recovery.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "The NyxOS Recovery boot entry beside each generation.";
  };

  config = lib.mkMerge [
    {
      # The machine's own flake when it has one (templates/host), else NyxOS's.
      environment.etc."nyxos/built-from/flake.lock".source = "${inputs.machine or inputs.self}/flake.lock";
      environment.etc."nyxos/built-from/system.json" = lib.mkIf (builtins.pathExists settings) { source = settings; };
      environment.etc."nyxos/built-from/tools.json" = lib.mkIf (builtins.pathExists toolPins) { source = toolPins; };
    }

    (lib.mkIf cfg.enable {
      specialisation.recovery.configuration = {
        system.nixos.tags = [ "recovery" ];
        boot.kernelParams = [ "nyx.recovery=1" ];
        boot.plymouth.enable = lib.mkForce false;
        # No desktop and no network: what's on this computer is enough.
        services.greetd.enable = lib.mkForce false;
        networking.networkmanager.enable = lib.mkForce false;
        networking.wireless.enable = lib.mkForce false;
        networking.useDHCP = lib.mkForce false;
        environment.etc."nyx-recovery-environment".text = "nyx-backup-recovery-v1\n";
        # Recovery is root without a password, like its own shell: the other consoles too,
        # and the first one if the console ever stops.
        services.getty.autologinUser = lib.mkForce "root";

        systemd.services.nyx-recovery = {
          description = "NyxOS Recovery";
          wantedBy = [ "multi-user.target" ];
          after = [
            "systemd-user-sessions.service"
            "getty-pre.target"
          ];
          conflicts = [ "getty@tty1.service" ];
          onFailure = [ "getty@tty1.service" ];
          path = [
            pkgs.restic
            "/run/current-system/sw"
          ];
          environment.TERM = "linux";
          serviceConfig = {
            ExecStart = "${nyxPkgs.nyx-system}/bin/nyx-recovery";
            StandardInput = "tty";
            StandardOutput = "tty";
            StandardError = "tty";
            TTYPath = "/dev/tty1";
            TTYReset = true;
            TTYVHangup = true;
            TTYVTDisallocate = true;
            Restart = "always";
            RestartSec = 1;
          };
        };
        environment.systemPackages = [ pkgs.restic ];
      };
    })
  ];
}
