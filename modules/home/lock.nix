# The lock screen, for now hyprlock: the clock, the date and the password (and a
# fingerprint when there's a reader), in the lock-screen theme's colours and wallpaper
# (nyx-themed writes ~/.config/hypr/nyx-hyprlock.conf). No notifications. hypridle
# locks after five idle minutes and before the computer sleeps (which waits for the
# lock). hyprlock runs as nyx-lock.service, restarted if it ever crashes; in between,
# Hyprland keeps the session locked.
{
  lib,
  pkgs,
  osConfig,
  ...
}:
lib.mkIf osConfig.programs.hyprlock.enable {
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
      ExecStart = "${lib.getExe pkgs.hyprlock}";
      Restart = "on-failure";
      RestartSec = 0;
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
