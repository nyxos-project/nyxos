# Working notes (candidates; final text goes in ../issues.md)

Next free numbers: SYS 002, SEC 015, PRIV 007, DOC 006, UX 005, SHELL 009, DEP 006, ARCH 011,
SET 003, REL 004, PERF 003, AI 005, A11Y 004, THEME 006, PKG 010, CI 008, UPD 003, INST 004,
HYPR 010; APP-BROWSER 001 (new), APP-TV 001 (new); apps: see release-readiness/issues.md.

## Pass 1 baseline
- All 70 checkouts on main, nothing unpushed. heads.tsv.
- C1 (CI/P3): uncommitted shared-crate bump (nyx-core 32f0c5e→94e0c8a, nyx-design 4f8e16d→ea8839d)
  in Cargo.toml/Cargo.lock of ~53 app repos, mtime 2026-11-14 11:28, never committed. Stale
  working trees; any `git commit -a` in those repos ships an untested bump.
- nyx-packages pins behind main by 1: nyx-archive, nyx-notepad, nyx-pdf, nyx-photos (the W4
  data-safety fixes of 14 Nov aren't in NyxOS yet). Not a bug; note in README.
- CI green on nyxos + nyx-packages main and stable.

## Pass 2 OS / update
- Verified OK: Hyprland permission rules (RE2::FullMatch, first match wins: allow rules before
  the catch-all deny work; Hyprland/src/managers/permissions/DynamicPermissionManager.cpp:113).
  Browser release asset public (HTTP 200). oneshot nyx-shell-failed has no start timeout.
- C2 (UPD/P2): `nyx install nyx-<app>` resolves to github:nyxos-project/nyx-packages#… =
  that repo's default branch (main, development), not stable and not signature-checked
  (nyxos/pkgs/nyx-cli/nyx.sh:43), while Welcome/Store use github:nyxos-project/nyxos/stable#….
  run.rs:248 only verifies elements whose url starts with nyxos/stable.
- C3 (UPD/P3): profile(): verifies ls-remote head of stable, then `nix profile upgrade` resolves
  the branch again by itself (not pinned to the verified rev); ls-remote there has no
  GIT_TERMINAL_PROMPT=0 and its exit status isn't checked (nyx-update/src/run.rs:250-254).
- C4 (UPD/P3): no rollback protection: verify() accepts any signed known-good tag at the rev, so
  a stable branch moved back to an older signed release installs (signed.rs:78).
- C5 (PKG/P2): nyx-browser wrapper sets MOZ_SYSTEM_DIR=$out/lib/mozilla/native-messaging-hosts
  (nyx-packages/pkgs/nyx-browser.nix:135) but the engine appends native-messaging-hosts to it
  (engine NativeManifests.sys.mjs:184; patch nsXREDirProvider-cpp.patch) → system lookup is
  $out/lib/mozilla/native-messaging-hosts/native-messaging-hosts/…: never found. Works only
  through the ~/.mozilla symlink made by userActivationScripts. smoke.py:65 only checks the
  variable is echoed back. CONFIRM IN VM.
- C6 (PKG/P2): Passwords' native host is linked into ~/.mozilla only when nyx.passwords.enable
  (system-wide). New installs are per-user (standaloneApps = per-user; Welcome installs
  Passwords into the profile) → no manifest for Browser/Firefox → autofill bridge not found.
  nothing in nyx-system handles native-messaging for profile apps. CONFIRM IN VM.

## Pass 2 installer (nyx-installer 46d13f2)
- C7 (APP-INSTALLER-005 / P1 data loss): leftovers = any partition named "NyxOS EFI"/"NyxOS"
  on a disk that also has other partitions (disks.rs:41-43, 91-94). A FINISHED install beside
  Windows has exactly those names. Booting the live USB on a working dual-boot machine shows
  "An earlier install didn't finish … Remove them" (pages.rs:243-265): one click, no
  confirmation, runs wipefs --all + sgdisk --delete on the working NyxOS (plan.rs:113-131).
  Text also says "nothing else is touched". No completion marker distinguishes the two.
  Same for `nyx-install remove-leftovers DISK --yes`.
- C8 (INST-004 / P1): no firmware check. Guide says the USB starts on BIOS but NyxOS installs
  only on UEFI (docs/guide/requirements.md:8); the installer never looks at /sys/firmware/efi
  (grep: nothing). host.nix always has canTouchEfiVariables = true, Limine efiSupport only
  (nyxos modules/nixos/boot.nix:88). A BIOS/CSM-booted live session erases the disk, then
  fails at "Installing NyxOS" (or installs something that can't boot). static; confirm.
- C9 (APP-INSTALLER-006 / P3): a password with ":" is refused (choices.rs:210, plan.rs:173);
  chpasswd splits at the first colon, so only the login can't have one.
- OK: 4Kn math, gap check, GUID use, nix_str escaping, secrets not in the log, gcroot.

## Pass 2 system manager / recovery: read, no findings
- recovery sign-in (nyx-system apps/recovery/src/signin.rs): fails closed on EOF/Ctrl+C; opens
  without a password when no wheel/root account has a usable hash (by design G7), which
  includes "every admin account locked" (hash starts with !). Note only.
- staged overrides (rebuild.rs): fine.

## Pass 3 security
- C10 (APP-ARCHIVE-004 / P3): Archive's own pre-check (c99343c) is bypassed by (a) names with
  a leading "./" — 7-Zip lists "./l2" as stored, and "l2/evil.txt".strip_prefix("./l2") fails
  (parse.rs extraction_risk); (b) link chains — link_escapes counts path depth, so
  d/l1 -> ".." and l2 -> "d/l1/.." pass though l2 resolves above the folder. Tested with
  7-Zip 26.04 on a crafted tar: Archive's logic reports no risk; 7-Zip itself refuses
  ("Dangerous link path was ignored"), so nothing escapes today. The README's "doesn't
  depend on its version" isn't true for these two shapes.
- OK (no finding): nyx-ai endpoint key/Host check (185369e); nyx-capability watcher fix
  (only nyx-settings uses the crate, pinned at aac46eb); Passwords daemon/bridge diff;
  System Manager may_read.
- C11 (APP-CLOUD-003 / P2): Cloud's encrypted rclone.conf with a missing or different keyring
  item (nyx-cloud d22475d src/main.rs encrypt_config + src/secret.rs): (a) Secret Service
  absent → pass None, rclone runs on an encrypted file with no password, log line says "the
  configuration isn't encrypted"; (b) keyring recreated / ~/.config restored on another
  machine → config_password() makes a NEW password, encrypt_config() sees the file is already
  encrypted and returns Ok, rclone gets the wrong password. Either way every account
  silently stops working; nothing detects "can't decrypt" or tells the person. static.

## Pass 4 data safety
- C12 (ARCH-011 / P3): nyx_core::cmd::atomic_write (nyx-core crates/nyx-core/src/cmd.rs:132),
  now every Notepad save: needs a writable folder (a writable file in a read-only folder
  can't be saved: "Couldn't save"), drops owner/group, ACLs and xattrs, breaks hard links,
  and its temp name (.NAME.tmp-PID, File::create follows links) is predictable in shared
  folders. No fallback to writing in place.
- Notepad encoding/closed-tab code read (doc.rs 560-760): asks before lossy saves. OK.
- C5 CONFIRMED in VM (gen 266): wrapper exports MOZ_SYSTEM_DIR=…/lib/mozilla/native-messaging-hosts;
  only ~/.mozilla/native-messaging-hosts links exist. C6 not testable in the dev VM
  (passwords.enable = true there); static.
- C13 (APP-BROWSER-001 / P1 privacy): VPN bypass pattern matches public hosts.
  nyx-browser 37d7341 src/nyx/modules/NyxVpn.sys.mjs:31 LOCAL = /^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|…)/
  has no end anchors on the address alternatives, and hosts aren't checked to be IPs:
  10.attacker.com, 127.evil.net, 192.168.example.org, 172.16.tracker.io and
  localhost.attacker.com all test true (node), so bypassed() sends them direct. Any page
  can embed such a host and read the real address with the VPN and kill switch on.
- C14 (APP-BROWSER-002 / P3): requests with no tab (service workers, prefetch, system) use only
  state.active; with a per-workspace VPN and the main switch off they go direct
  (connectionFor, same file). And before nyx-vpn.json is read every request is refused when the
  kill switch pref is on (default), also for people with no VPN (applyFilter `!state`). static.
- nyx-tv: audit/ is gitignored, no tracked secrets; usesCleartextTraffic=true (note, not 0.1).
- No tracked secrets suite-wide (only test fixtures); no todo!/unimplemented!/FIXME in src.

## Runtime (VM gen 266)
- W1/W2 checks hold: ptrace_scope=1, ken not in input, a11y bus up and no NO_AT_BRIDGE,
  53317 open, 12100 only via empty nyx-trusted-net chain, fluxd inactive (unpaired),
  openai socket not enabled, no "Ignoring duplicate name", OnFailure set on both shell units,
  plugins under /etc, release-signers present, 0 failed units.
- C15 (THEME-006 / P3): nyx-icons copies third-party launchers into ~/.local/share/applications
  (Helix, btop, foot, Irlume in the VM). On NyxOS only `nyx-icons sync` runs (activation, theme
  change), and sync never cleans up (nyx/tools/icons.py:448 "cleaning up removed apps is left
  to generate"): a removed app keeps a launcher entry with a dead Exec. Irlume's copy holds a
  /nix/store Exec/TryExec.
- C16 (HYPR-010 / P2, to confirm): screencopy allow rules name store paths and Hyprland reads
  permission rules only at start (comment in nyxos modules/home/hyprland.nix). After an update
  that changes nyx-dock/switcher/grim/portal paths the running session's rules are for the old
  paths: capture is refused or asks each time until next sign-in. Plugins were moved to /etc
  for this reason; capture programs weren't.

## Pass 5 shell (started; only nyx-shell's server.rs, peer.rs, units and ShellCore.qml diff read)
- S1 (SHELL-009 / P2 candidate, static): Shell Core reads /etc/nyx/trusted-bin once
  (nyx-shell crates/nyx-shell-core/src/peer.rs:36-42, Trust::standard; refreshed only when
  ipc.ui_runtimes changes, server.rs run loop) and trusts its own folder at start. After a
  NixOS update the new nyx-settings / quickshell / nyx-shellctl store paths aren't in the
  running core's list, so they classify as read-only (no ConfigWrite, no OverlayManage) until
  Shell Core restarts. Every other user (nyx-peer::program) reads the file per call.
  Same shape as NYX-HYPR-010. Confirm: does a switch restart nyx-shell-core?
- S2 (SHELL-010 / P3): accept loop `let Ok(..) = listener.accept().await else { continue }`
  (server.rs accept) spins without a pause on a lasting error (EMFILE).
- S3 (SHELL-011 / P3): nyx-shell-qs.service and nyx-shell-core.service are Restart=on-failure:
  a clean exit of Quickshell leaves no bar/dock and doesn't trigger OnFailure.
- S4 (note): offline overlay toggling in ShellCore.qml (27dca32) skips the panels' exclusive
  group, so two overlays can be open while Shell Core is down.
- NOT READ YET: core.rs, overlay.rs, compositor.rs, bridge.rs; all of nyx-bar, nyx-dock,
  nyx-switcher, nyx-control-center, nyx-notification-center, nyx-glimpse, nyx-clipboard,
  nyx-desktop-widgets.
- S1 partly confirmed in VM: nyx-shell-core has run since 03:35 across the switches to gens
  261-266 (not restarted by a switch); paths didn't change in that span so no visible effect.
- S5 (APP-ASSISTANT-009 / P2, CONFIRMED): with the Assistant's daemon not running (never set
  up), nyx-assistant-hud.service and nyx-assistant-visual.service still run, and their QML
  restarts `nyx-assistant listen` for ever: every 1 s (apps/assistant/quickshell/shell.qml
  restartTimer, 1000 ms, no backoff) and every 2 s (Aura/Main.qml restart, 2000 ms). VM idle:
  15 such starts in 15 s, each failing "connect …/assistant.sock: No such file"; 170 forks
  per 20 s overall; .nyx-assistant visual process at 8.5 CPU-minutes in 16 h.
- S6 (SHELL-012 / P3): nyx-bar's privacy plugin runs `pw-dump` every 3 s for ever
  (nyx-bar plugins/privacy/src/main.rs:5,122) and its system plugin polls wpctl; seen in VM.
- S7 (SEC-015 / P3): Notification Center's "only Nyx programs read stored notifications"
  (7711cea) checks the D-Bus caller's exe, but the store is ~/.local/share/nyx/notifications.db
  (0600, the user's): any program of that user reads it directly. pid->exe lookup is also racy.
- OK: dock swipe plugin (null checks, hash check, unload), Control Center providers poll only
  while subscribed, NyxTheme.qml timers bounded, vendored NyxTheme copies identical.

## Pass 7 suite-wide (done)
- clippy --workspace --all-targets on clean exports of HEAD: nyx-installer, nyx-system,
  nyx-archive, nyx-notepad, nyx-cloud: only style lints (collapsible if, sort_by_key) under
  rustc 1.99; nothing substantive. cargo test NOT rerun: every package's tests run in the Nix
  build that CI does on each pin (CI green); host too short on memory/tmp for more.
- Shell command strings in apps: all constant, quoted (Chat's Piper line uses shell_quote) or
  behind an approval (Chat run_shell asks first, tools/mod.rs:197). No finding.
- VM: every launcher Exec and Icon resolves; every Nyx D-Bus service and user unit points at
  an existing program; /usr/bin holds only env.
- 211 hard-coded /usr/... paths in app code; nearly all in Arch-only code (Store's
  pacman/AUR/BlackArch, Settings' helper) = W6. On NyxOS paths that still matter:
  nyx-settings backend/cleanup.rs:76,80 (/usr/bin/du, /usr/bin/nice: sizes come back 0) —
  check the Storage page in the VM; nyx-biometrics nyx-authctl enroll.rs:300 (/usr/bin/systemctl,
  result ignored; NyxOS sets the socket up in its module, so harmless).
- Icon buttons with neither tooltip nor accessible name (STYLE.md): nyx-chat quick.rs:105
  (send), sections/chat/composer.rs:828 and panel.rs:267 (close), view.rs:284,294 (branch
  prev/next); nyx-notes window.rs:854 (add folder); nyx-activity processes.rs:434 (expander).
## Pass 6 (reading)
- Mail sorted.rs imbox(): with "Previously seen" chosen and every conversation unread, nothing
  is appended: a blank page under the head (no "nothing seen yet" line).
- Calendar: week should open at prefs.day_starts (8) but opened at midnight in the VM;
  days.rs:167-171 sets the adjustment in one idle before the view has its height (upper -
  page_size <= 0 -> 0). The "Scroll to" setting has no effect at launch.
- Welcome (bfaa1bf): a second launch presents the open window but its --step/--select/--preset
  are dropped (main.rs: run_with_args(&[]) and activate returns early), so Settings' and the
  Store's buttons that open Welcome at a step do nothing visible when it's already open.
- Transfer mirror: previewed and confirmed. OK.
