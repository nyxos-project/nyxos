{ lib, pkgs, ... }:
{
  networking = {
    networkmanager.enable = true;
    # OpenVPN files from a VPN provider import in Settings › Network › VPN (WireGuard is
    # built in); NixOS adds no plugins unless they're listed.
    networkmanager.plugins = lib.mkDefault [ pkgs.networkmanager-openvpn ];
    useDHCP = lib.mkDefault false;
    firewall.enable = true;
  };

  # Off unless a host or Settings (Services) turns it on; keys only, never root.
  services.openssh = {
    enable = lib.mkDefault false;
    startWhenNeeded = false;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
