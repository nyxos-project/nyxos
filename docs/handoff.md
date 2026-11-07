# Handoff: where NyxOS stands (2026-11-07, night)

Read this first in a new session. It covers what's done, what's half done, what Ken is
deciding, and how to work so things don't break again.

## How to work (Ken's rules, and lessons from these sessions)

- **Test the way a person uses NyxOS, not the piece you changed.** Open apps from the
  dock, its app drawer and Glimpse, not with `hyprctl exec` or a store path. Use the
  app: browse in Files, open Trash, change a setting, install from the Store. A
  screenshot of an idle screen proves nothing.
- **Read the logs after every test:** `journalctl _UID=1000 --since -10min` and
  `journalctl -b -p err` in the VM. Look for errors, crashes (`coredumpctl list`) and any
  line that repeats every second.
- **Keep every Nyx app pin current.** nyx-packages pins each app at a commit; update all
  of them (not just the app you touched) before testing NyxOS as a whole.
- **Watch the VM's disk.** `scripts/dev-vm disk check` after big builds (rebuild does it
  for you); `scripts/dev-vm disk clean` when it warns. Past the quota the VM's disk turns
  read-only and builds die quietly.
- **Never change uwsm's package** (an override, a patch): a switch to it restarts uwsm's
  user units and ends the running Hyprland session (it happened here). Change what the
  session sees some other way (a Home Manager file, as `uuctl.desktop` is hidden).
- **Ken's laptop:** tell Ken before installing or running anything there, and say when
  an install will ask for his password (install scripts use `pkexec` without a terminal).
  Nyx apps changed in a session are installed with `./install.sh <app> </dev/null`.
  Never touch his mouse, keyboard or focus; test windows go only on a headless output you
  create (see `.cursor/rules/screenshots-virtual-monitor.mdc`).
- Commit in each repo; push nyxos to `main` and `main:testing`.

## Testing in the VM

- `scripts/smoke-apps dock` and `scripts/smoke-apps glimpse` open every app as the dock
  and as Glimpse do, and write a report and screenshots to `/tmp/nyx-smoke-*`. A terminal
  app counts when a new window opens; an overlay (Clipboard, Glimpse) when its layer
  appears, and Escape closes it. Last run: 44 of 46 open both ways; Foot Server (no
  window) and uuctl (now hidden) are the two left.
- Input in the VM (the VM only, never the laptop): `nix build nixpkgs#wtype` and
  `nixpkgs#wlrctl` in the VM, then run them as ken with `WAYLAND_DISPLAY=wayland-1`.
  wtype types (the lock screen and greeter take it; password `nyx`), `wlrctl pointer move
  -3000 -3000` then `move X Y` and `click left` clicks. Lock with `loginctl lock-sessions`
  as root. Hold `systemd-inhibit --what=idle sleep 7200` as ken so idle doesn't lock
  mid-test.
- After a re-login, `/run/user/1000/hypr` keeps the old instance's folder: pick the
  newest (`ls -t | head -1`).
- `nyx-settings --section ID` opens a Settings page (Welcome's buttons do the same).

## Fixed this session (committed and pushed)

- **Default apps:** Settings and Welcome offered Write as the web browser: GIO lists
  apps for a type's parent types too, and text/html is a text/plain. nyx-ui now offers
  only apps that list a type themselves (`recommended_for_type`); Settings says when no
  browser is installed (nyx-design `f8eb24b`).
- **Files** reopened saved tabs it couldn't open (Trash without GVfs); restore now skips
  schemes this system's GIO doesn't support.
- **Lock screen** said "Fingerprint/Face not recognised" without a reader or camera. The
  lock services (`nyx-packages/modules/nixos/biometrics.nix`) now return the method's
  own result, and a method its gate skips or that stands aside lands on `false`
  (unavailable) instead of NixOS's closing `pam_deny`. Checked in the VM: no message.
- **Control Center:** Sound & brightness is one row tall without a screen backlight.
- **Notification Center:** a corner card as tall as what it shows (like the Control
  Center); and pop-ups no longer abort when one is taken down under the pointer (the
  SIGABRT in the VM's coredumps).
- **Store on NyxOS:** no "select AUR" hint, a Flathub-only review doesn't promise an
  administrator password, "Flathub ·" lost its stray dot, and the details' description
  doesn't open all selected.
- **Settings on NyxOS:** Bar Plugins lists and switches Nyx plugins (`nyx plugin`)
  instead of "Couldn't list plugins"; Printers shows its Printing service switch instead
  of `sudo pacman -S cups`; the launcher entry no longer says "in Omarchy".
- **Welcome** fits half a 1280 px screen (the list of steps goes below 760 px).
- **Containers** builds again: its VM screens use spice-client-glib, so its package
  needs `spice-gtk`.
- Tested by hand in the VM: Files (Trash, Network, a USB disk that mounts on click),
  every Settings page (screenshots, no errors), the Store installing and removing
  Mines from Flathub, Welcome start to finish, lock and unlock with the password,
  logging in at the greeter, notifications and pop-ups, Control Center, Bar Plugins
  switches, Glimpse search.
- **uuctl** (uwsm's unit picker, which needs a dmenu NyxOS lacks) is hidden from the app
  drawer by `modules/home/default.nix`.
- `scripts/smoke-apps` works: the app list was swallowed by `incus exec` reading stdin,
  windows weren't closed (quoting), and Glimpse mode needed a `gio` NyxOS doesn't have.

## Known problems not fixed yet

- **Settings pages still written for Omarchy** (seen on every page in the VM):
  Sign-in & Security reads `/etc/pam.d` files ("sddm has no PAM file to build on") where
  NyxOS sets methods in `nyx.biometrics.surfaces`; Bar & Notifications edits a Waybar/
  Omarchy shell layout (empty) instead of Nyx Bar's `~/.config/nyx/bar.toml`; text that
  names Omarchy on Night Light, Dock, Trackpad, Appearance and About ("Omarchy's
  defaults"); Extensions offers Arch packages.
- **Chat** defaults to llama.cpp on this computer, which NyxOS doesn't ship (its
  installer is left out); the banner says "Install the llama.cpp service from Chat's
  installer". On NyxOS it should default to Ollama (a Store item) and say so. Needs a
  decision about the saved-hosts migration in `nyx-chat/apps/chat/src/prefs.rs`.
- **Keyring:** Pulse (and Antigravity, ChatGPT) bring up GNOME's "Unlock Login Keyring"
  in the VM, whose session starts by autologin; check a password sign-in on real
  hardware unlocks it, and consider a Nyx-styled prompt.
- **Glimpse** indexes no folders until you add one (by design); Welcome could offer it.
- Two overlays at once (Clipboard opened over Glimpse): after Clipboard closes, the
  keyboard doesn't go back to Glimpse, so Escape does nothing until it's clicked.
- The lock screen still shows the face icon when face can't be used (it's quiet now).
- The Store tiled beside another window at 1280 px is cut off on the right, as Welcome
  was.
- The Store's NyxOS catalog items for Nyx apps (`nyx = ["mail"]`) have no desktop ID:
  Installed shows category symbols for them, not their icons, and their details have no
  Open button. `nix.rs` could find each one's launcher by its program (`nyx-mail`).
- Flatpak apps (Mines, tested) don't follow the Nyx theme.
- The Clock bar plugin is started once a minute (a journal line each time).
- `dbus-broker` logs "Ignoring duplicate name" for many services at every switch
  (packages listed twice in the D-Bus service path).
- No USB stick, printer or real network shares in the VM: a virtual USB disk
  (`incus config device add nyxos-dev smokeusb disk source=IMG io.bus=usb`) shows in
  Files and mounts on click.

## Waiting on Ken

- **Laptop installs:** Control Center, Files, Notification Center, Settings and Store
  changed and are installed on the laptop; not reinstalled (Settings and Store ask for a
  password through pkexec).
- **The Catppuccin Mocha look:** Ken wants Catppuccin Mocha as NyxOS's default theme and
  a new identity (wallpaper, logo, boot, login, lock). Four rounds of mockups are in
  `~/Pictures/nyx-catppuccin-mockups/` (`round-1` … `round-4`, each with
  `overview-*.png`); generators in `src/gen*.py`. His latest direction (round 4): simple,
  modern, clean and techie like his current Omarchy desktop, a flat mantle background
  (#181825) with one centred wordmark in blue (#89b4fa). Round 4 has 12 wordmarks and four
  full sets (pixel gothic, pixel lowercase, squared tech, mono). Don't build any of it
  until he picks.
