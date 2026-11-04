# The lock screen: Nyx Locker (the password, a fingerprint, a face and a security key at
# once, its indicator in the lock-screen style), or hyprlock where it's off (the clock,
# the date and the password, and a fingerprint with a reader). Both in the lock-screen
# theme's colours and wallpaper (nyx-themed writes ~/.config/hypr/nyx-hyprlock.conf);
# no notifications. hypridle locks after five idle minutes and before the computer
# sleeps (which waits for the lock). The locker runs as nyx-lock.service, restarted if
# it ever crashes; in between, Hyprland keeps the session locked.
{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  hyprlock = lib.getExe pkgs.hyprlock;
  # Nyx Locker, and hyprlock if it fails for any reason but another lock screen having
  # the session: a lock screen that can't start must never leave the desktop open.
  locker =
    if osConfig.nyx.locker.enable then
      toString (
        pkgs.writeShellScript "nyx-lock" ''
          /run/current-system/sw/bin/nyx-locker
          rc=$?
          if [ "$rc" -eq 0 ] || [ "$rc" -eq 3 ]; then exit "$rc"; fi
          echo "nyx-lock: Nyx Locker stopped ($rc); hyprlock takes over" >&2
          exec ${hyprlock}
        ''
      )
    else
      hyprlock;
in
lib.mkIf (osConfig.programs.hyprlock.enable || osConfig.nyx.locker.enable) {
  xdg.configFile."hypr/hyprlock.conf".text = ''
    source = ~/.config/hypr/nyx-hyprlock.conf

    general {
      hide_cursor = true
      ignore_empty_input = true
    }

    auth {
      fingerprint {
        enabled = ${lib.boolToString osConfig.services.fprintd.enable}
        ready_message = Or touch the fingerprint reader
        present_message = Checking your fingerprint…
      }
    }

    background {
      monitor =
      path = $nyx_wallpaper
      color = $nyx_bg
      blur_passes = 3
      brightness = 0.45
    }

    label {
      monitor =
      text = $TIME
      color = $nyx_text
      font_size = 96
      font_family = Inter Light
      position = 0, 180
      halign = center
      valign = center
    }

    label {
      monitor =
      text = cmd[update:60000] date +"%A, %B %-d"
      color = $nyx_dim
      font_size = 18
      font_family = Inter
      position = 0, 90
      halign = center
      valign = center
    }

    input-field {
      monitor =
      size = 340, 52
      rounding = 14
      outline_thickness = 2
      outer_color = $nyx_surface
      inner_color = $nyx_surface
      font_color = $nyx_text
      check_color = $nyx_accent
      fail_color = $nyx_danger
      fade_on_empty = false
      placeholder_text = Password
      fail_text = That password didn't work
      font_family = Inter
      position = 0, -40
      halign = center
      valign = center
    }
  '';

  systemd.user.services.nyx-lock = {
    Unit = {
      Description = "Nyx lock screen";
      # A crash restarts it at once; an unlock ends it.
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStart = locker;
      Restart = "on-failure";
      RestartSec = 0;
      # Another lock screen already has the session.
      RestartPreventExitStatus = 3;
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "systemctl --user start nyx-lock.service";
        before_sleep_cmd = "loginctl lock-session";
        # Sleep waits until the session is locked.
        inhibit_sleep = 3;
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
      ];
    };
  };
}
