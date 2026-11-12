# Security defaults for every NyxOS machine. Full-disk encryption comes with the
# installer (unlocked with its passphrase; TPM2 unlock is planned) and Secure Boot with
# nyxos.boot.secureBoot; the firewall is on in network.nix.
{ config, lib, ... }:
let
  cfg = config.nyxos.hardening;
  # Over NixOS's own defaults; a host's setting still wins.
  harden = lib.mkOverride 900;
in
{
  options.nyxos.hardening.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "NyxOS's security defaults: kernel and network settings, root-only /boot, sudo and Nix for administrators only.";
  };

  config = lib.mkIf cfg.enable {
    # The boot partition holds the boot entries and systemd-boot's random seed.
    fileSystems."/boot".options = lib.mkIf config.boot.loader.systemd-boot.enable [
      "fmask=0077"
      "dmask=0077"
    ];

    # Only administrators run sudo at all. (Nix trusts only root, NixOS's default: a
    # trusted user could become root without a password.)
    security.sudo.execWheelOnly = lib.mkDefault true;

    boot.kernel.sysctl = {
      # Kernel addresses and the kernel log are root's.
      "kernel.kptr_restrict" = harden 2;
      "kernel.dmesg_restrict" = harden 1;
      "net.core.bpf_jit_harden" = harden 2;
      # No loading a new kernel over the running one, no line disciplines on demand.
      "kernel.kexec_load_disabled" = harden 1;
      "dev.tty.ldisc_autoload" = harden 0;
      # A program can debug only its own children, so it can't reach into a running Nyx
      # program that services trust by its executable.
      "kernel.yama.ptrace_scope" = harden 1;
      # Files in world-writable sticky folders (/tmp) only open for their owner.
      "fs.protected_fifos" = harden 2;
      "fs.protected_regular" = harden 2;
      # A desktop isn't a router: no redirects or source routing.
      "net.ipv4.conf.all.accept_redirects" = harden 0;
      "net.ipv4.conf.default.accept_redirects" = harden 0;
      "net.ipv4.conf.all.secure_redirects" = harden 0;
      "net.ipv4.conf.default.secure_redirects" = harden 0;
      "net.ipv6.conf.all.accept_redirects" = harden 0;
      "net.ipv6.conf.default.accept_redirects" = harden 0;
      "net.ipv4.conf.all.send_redirects" = harden 0;
      "net.ipv4.conf.default.send_redirects" = harden 0;
      "net.ipv4.conf.all.accept_source_route" = harden 0;
      "net.ipv6.conf.all.accept_source_route" = harden 0;
      "net.ipv4.tcp_syncookies" = harden 1;
    };

    # Network protocols a desktop doesn't use, with a history of kernel bugs.
    boot.blacklistedKernelModules = [
      "dccp"
      "sctp"
      "rds"
      "tipc"
    ];
  };
}
