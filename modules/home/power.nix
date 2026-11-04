# The power profile for each power source, chosen in Settings' Power page
# (~/.local/state/nyx/power-profiles/ac and battery): set at login and whenever the
# computer is plugged in or unplugged. Without a choice: Performance on AC when there is
# one, else Balanced.
{ pkgs, osConfig, ... }:
let
  ppd = osConfig.services.power-profiles-daemon.package;
  script = pkgs.writeShellScript "nyx-power-profiles" ''
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/nyx/power-profiles"
    apply() {
      if [ "$(${pkgs.systemd}/bin/busctl get-property org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower OnBattery 2>/dev/null)" = "b true" ]; then
        source=battery
      else
        source=ac
      fi
      profiles=$(${ppd}/bin/powerprofilesctl list 2>/dev/null | ${pkgs.gnused}/bin/sed -n 's/^[* ]*\([a-z-]*\):$/\1/p')
      want=$(cat "$state/$source" 2>/dev/null)
      if [ -z "$want" ] || ! printf '%s\n' $profiles | ${pkgs.gnugrep}/bin/grep -qx "$want"; then
        want=balanced
        if [ "$source" = ac ] && printf '%s\n' $profiles | ${pkgs.gnugrep}/bin/grep -qx performance; then want=performance; fi
      fi
      ${ppd}/bin/powerprofilesctl set "$want"
    }
    apply
    ${pkgs.glib}/bin/gdbus monitor --system --dest org.freedesktop.UPower --object-path /org/freedesktop/UPower |
      while read -r line; do
        case "$line" in *OnBattery*) apply ;; esac
      done
  '';
in
{
  systemd.user.services.nyx-power-profiles = {
    Unit = {
      Description = "The power profile for being plugged in or on battery";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = toString script;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
