# Runtime observations (working notes, folded into the reports)

All in the dev VM `nyxos-dev` (Incus/QEMU, 6 vCPU of an Intel Core Ultra 9 285H, 16 GiB,
virtio-gpu native context on the Intel iGPU), generation 244, nyx-packages `d69e87e`.

## Phase C

- nyxos `nix flake check` (as CI: repository overrides): passed, 211 s, mostly cached
  (logs/nyxos-flake-check.log.gz).

## Probes before the snapshot (read-only)

- No failed system or user units (logs/runtime-services.txt).
- Listening: sshd 0.0.0.0:22, fluxd *:12100 tcp+udp, avahi 5353/udp, nyx-aid 127.0.0.1:8080,
  nyx-cloudd 127.0.0.1:35951 (logs/runtime-listening.txt).
- System journal this boot: 3,050 error-priority lines, nearly all dbus-broker
  "Ignoring duplicate name" (every D-Bus service file is found twice: the package's
  store path and /run/current-system/sw/share). Two *different* nyx-system store paths
  both provide `io.github.design_nexus.nyx.Theme`. nyx-locker logs pam_exec failures of
  the face/fingerprint gates (expected: no camera or reader in the VM).
  `nyx-icons.service` was killed by SIGTERM once (logs/runtime-*-journal*.txt).
- `nyx update --dry-run` on the dev VM: "The system channel couldn't be checked: this
  system's flake has no nyxos input" (the dev VM's flake is the nyxos repo itself, so
  the system path can only be exercised on an installed machine); "Firmware: fwupd isn't
  installed". `nyx update history` shows a failed system update and one rollback on
  2026-11-08 (logs/runtime-nyx-update.txt).
- `nyx system generations` prints raw Unix timestamps (1794462566) instead of dates.
- AI Core (logs/runtime-ai-core*.txt): worker ready (PrismML llama.cpp b12128), one
  installed model (SmolLM2 135M Q2_K, 88 MB). The OpenAI endpoint on 127.0.0.1:8080:
  - answers without any key, to any local user (uid 65534 `nobody` got HTTP 200);
  - accepts a foreign `Host:` header (DNS rebinding is not prevented);
  - accepts a `Content-Type: text/plain` POST with a foreign `Origin` (a browser
    "simple request" needs no preflight) and runs inference; no CORS headers are sent, so
    a page can't read the reply unless it also rebinds DNS.
  - Cold request (model load + 16 tokens): 41.4 s; warm: 6.9 s; prompt processing
    15.7 tokens/s on a 135M model, with "0.0 GB GPU" (Vulkan device unused in the VM).
    Not representative of hardware; record as unmeasured on real hardware.
  - `nyx-ai status` reports "first token avg 0 ms; 0 tokens/s" after two completed
    requests through the endpoint: endpoint requests aren't counted in the statistics.

## Runtime checks requested by the static reports (to run in Phase D/F)

- Hyprland (hyprland-patches.md): fullscreen a GTK app and mpv, leave fullscreen,
  close while fullscreen; watch Dock/Bar during it (NYX-HYPR-001/002). Virtual monitor
  layout with confirm and no answer, twice (NYX-HYPR-003). Workspace wrap-around.
- Shell (shell.md): kill the shared Quickshell process (nyx-shell-qs) repeatedly past
  systemd's start limit; check Super+Space/Super+D and recovery (NYX-SHELL-001). Kill
  Shell Core with Glimpse open; Escape/click-out; Super+Space while it's down
  (NYX-SHELL-002). Second (headless) output: CC then Glimpse keyboard ownership, Dock on
  the new output, remove it. Brightness OSD latency (no backlight in the VM: likely n/a).
- Release inventory correction from architecture.md: Desktop Widgets are enabled on no
  host (NYX-ARCH-006); Notification Center and Switcher run their GTK front ends on NyxOS.

## Tooling observation

- `scripts/dev-vm packages …` pushes the nyx-packages checkout into the VM, runs nix,
  then copies the VM's `flake.lock` back over the checkout (`pull_lock`). During this
  audit another session updated `nyx-files` in the working tree's lock while the check
  ran; the pull-back would have reverted it silently. Avoided by removing the VM copy
  after evaluation. Developer-tooling risk (P3), not a product defect.
- Productivity apps (apps/*.md): on the installed test VM (per-user apps), check Glimpse
  finds per-user apps' plugins (MAIL-002) and that their D-Bus services activate
  (CALENDAR-002). Office: round-trip a .docx with an unsupported element (comment,
  footnote, chart) and diff the XML (OFFICE-001). Archive: extract a crafted zip with
  `../` entries and an absolute path (ARCHIVE). AT-SPI: are icon-only buttons named
  (OFFICE-002; nyx-ui icon-button helper sets only a tooltip).
- Assistant/utility apps: Assistant voice command "open files"/"open the browser" on
  NyxOS (ASSISTANT-001); is the microphone open once the daemon is enabled (wake word);
  Clipboard and Agents Settings pages visible?; fingerprint wait before password in the
  admin prompt (BIOMETRICS).

## Security/privacy probes (logs/runtime-security-probes.txt)

- NYX-SEC-002 confirmed: a copy of socat saved as `~/.local/bin/nyx-passwordsd` got
  `{"ok":true,...}` from the root key service `/run/nyx-biometrics/keyd.sock` (mode
  0666); the same binary under its own name was refused. (Only the harmless `exists`
  query was sent; the copy was removed.)
- NYX-SEC-003 confirmed: the firewall (iptables backend) accepts 12100/tcp+udp, 22/tcp,
  5353/udp and ICMP echo on every interface.
- NYX-SEC-004 confirmed: user `ken` is in `input` (and wheel, audio, video,
  networkmanager). Confirm on the installed machine whether the installer's user gets
  `input` too.
- NYX-PRIV-001 confirmed: `ecosystem:enforce_permissions` is false; `grim` as an
  ordinary program captured the whole screen without any prompt; a capture taken right
  after shows no indicator in the bar (shots/after-silent-grim.png).
- Connect's config on the dev user: `share_home = false`, `check_updates = false`.

## CI and channel checks (verified with gh and git, 00:50)

- Last 5 runs of nyxos and of nyx-packages: all `failure`, at `nix fmt -- --check`
  (exit 1 after ~10 s). Confirms NYX-CI-001.
- Remote branches: nyxos `main` 97f1573, `stable` 7454358 (2026-11-10), `testing`
  e9673e6; nyx-packages `main` d69e87e, `stable` 558453c. `git rev-list
  origin/stable..v0.1.0` = 40. The installer writes `nyxos.url =
  "github:nyxos-project/nyxos/{channel}"` with channel stable|testing
  (nyx-installer/crates/nyx-install/src/plan.rs:355). Confirms NYX-CI-003's premise; the
  install test will show what a 0.1.0 install's first update does.
- Infrastructure runtime tests queued: theme token vs app screenshot; AI socket when
  8080 is taken; nyx update dry-runs on the installed machine; F9 dictation on a base
  install; Connect with fluxd stopped.
- Base-tier apps: SHARE-001 confirmed by configuration: nothing opens 53317 (no Nix
  file mentions it; the firewall list above has no 53317). BACKUP-001 premise
  confirmed: `nix.gc.automatic = true; dates = "weekly"` (modules/nixos/base.nix:24);
  runtime: create a schedule in Backup, check the unit's ExecStart path, rebuild + gc,
  check the timer still runs. INSTALLER-001: install test with a non-US layout (de) and
  a passphrase containing layout-dependent characters (y/z, ä).

## Install test (nyxos-install-test, ISO sha256 7b5c27e4…)

- VM made by hand as `scripts/install-vm create` does, but with 6 GiB instead of 8 (host
  memory). Live ISO: agent up 14 s after start; the graphical installer runs on tty1;
  `/etc/nyxos/source` points at the ISO's own NyxOS flake (offline install).
- Headless install (`nyx-install run plan.json --yes`, the same steps the GUI runs),
  erase /dev/sda, LUKS2 with a test passphrase, keyboard us, channel stable, serial
  console added (`console=ttyS0`) so the unlock prompt can be answered:
  **FAILED at step 11/43 after 12 s**: "Making subvolumes didn't work: mount failed" —
  `mount: /mnt: mount point does not exist`. The live root has no /mnt
  (`ls /` on the ISO), and nothing creates it: nyx-install mounts at `ROOT = "/mnt"`
  (plan.rs:12) without `mkdir`, and NyxOS's own live image (iso/live-image.nix, added in
  2e874ed at 2026-11-11 22:09, in place of NixOS's installation-cd modules) doesn't
  provide it. The v0.1.0 tag (d632770) contains this. → P0 (NYX-INST-001).
  Logs: logs/install-plan.json (redacted), logs/install-plan-steps.txt, logs/install-run.log.
- With /mnt created by hand, the same plan installs in 112 s (offline, from the ISO's
  closure): logs/install-run-2.log. Installed system (no Incus agent; driven over the
  serial console with scripts/serial-run.py): LUKS prompt at 7.8 s, login prompt at
  17.6 s; `systemd-analyze` 15.5 s (firmware 1.6 + loader 3.5 + kernel 0.8 + initrd 6.4
  incl. passphrase + userspace 3.1); no failed units; 8.2 GiB store; zram 2.9 G + 4 G
  swapfile; firewall 12100 tcp/udp, 5353 udp, ICMP (no 22: SSH off by default); new user
  `amy` is in `input` (NYX-SEC-004 on a real install). logs/installed-state.txt.
- Machine flake: `nyxos.url = github:nyxos-project/nyxos/stable`, but flake.lock pins
  nyxos to `path:/nix/store/wn5hsy…-source` (the ISO's copy, lastModified 0). That path is
  not a GC root and not in the system closure (`nix-store --gc --print-dead` lists it).
  After running the weekly `nix-gc.service` (timer: Monday), `sudo nyx-system set
  time-zone America/Denver` fails: "The new system couldn't be built: path
  '//nix/store/wn5hsy…-source' does not exist; the change was undone". `nyx update
  --dry-run` and `nyx update check` still say "Everything is up to date", so nothing
  repairs it. → P1 (NYX-INST-002): from the first weekly GC (≤ 7 days after install),
  every System Manager change (Settings, Welcome's system part, Store system apps,
  recovery rebuilds) fails. logs/installed-gc-rebuild*.txt, installed-after-gc-*.txt.
  The lock also records `nyxos-overrides` as `path:/mnt/etc/nyxos/overrides` (Nix warns
  on every rebuild; cosmetic).
- `nyx update status` on the fresh install: "NyxOS (stable) with the system", 21 apps
  built in, fwupd not installed. `nyx system generations` shows 1 (raw timestamp).
- Greeter (shots/installed-greeter.png): user card, password focused, "Press Enter to
  sign in", session "Hyprland (uwsm-managed)" (technical wording), power buttons; the
  vertical wordmark shows only "NYX" at 1280×800 ("OS" off-screen). A second greetd
  client can't start a session while the greeter holds one ("a session is already being
  configured"), as designed.
- Typing the password into the real greeter (wtype on the greeter's compositor): the
  user's Hyprland was up 2.0 s later; at +30 s Welcome is open on its first page (14
  steps), bar/dock/wallpaper layers present, no failed user units, all shell services
  running (shots/installed-first-login.png).
- Per-user apps (as Welcome installs them: `nyx-system catalog install calendar mail
  --yes`, from `github:nyxos-project/nyxos/stable`, i.e. the 2026-11-09 builds):
  Calendar installs (16 s); **Mail then fails**: "An existing package already provides
  the following file: …nyx-calendar…/share/nyx/autostart; conflicting file from the new
  package: …nyx-mail…/share/nyx/autostart". nyx-packages writes that file per package
  (lib/default.nix:180 on main, so main is affected too). Packages with an autostart
  file: Welcome tier Calendar, Mail, Passwords, Home, Assistant; Store tier Reminders,
  Clipboard, Transfer, Cloud (and system-only shell packages). → P1 (NYX-PKG-008): any two
  of those chosen in Welcome or the Store, per user, fail. logs/installed-per-user-apps*.txt
- Per-user Calendar right after install: its D-Bus name isn't activatable (only
  system-installed names are), `nyx calendar` is "not a recognised command" (the
  actions registry lists only system apps), `nyx-calendard` is linked but disabled until
  the next sign-in. Glimpse plugin is in `~/.nix-profile/share/nyx-calendar/glimpse`.
  Confirms CALENDAR-002 / MAIL-002 class of issues (D-Bus activation and actions for
  per-user apps).

## Phase D in the dev VM (snapshot `audit-baseline` taken 01:30)

- smoke-apps dock and glimpse (evidence/smoke-dock, smoke-glimpse): 46 of 48 launcher
  entries open both ways (44 windows + Clipboard and Glimpse overlays, each closed by
  Escape). NO-WINDOW: "Foot Server" and "uuctl" (helper entries that shouldn't be in the
  launcher). Recurring log lines: `nyx-dock/CardPopup.qml:75: Unable to assign
  [undefined]` on nearly every launch; "Failed to register: Unable to acquire bus name"
  for Files, Music and Settings (window opens anyway); Quickshell "Could not register app
  ID: App info not found for 'org.quickshell'".
- NYX-SHELL-001 confirmed (logs/shell-qs-crashloop.txt, shots/shell-qs-crashloop.png):
  five SIGKILLs of nyx-shell-qs restart it (2 s); the sixth within a minute →
  `failed (Result: start-limit-hit)`, layers: wallpaper only (no bar, dock, CC,
  Glimpse). `systemctl --user start` is refused until `reset-failed`. Nothing (Shell
  Core included) brings it back; NRestarts had been 0 before the test.
- NYX-SHELL-002 partly: with Glimpse open, SIGKILL of Shell Core → Escape still closed
  Glimpse (not reproduced). With Shell Core stopped, `nyx-glimpse --toggle` (the Super+
  Space command) opens nothing (confirmed). The first toggle 2 s after Shell Core came
  back did nothing; later toggles work. Shell Core: 3 min 53 s CPU over 21 h, 10.3 MB
  peak. (wtype key presses reach focused surfaces but don't trigger Hyprland binds, so
  binds were exercised by running their command.)
- Single SIGKILL of each backend (bar, dock, CC, glimpse, notification-center, notifyd,
  switcher, themed, fluxd, nyx-aid, clipboardd): each restarted within 4 s and its
  surface/name came back; the AI endpoint answered /health again (worker stopped until
  next use). logs/shell-backend-kills.txt. `notify-send` isn't installed on NyxOS.
- Lock screen (logs/lock-crash.txt, shots/lock-*.png): `loginctl lock-session` →
  Nyx Locker (face first, "Use password"), LockedHint yes. SIGSEGV of the locker
  (`.nyx-locker-wrapped`) → hyprlock takes over within 3 s (session stays locked);
  SIGKILL of hyprlock → nyx-lock.service restarts (NRestarts 1) and Nyx Locker is back;
  LockedHint stayed yes throughout; a window launched while locked (Calculator) never
  appeared over the lock. Typing the test password unlocked (LockedHint no). The lock
  chain is robust: no bypass found.
- Rollback (logs/rollback.txt): `nyx-system rollback` (root) 245 → 244 in 4 s, history
  entry written ("reboot": true). Switched forward to 245 again (2 s). Shell kept running.
  (Generation 245 is another session's rebuild at 00:56, nyxos f835ed6 / nyx-packages
  9557afd: differs from the audited pins only by nyx-files c1e7cca.)
- Hyprland (logs/hyprland-fullscreen.txt): `fullscreen_own_workspace` works: fullscreen
  moves the window to a named workspace `fullscreen-1-1` (hyprctl reports `"id": null`
  for it); leaving returns it to workspace 1; closing while fullscreen returns to
  workspace 1 and the named workspace disappears. Workspace wrap: m+1 from 5 → 1, m-1
  from 1 → 5. The fullscreen screenshot shows no bar (expected in fullscreen).
- Theme (logs/theme-switch.txt, shots/theme-mocha-live.png): `nyx-theme set
  catppuccin-mocha` → bar repainted within 375 ms; a running Calculator repainted to
  Mocha's surface.primary #1e1e2e without restart; bar and app consistent. Set back to
  nyx-dark (the dev user's choice).
- Accessibility (logs/atspi-buttons.txt): **the session has `GTK_A11Y=none` and
  `NO_AT_BRIDGE=1`** (/etc/set-environment) and no `org.a11y.Bus`: NixOS's
  at-spi2-core module sets those when `services.gnome.at-spi2-core.enable` is false
  (nixos/modules/services/desktops/gnome/at-spi2-core.nix:47-50), and NyxOS never enables
  it. No screen reader or other AT can work on any NyxOS install → P1 (NYX-A11Y-001).
  With the bus started by hand and the variables removed for six apps: Notepad 8/8,
  Files 26/26, Calculator 32/32, Mail 29/29, Settings 55/55 visible buttons have an
  accessible name (GTK4 falls back to the tooltip, so the "tooltip only" concern in
  OFFICE-002 doesn't hold for GTK apps); Store 4 of 60 unnamed ("Browse graphics" etc.
  carry only a description). The Quickshell surfaces (bar, dock, panels) weren't on the
  bus: not verified.
- Archive zip slip (logs/archive-zipslip.txt): crafted zip (`../../x`, `/tmp/x`, a
  symlink `link → /tmp` then `link/x`) extracted with nixpkgs 7zz 26.04 and the app's own
  switches (`x -y -aoa -o<dest> -bsp1 -bso0 -bse1`): `../` stripped, absolute path made
  relative, writing through the symlink refused ("Not a directory", exit 2). Nothing
  escaped the destination. The symlink itself is left in the destination (pointing at
  /tmp). ARCHIVE-002 not reproduced with the shipped 7-Zip.
- Backup (logs/backup-restore*.txt): CLI flow on a local repository: config import,
  generated password (Secret Service), test, init (2.4 s), preview (4 files, 5 MB), approve,
  backup (1.0 s, snapshot c62c23ca…), full verify (0 errors), damage the source, restore
  plan → apply into a separate folder: all three files **byte-identical** (sha256) and
  the symlink restored; restore and rollback receipts kept. Backup's restore is verified
  on NyxOS for the local-destination, separate-folder case. (A second, in-place attempt
  used `--target $HOME`, which restores under `$HOME/home/ken/…`: tester error; in-place
  replace not exercised.) `schedule --enable` writes `nyx-backup-audit.timer` whose
  service has `ExecStart="/nix/store/ipa974…-nyx-backup-…/bin/nyx-backupctl" backup audit
  --wait`: a store path, confirming BACKUP-001's premise (breaks once that path is
  garbage-collected after an update).
- Connect with fluxd stopped (logs/connect-fluxd-stopped.txt,
  shots/settings-devices-fluxd-stopped.png): `nyx devices list` says "Flux isn't
  running"; capabilities report `daemon:flux inactive` with the reason; Settings ›
  Connected Devices shows "Flux isn't running … Start Flux". Restarting fluxd recovers.
  Pairing, clipboard and notification relay with a real phone: not verified (no phone).
- Not exercised at runtime: Office round-trip of .docx (GUI-only save path), Welcome's
  "Review and apply" end to end, graphical installer (keyboard-layout issue
  INSTALLER-001), suspend/resume, Bluetooth, Wi-Fi, multi-monitor on hardware.

## Phase E observations (shots/montage-apps-*.png from the smoke screenshots)

- 24 app windows side by side: consistent sidebar + header + content structure, same
  type scale, same icon style and accent use, empty states with an icon, a line and one
  primary button (Git, Home, Theater, Photos, Contacts). Design consistency is good.
- Outliers: Notes' first run is a separate 620×420 dialog (same background as the suite,
  but flat buttons and larger body text than the rest of the suite); Lyra's content is YouTube
  Music's own web page (its colours, type and layout), with only the header in Nyx style;
  Passwords opens to a small centred unlock card on an empty window.

## Phase F measurements and failure tests (dev VM)

- Idle (logs/perf-idle.txt), all windows closed, 60 s: whole VM 1.7 % CPU (of 6 vCPU);
  2.3 GB used of 16 GB (+0.9 GB swap from earlier); user processes 1.6 GB RSS in 128
  processes; largest: Quickshell (bar/dock/CC/OSD/Glimpse) 297 MB, clipboard UI 140 MB,
  llama-server 75 MB (no model loaded), glimpse backend 50 MB, Hyprland 49 MB. 52 user
  and 25 system services running (the dev VM enables every Welcome app). Root services
  ≤ 35 MB each. Dev VM boot 13.9 s; system closure 11.4 GiB. Installed base system:
  15.5 s boot incl. LUKS prompt, 8.2 GiB store, 1.07 GB used at the login screen.
- App start to first window (logs/perf-app-startup.txt, warm cache, two runs): 0.45–0.94 s
  (Store 0.45-0.50, Calculator/Notepad/Passwords ~0.52, Files 0.75-0.80, Mail 0.72-0.89,
  Settings 0.91-0.94); RSS 4 s after start 130–235 MB per app (Calculator 131, Notepad 133,
  Files 208, Settings 233, Lyra 235). Two artefacts (a window still open) excluded.
- AI Core in the VM: model load 5.3 s, cold first request 41 s, warm 6.9 s for 16 tokens of
  a 135M model on CPU emulation without GPU offload: not representative; unmeasured on
  hardware.
- Network loss (logs/network-loss.txt, shots/offline-*.png): `nyx update` says "there's no
  network connection, so nothing can be checked or downloaded" (good); catalog install
  and `nyx-ai pull` print raw Nix/HTTP errors ("unable to download
  'https://api.github.com/…' Could not resolve hostname"); Store shows the raw Flathub
  error text in its header; Weather keeps showing cached data with no visible offline
  note. Network back: all recover.
- Low memory (logs/low-memory.txt): a process touching 256 MB chunks drove MemAvailable to
  30 MB within 41 s; the kernel OOM killer killed only that process (its scope reported
  `oom-kill`); no user service was lost; bar/dock/wallpaper stayed. systemd-oomd is
  active but didn't act first. (stress-ng runs capped themselves and caused no pressure.)
- Monitor hotplug (logs/monitor-hotplug.txt, shots/monitor-added*.png): a headless output
  added to the VM's Hyprland gets the wallpaper and Glimpse opens on it when focused, but
  **the bar and the dock never appear on it** (checked at 2, 5, 10 and 20 s; no
  per-monitor setting in bar/dock config). Removing it leaves the shell intact on
  Virtual-1, no service restarts. Confirm with a physical second display (headless
  outputs may differ), but as observed new monitors get no bar or dock.
- Disk full (logs/disk-full.txt): XDG config/data/state/cache on a full 8 MB tmpfs:
  Calculator, Notepad, Files and Notes all start and show their windows (Files logs "No
  space left on device" for its assets and open tabs and carries on); `nyx-system config
  set` reports "No space left on device (os error 28)"; `nyx-theme app set` reports
  "could not write …/theme.toml". No crash, no partial config observed.
- Interrupted System Manager change (logs/interrupted-system-change.txt): `nyx-system
  service fwupd on`, System Manager SIGKILLed 6 s in (during the build): client gets
  "Remote peer disconnected"; **/etc/nyxos/overrides/system.json keeps `"fwupd": true`**
  although nothing was built or switched; no history entry. The overrides layer now
  differs from the running system, so the next unrelated change would also turn fwupd on
  (P2, NYX-REL-002). A following change (`fwupd default`) built and switched normally, so
  the manager isn't stuck. (That created a new generation; the snapshot restore undoes it.)
- Config corruption (logs/config-corruption.txt): invalid `dock.toml` → the dock keeps it
  as `dock.toml.broken-<time>` and starts on defaults (good). Invalid `theme.toml` → the
  file is left as is and `nyx-theme get` reports the system default (Catppuccin Mocha)
  instead of the user's Nyx Dark, with no message: a typo silently resets the user's theme
  (matches NYX-THEME-003's class). Both files restored afterwards.
- Not tested: suspend/resume (VM), GPU reset, Bluetooth, Wi-Fi, battery, fingerprint and
  camera hardware, physical multi-monitor, HiDPI scaling on real displays.
- Dev VM restored to snapshot `audit-baseline` (generation 245, as left by the other
  session) and the snapshot deleted; `nyxos-install-test` left stopped with its
  `fresh-install` snapshot.
