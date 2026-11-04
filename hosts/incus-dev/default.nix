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
    };
  };

  # Rust builds take about 1 GiB per rustc; 6 jobs of 6 threads each overran 8 GiB.
  nix.settings = {
    max-jobs = 2;
    cores = 3;
  };

  # The Incus image allows a passwordless root console; `incus exec` is enough.
  users.users.root = {
    initialHashedPassword = lib.mkForce null;
    hashedPassword = "!";
  };

  system.stateVersion = "26.05";
}
