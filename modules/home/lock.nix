# The lock screen: Nyx Locker (the password, a fingerprint, a face and a security key at
# once, its indicator in the lock-screen style), or hyprlock where it's off (the clock,
# the date and the password, and a fingerprint with a reader). Both in the lock-screen
# theme's colours and wallpaper (nyx-themed writes ~/.config/hypr/nyx-hyprlock.conf);
# no notifications. hypridle locks, turns the screen off and sleeps after the idle
# settings' times, and locks before the computer sleeps (which waits for the lock). The
# locker runs as nyx-lock.service, restarted if it ever crashes; in between, Hyprland
# keeps the session locked.
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
          ${hyprlock}
          rc=$?
          # Nyx Locker told logind the session is locked (LockedHint) and hyprlock doesn't
          # say otherwise, so once hyprlock has unlocked, clear it here.
          if [ "$rc" -eq 0 ]; then
            ${pkgs.systemd}/bin/busctl --system call org.freedesktop.login1 \
              /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetLockedHint b false || true
          fi
          exit "$rc"
        ''
      )
    else
      hyprlock;

  screen = pkgs.writeShellScript "nyx-screen" ''
    exec ${osConfig.programs.hyprland.package}/bin/hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })"
  '';

  # hypridle's configuration, from the idle settings: seconds, 0 for never. hypridle
  # 0.1.7 wants its usual file even when given another, so it's written there.
  idleConf = pkgs.writeShellScript "nyx-idle-conf" ''
    set -eu
    get() {
      v=$(/run/current-system/sw/bin/nyx-system config get idle "$1" 2>/dev/null) || v=$2
      case "$v" in "" | *[!0-9]*) v=$2 ;; esac
      echo "$v"
    }
    lock=$(get lock 300)
    off=$(get screen-off 360)
    sleep=$(get suspend 0)
    dir="''${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    mkdir -p "$dir"
    out="$dir/hypridle.conf"
    {
      echo "general {"
      echo "  lock_cmd = systemctl --user start nyx-lock.service"
      echo "  before_sleep_cmd = loginctl lock-session"
      echo "  after_sleep_cmd = ${screen} on"
      # Sleep waits until the session is locked.
      echo "  inhibit_sleep = 3"
      echo "}"
      if [ "$lock" -gt 0 ]; then
        printf 'listener {\n  timeout = %s\n  on-timeout = loginctl lock-session\n}\n' "$lock"
      fi
      if [ "$off" -gt 0 ]; then
        printf 'listener {\n  timeout = %s\n  on-timeout = %s off\n  on-resume = %s on\n}\n' "$off" "${screen}" "${screen}"
      fi
      if [ "$sleep" -gt 0 ]; then
        printf 'listener {\n  timeout = %s\n  on-timeout = systemctl suspend\n}\n' "$sleep"
      fi
    } > "$out.new"
    mv "$out.new" "$out"
  '';
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

  # hypridle's timings come from the idle settings (defaults, the administrator's, the
  # user's, merged by nyx-system), read each time it starts: Settings restarts it after
  # a change. An idle inhibitor (Stay awake, a video playing) holds them all off.
  systemd.user.services.hypridle = {
    Unit = {
      Description = "Locks the screen and turns it off when you're away";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStartPre = idleConf;
      ExecStart = lib.getExe pkgs.hypridle;
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
