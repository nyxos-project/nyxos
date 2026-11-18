{ lib, ... }:
let
  # Not for system accounts: the login screen's session socket-activated PipeWire, which
  # crashed there (its X11 bell module, with no X server) at every boot.
  people = {
    unitConfig.ConditionUser = "!@system";
  };
in
{
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  systemd.user.services = lib.genAttrs [ "pipewire" "pipewire-pulse" "wireplumber" ] (_: people);
  systemd.user.sockets = lib.genAttrs [ "pipewire" "pipewire-pulse" ] (_: people);
}
