{ lib, ... }:
{
  networking = {
    networkmanager.enable = true;
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
