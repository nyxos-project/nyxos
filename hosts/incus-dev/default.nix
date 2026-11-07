# Local development VM on Incus (QEMU/KVM, virtio-gpu, no GPU passthrough).
{ lib, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
    ../../modules/nixos
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "nyxos-dev";

  nyxos = {
    user = {
      name = "ken";
      description = "Ken Smith";
      authorizedKeys = [ (builtins.readFile ./ken.pub) ];
      # Console and greeter fallback only; SSH accepts keys alone.
      initialPassword = "nyx";
    };

    # Temporary until Nyx Greeter exists.
    desktop.autoLogin = true;
  };

  # Welcome-tier apps, enabled here to test their packages.
  nyx = {
    system.host = "incus-dev";
    fonts.enable = true;
    pdf.enable = true;
    news.enable = true;
    office.enable = true;
    git.enable = true;
    music.enable = true;
    media-player.enable = true;
    theater.enable = true;
    photos.enable = true;
    share.enable = true;
    transfer.enable = true;
    cloud.enable = true;
    clipboard.enable = true;
    home.enable = true;
    chat.enable = true;
    activity.enable = true;
    containers.enable = true;
    torrents.enable = true;
    weather.enable = true;
    notes.enable = true;
    files.enable = true;
    contacts.enable = true;
    calendar.enable = true;
    reminders.enable = true;
    backup.enable = true;
    maps.enable = true;
    mail.enable = true;
    capture.enable = true;
    passwords.enable = true;
    pulse.enable = true;
    assistant.enable = true;
    # No camera or reader in the VM: both methods stand aside and the password works.
    biometrics = {
      enable = true;
      face = "irlume";
      fingerprint.enable = true;
      surfaces.sudo = [
        "face"
        "fingerprint"
      ];
      surfaces.lock = [
        "fingerprint"
        "face"
      ];
    };
  };

  # The VM's disk is ext4; a small Btrfs test disk (Incus volume nyx-snaptest) is
  # snapshotted instead of / and /home.
  fileSystems."/srv/snaptest" = {
    device = "/dev/disk/by-label/nyx-snaptest";
    fsType = "btrfs";
    options = [ "nofail" ];
  };
  nyxos.snapshots = {
    enable = true;
    mounts = [ "/srv/snaptest" ];
    aroundChanges = [ "/srv/snaptest" ];
  };

  # The VM's EFI partition is 256 MB; an installed NyxOS has 1 GiB.
  boot.loader.limine.maxGenerations = 4;

  # dev-vm ssh.
  services.openssh.enable = true;

  # The disk is a file in the host's Btrfs pool with a quota, and builds churn through it:
  # freed blocks go back at once (discard) and daily, old generations and garbage go daily
  # and whenever the disk runs low, and the journal stays small. Past the quota the disk
  # turns read-only.
  fileSystems."/".options = [ "discard" ];
  services.fstrim.interval = "daily";
  nix.gc = {
    dates = lib.mkForce "daily";
    options = lib.mkForce "--delete-older-than 3d";
  };
  services.journald.extraConfig = "SystemMaxUse=300M";

  # Rust builds take about 1 GiB per rustc; 6 jobs of 6 threads each overran 8 GiB.
  nix.settings = {
    max-jobs = 2;
    cores = 3;
    # During a build, collect garbage when under 30 GiB are free, up to 60 GiB free.
    min-free = 30 * 1024 * 1024 * 1024;
    max-free = 60 * 1024 * 1024 * 1024;
  };

  # The Incus image allows a passwordless root console; `incus exec` is enough.
  users.users.root = {
    initialHashedPassword = lib.mkForce null;
    hashedPassword = "!";
  };

  system.stateVersion = "26.05";
}
