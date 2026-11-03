{ lib, ... }:
{
  networking = {
    networkmanager.enable = true;
    useDHCP = lib.mkDefault false;
    firewall.enable = true;
  };

  services.openssh = {
    enable = true;
    startWhenNeeded = false;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
