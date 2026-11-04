# Btrfs snapshots with snapper: hourly and daily snapshots of the chosen Btrfs
# filesystems (/ and /home by default), and one before and after each system change the
# System Manager makes (Settings, Welcome, the Store, updates). The installer turns this
# on for a Btrfs layout; filesystems that aren't Btrfs are left out.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nyxos.snapshots;
  btrfs = builtins.filter (m: (config.fileSystems.${m}.fsType or "") == "btrfs") cfg.mounts;
  name = m: if m == "/" then "root" else lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" m);
in
{
  options.nyxos.snapshots = {
    enable = lib.mkEnableOption "Btrfs snapshots of / and /home, and around each system change";
    mounts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/"
        "/home"
      ];
      description = "Filesystems to snapshot; only the Btrfs ones are.";
    };
    aroundChanges = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.optional (builtins.elem "/" btrfs) "/";
      defaultText = lib.literalExpression ''[ "/" ] when / is Btrfs'';
      description = "Filesystems snapshotted before and after each system change.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = btrfs != [ ];
        message = "nyxos.snapshots: none of ${lib.concatStringsSep ", " cfg.mounts} is a Btrfs filesystem.";
      }
    ];

    services.snapper = {
      persistentTimer = true;
      configs = lib.listToAttrs (
        map (m: {
          name = name m;
          value = {
            SUBVOLUME = m;
            ALLOW_GROUPS = [ "wheel" ];
            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;
            TIMELINE_LIMIT_HOURLY = 6;
            TIMELINE_LIMIT_DAILY = 7;
            TIMELINE_LIMIT_WEEKLY = 4;
            TIMELINE_LIMIT_MONTHLY = 0;
            TIMELINE_LIMIT_YEARLY = 0;
            NUMBER_CLEANUP = true;
            NUMBER_LIMIT = 20;
          };
        }) btrfs
      );
    };
    # snapper keeps each filesystem's snapshots in its own .snapshots subvolume, made once
    # the filesystem is mounted.
    systemd.services.nyx-snapshot-subvolumes = {
      description = "Subvolumes for Btrfs snapshots";
      wantedBy = [ "multi-user.target" ];
      before = [
        "snapper-timeline.service"
        "nyx-system-manager.service"
      ];
      unitConfig.RequiresMountsFor = btrfs;
      path = [ pkgs.btrfs-progs ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = lib.concatMapStrings (m: let s = "${lib.removeSuffix "/" m}/.snapshots"; in ''
        if [ ! -e ${s} ]; then btrfs subvolume create ${s}; fi
        chmod 0750 ${s}
        chgrp wheel ${s}
      '') btrfs;
    };

    environment.etc."nyxos/snapshots.toml".text = ''
      # The snapper configurations the System Manager snapshots around each change.
      around_changes = [${lib.concatMapStringsSep ", " (m: ''"${name m}"'') (builtins.filter (m: builtins.elem m btrfs) cfg.aroundChanges)}]
    '';
  };
}
