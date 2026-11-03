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

  # The Incus image allows a passwordless root console; `incus exec` is enough.
  users.users.root = {
    initialHashedPassword = lib.mkForce null;
    hashedPassword = "!";
  };

  system.stateVersion = "26.05";
}
