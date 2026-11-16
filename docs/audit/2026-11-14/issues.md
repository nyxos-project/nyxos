# Issue register, 2026-11-14

Findings of the second audit, in the format of
[../release-readiness/evidence/FINDINGS-FORMAT.md](../release-readiness/evidence/FINDINGS-FORMAT.md).
IDs continue each area's numbering from the [first register](../release-readiness/issues.md).
Findings already open there aren't repeated. "static" means found by reading the code and
not yet reproduced on a running system.

## P1

### NYX-APP-INSTALLER-005: "Remove them" deletes a working NyxOS installed beside another system

- **Component:** nyx-installer `crates/nyx-install/src/disks.rs`, `plan.rs`, `apps/installer/src/pages.rs`
- **Category:** reliability (data loss)
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** The installer treats any partition named `NyxOS EFI` or `NyxOS` on a disk
  that also holds other partitions as left over from an install that didn't finish. A
  finished install beside Windows has exactly those partitions and names; nothing marks
  an install as complete.
- **Expected:** Only partitions of an install that failed are offered for removal
  (work-plan W3, APP-INSTALLER-002: "Detect our GUIDs and offer 'Remove what the failed
  install made'").
- **Actual:** `Partition::is_nyxos` matches by partition name only (`disks.rs:41-43`);
  `Disk::nyxos_leftovers` returns them whenever the disk has anything else
  (`disks.rs:91-94`). The disk page then shows "An earlier install didn't finish. It left
  NyxOS's partitions here (…). Removing them gives the space back for NyxOS, beside
  Windows; nothing else is touched." with a **Remove them** button (`pages.rs:243-265`).
  One click, with no confirmation, runs `wipefs --all` on those partitions and
  `sgdisk --delete` (`plan.rs:113-131`, `pages.rs:639-647`). `nyx-install remove-leftovers
  DISK --yes` does the same.
- **Reproduce / verify:** static. Install NyxOS beside Windows, finish, start the live USB
  again and choose that disk: the row appears for the working system.
- **Evidence:** the file and line references above; test `what_a_failed_install_left_beside_windows`
  (`disks.rs:320`) builds its "leftovers" from names alone.
- **Affected versions:** nyx-installer d408149 to 46d13f2 (in NyxOS since nyxos 4c1425c, on `stable` as known-good/24)
- **User impact:** Someone who starts the installer on a dual-boot computer (to reinstall,
  to install on a second disk, to look) is told their working NyxOS is a failed install,
  and one click erases it and their files.
- **Recommended correction:** Mark an install as finished (for example rename the root
  partition to `NyxOS` only in the last step, and create it as `NyxOS (installing)`), and
  offer removal only for unfinished ones; ask for confirmation naming the partitions and
  sizes; on the disk page, describe a finished NyxOS as what it is.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** After a finished install beside Windows, the live USB's disk
  page offers no removal; after an install stopped half way, it does, and asks first.

### NYX-INST-004: A live USB started in BIOS mode erases the disk and then can't install

- **Component:** nyx-installer (no check), nyxos `modules/nixos/boot.nix`, `docs/guide/requirements.md`
- **Category:** reliability (installation)
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** The live USB starts on BIOS and on UEFI (Limine for both), but NyxOS
  installs only on UEFI. The installer never checks how it was started.
- **Expected:** The installer refuses before touching the disk when the computer wasn't
  started in UEFI mode, and says how to change it.
- **Actual:** No source file of the installer reads `/sys/firmware/efi` (grep over
  `apps/` and `crates/`: nothing). `host_nix` always writes
  `boot.loader.efi.canTouchEfiVariables = true` (`plan.rs:464`) and NyxOS's Limine has
  `efiSupport` only (`boot.nix:88`). The disk is wiped in steps 1–2 (`plan.rs:240-241`);
  the boot loader is installed some 30 steps later.
- **Reproduce / verify:** static; confirm by starting the ISO in a VM with SeaBIOS
  (`scripts/install-vm` with BIOS firmware) and installing with Erase.
- **Evidence:** `docs/guide/requirements.md:8` ("The USB stick also starts on older BIOS
  computers, but NyxOS itself installs only on UEFI.")
- **Affected versions:** nyx-installer 46d13f2, nyxos ed46205
- **User impact:** On a BIOS-only computer, or a UEFI one whose boot menu started the stick
  in legacy/CSM mode (common), the install fails after the disk is erased, or ends with a
  system that doesn't start.
- **Recommended correction:** On the first page, when `/sys/firmware/efi` is missing, stop
  with "This computer started the USB stick in BIOS mode…" and no Next; also refuse in
  `Plan::validate`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A BIOS-started live session can't reach the disk page;
  `nyx-install run` refuses.

### NYX-APP-BROWSER-001: The VPN's "local addresses" exception matches public host names

- **Component:** nyx-browser `src/nyx/modules/NyxVpn.sys.mjs`
- **Category:** privacy
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** Requests to "this computer and the network it's on" skip the VPN. The
  pattern that decides it tests the start of the host name and doesn't require an IP
  address.
- **Expected:** Only loopback, private-range IP addresses and `.local`/`.localhost` names
  go direct.
- **Actual:** `LOCAL = /^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|…)/`
  (`NyxVpn.sys.mjs:31`), used by `bypassed()`. `10.attacker.com`, `127.evil.net`,
  `192.168.example.org`, `172.16.tracker.io` and `localhost.attacker.com` all match.
- **Reproduce / verify:** `node -e` with the pattern and those names prints `true` for
  each (run during this audit). In Browser: VPN on, load a page that embeds an image from
  a host named `10.<your-domain>`; the server sees the real address.
- **Evidence:** as above.
- **Affected versions:** nyx-browser 645f973 to 37d7341 (release 1.24.2b-2, in NyxOS's base)
- **User impact:** Any website can learn the real IP address of someone using Browser's
  VPN, with the kill switch on, by embedding one request.
- **Recommended correction:** Parse the host: bypass only when it is an IP literal in
  127/8, 10/8, 172.16/12, 192.168/16, 169.254/16, ::1, fc00::/7 or fe80::/10, or the name
  is exactly `localhost` or ends in `.local`/`.localhost`. Add the names above to
  `nyx/tests`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A test asserts those five names go through the VPN.

## P2

### NYX-PKG-010: Browser's system native-messaging folder is one level off

- **Component:** nyx-packages `pkgs/nyx-browser.nix`, `modules/nixos/default.nix`
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** verified
- **Description:** The wrapper sets `MOZ_SYSTEM_DIR` to
  `$out/lib/mozilla/native-messaging-hosts`; the engine appends `native-messaging-hosts`
  to that folder itself, so it looks in
  `…/native-messaging-hosts/native-messaging-hosts/`, which doesn't exist.
- **Expected:** Browser finds its own bridge's manifest from the package.
- **Actual:** `nyx-browser.nix:135`; engine `toolkit/components/extensions/NativeManifests.sys.mjs:184`
  (`PathUtils.join(dir, TYPES[type], name + ".json")`) with
  `nyx/patches/toolkit/xre/nsXREDirProvider-cpp.patch`. The bridge works only through
  the links a user activation script puts in `~/.mozilla/native-messaging-hosts`
  (`default.nix`, `nyx-browser-native-hosts`). `nyx/tests/smoke.py:65` checks only that the
  variable is read back.
- **Reproduce / verify:** in the VM: `grep MOZ_SYSTEM_DIR $(readlink -f /run/current-system/sw/bin/nyx-browser)`
  shows the `…/native-messaging-hosts` path; that folder holds the `.json` directly.
- **Evidence:** VM generation 266, 2026-11-14.
- **Affected versions:** nyx-packages 9045e4c
- **User impact:** None while the activation script's links exist; Share, Capture,
  Assistant and the theme in Browser stop for an account whose `~/.mozilla` links are
  missing or stale (a new user before activation ran, a cleaned home folder).
- **Recommended correction:** `--set MOZ_SYSTEM_DIR "$out/lib/mozilla"`; make the smoke
  test look a host up through it.
- **Effort:** S
- **Dependencies:** NYX-PKG-011
- **Verification criteria:** With `~/.mozilla/native-messaging-hosts` removed, Browser's
  Share button still reaches the bridge.

### NYX-PKG-011: Passwords installed from Welcome has no native-messaging manifest for Browser or Firefox

- **Component:** nyx-packages `modules/nixos/default.nix`; nyx-system (profile changes)
- **Category:** packaging / functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The manifests browsers need to start Passwords' bridge are installed
  only when `nyx.passwords.enable` is set for the whole system. New installs are
  `standaloneApps = "per-user"`, where Welcome puts Passwords in the person's Nix profile.
- **Expected:** Passwords from Welcome fills logins in Browser (Passwords' extension is
  built into Browser) and Firefox.
- **Actual:** `programs.firefox.nativeMessagingHosts`, the Chromium manifest in `/etc` and
  the `~/.mozilla` link are all inside `lib.mkIf cfg.passwords.enable`
  (`default.nix`, "The browsers find the Passwords bridge…" and
  `nyx-browser-native-hosts`). Nothing in nyx-system's profile handling
  (`nyx-catalog::after_profile_change`) writes a manifest (grep for `native-messaging`:
  nothing).
- **Reproduce / verify:** static (the dev VM sets `passwords.enable = true`). On an
  installed NyxOS: install Passwords in Welcome, open Browser; the extension reports no
  host.
- **Evidence:** as above; first audit's NYX-APP-PASSWORDS-001 covered the missing
  extension, which now ships.
- **Affected versions:** nyx-packages 9045e4c
- **User impact:** Autofill, now advertised again, doesn't work on a fresh install.
- **Recommended correction:** After a profile change, link every
  `~/.nix-profile/lib/mozilla/native-messaging-hosts/*.json` into
  `~/.mozilla/native-messaging-hosts` (and Chromium's user folder), as autostart.d is
  handled; remove stale links.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** On an installed VM, Passwords from Welcome pairs with Browser.

### NYX-UPD-003: `nyx install nyx-APP` takes the app from nyx-packages' development branch

- **Component:** nyxos `pkgs/nyx-cli/nyx.sh`; nyx-system `crates/nyx-update/src/run.rs`
- **Category:** security / reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Welcome and the Store install Nyx apps from the signed channel
  (`github:nyxos-project/nyxos/stable#…`). The `nyx` command maps `nyx-*` names to
  `github:nyxos-project/nyx-packages#…`, which is that repository's default branch.
- **Expected:** One source for an app whichever way it's installed; stable machines get
  only signed releases (G9).
- **Actual:** `nyx.sh:43`. `profile()` checks a signature only for elements whose URL
  starts with `github:nyxos-project/nyxos/stable` (`run.rs:248`), so these update from
  `main` unchecked.
- **Reproduce / verify:** `nyx install nyx-pdf; nix profile list` shows the
  nyx-packages URL.
- **Evidence:** as above; README documents the mapping.
- **Affected versions:** nyxos ed46205, nyx-system c1d9c8a
- **User impact:** An app installed from the terminal runs unreleased code, can differ
  from the same app in the Store, and bypasses the release signature.
- **Recommended correction:** Resolve `nyx-*` through the catalog to the machine's channel
  (`nyx_catalog::channel_from_lock`), as the Store does.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `nyx install nyx-pdf` on a stable machine adds
  `github:nyxos-project/nyxos/stable#nyx-pdf`.

### NYX-APP-CLOUD-003: Cloud's accounts silently stop working when the keyring item is missing

- **Component:** nyx-cloud `src/main.rs` (`encrypt_config`), `src/secret.rs`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Since d22475d, `rclone.conf` is encrypted with a password kept in the
  Secret Service. Nothing handles an encrypted file whose password isn't there.
- **Expected:** Cloud says the accounts can't be opened and why, and offers to start over.
- **Actual:** (a) No Secret Service: `pass` is `None`, rclone is started on the encrypted
  file without a password, and the log says "the configuration isn't encrypted".
  (b) Keyring recreated, or `~/.config` restored on another computer:
  `config_password()` finds no item and makes a new password; `encrypt_config()` sees the
  file already starts with rclone's encrypted header and returns `Ok`; rclone gets the
  wrong password.
- **Reproduce / verify:** static. Delete the "Cloud Storage configuration" item from the
  keyring and restart `nyx-cloudd`.
- **Evidence:** `src/main.rs` `encrypt_config` (the `starts_with(ENCRYPTED)` early return),
  `src/secret.rs:19-39`.
- **Affected versions:** nyx-cloud d22475d
- **User impact:** After a keyring reset (a password reset from Recovery makes one) or a
  restore from Backup without the keyring, every cloud account is gone with no message.
- **Recommended correction:** After getting the password, run `rclone config show` (or
  `listremotes`) with it; on failure show "Cloud can't open its saved accounts" with a
  choice to remove them and start again. Don't create a new password when the file is
  already encrypted.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** With the keyring item deleted, Cloud shows the message and
  doesn't write a new item.

### NYX-HYPR-010: Screen-capture permission rules go stale when an update changes the programs' store paths

- **Component:** nyxos `modules/home/hyprland.nix` (`screenCapture`, `permissions`)
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The `screencopy` allow rules name the Nix store paths of the portal,
  Nyx's grim and wf-recorder, the Switcher and the Dock. Hyprland reads permission rules
  only when it starts (the module's own comment), and an update gives those programs new
  paths.
- **Expected:** Capture keeps working in a running session after an update (the reason the
  plugins were moved to `/etc/nyxos/hyprland-plugins` in d547f6e).
- **Actual:** `hyprland.nix` builds `hl.permission("<store path>/.*", "screencopy", "allow")`
  per program, then `hl.permission(".*", "screencopy", "deny")`. After a switch the
  restarted Dock and Switcher, Capture's grim and the portal run from paths the session's
  rules don't list; the comment says a session that reloads "asks about every capture
  until the next sign-in".
- **Reproduce / verify:** static; not reproducible in this run (generations 264–266 have the
  same Dock, Switcher and Capture paths). Update one of them without signing out, then
  take a screenshot and open the Switcher.
- **Evidence:** VM `~/.config/hypr/hyprland.lua` (9 `hl.permission` lines); Hyprland
  `src/managers/permissions/DynamicPermissionManager.cpp:113` (rules match the client's
  executable path with `RE2::FullMatch`).
- **Affected versions:** nyxos ed46205
- **User impact:** After most updates, screenshots, recordings, screen sharing and window
  thumbnails are refused or prompt until the next sign-in, with nothing saying why.
- **Recommended correction:** Give the capture programs stable paths as the plugins have
  (links under `/etc/nyxos/capture/…` won't do, since Hyprland resolves the executable;
  use setcap-style wrappers in `/run/wrappers/bin`, or match by a stable part of the path
  such as `/nix/store/[a-z0-9]+-nyx-dock-[^/]+/.*`), and tell the person to sign in again
  when an update changed them.
- **Effort:** S (pattern), M (wrappers)
- **Dependencies:** G6
- **Verification criteria:** Update the Dock in a running session; thumbnails and Capture
  still work without a prompt.

### NYX-APP-MAPS-004: Maps shows no map in the VM

- **Component:** nyx-maps (map view)
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** verified (in the dev VM only)
- **Description:** Maps opens with its sidebar, controls, attribution and the location
  circle on an empty background; no map appears.
- **Expected:** The map draws (the VM reaches the tile server).
- **Actual:** Four launches (full and half width, dark and light theme), each
  screenshot at least 6 s after opening, all blank.
  `curl https://tiles.openfreemap.org/planet` from the VM returns 200. The journal has no
  line from Maps beyond GTK's renderer notice.
- **Reproduce / verify:** in the VM, open Maps from the dock and wait.
- **Evidence:** `evidence/maps-blank.png`, `evidence/smoke-dock/io.github.design_nexus.nyx.Maps.png`.
- **Affected versions:** nyx-maps at nyx-packages 9045e4c; VM generation 266 (virtio GPU)
- **User impact:** If this isn't specific to the VM's graphics, Maps is unusable; if it
  is, Maps fails without a word on weak or virtual graphics.
- **Recommended correction:** Reproduce on hardware; surface tile and style errors in the
  window ("The map couldn't be loaded") instead of an empty view.
- **Effort:** S to diagnose
- **Dependencies:** NYX-HW-001
- **Verification criteria:** The map draws in the VM, or an error says why not.

### NYX-APP-ASSISTANT-009: The Assistant's overlays start a failing command every second when its service isn't running

- **Component:** nyx-assistant `apps/assistant/quickshell/shell.qml`, `quickshell/Aura/Main.qml`
- **Category:** performance
- **Severity:** P2
- **Status of feature:** verified
- **Description:** `nyx-assistant-hud.service` and `nyx-assistant-visual.service` run in
  every session. Each keeps `nyx-assistant listen` running and starts it again when it
  ends: after 1 s (`restartTimer`, shell.qml) and after 2 s (`restart`, Aura/Main.qml),
  with no back-off and no limit. With the Assistant's daemon not running (never set up,
  switched off, or stopped after its start limit) `listen` fails at once.
- **Expected:** Wait for the daemon's socket (a file watch, or socket activation), or back
  off to minutes.
- **Actual:** In the idle VM: 15 starts of `nyx-assistant listen` in 15 s, each ending with
  "connect /run/user/1000/nyx-assistant/assistant.sock: No such file or directory"; 170
  process starts per 20 s in the whole session; the visual process had used 8.5 minutes
  of CPU in 16 hours.
- **Reproduce / verify:** in the VM, `nyx-assistant listen` as the user (fails), then watch
  new processes for 15 s.
- **Evidence:** VM generation 266, 2026-11-14; shell.qml `listener`/`restartTimer`.
- **Affected versions:** nyx-assistant at nyx-packages 9045e4c
- **User impact:** Everyone who hasn't set the Assistant up pays for about 1.5 process
  starts a second for the whole session: battery, and noise in any process list.
- **Recommended correction:** Start the two overlay services with the daemon
  (`PartOf`/`WantedBy=nyx-assistantd.service`) instead of with the session, and in the QML
  retry on the socket appearing or with a back-off capped at a minute.
- **Effort:** S
- **Dependencies:** G1 (the Assistant ships in 0.1)
- **Verification criteria:** With the daemon stopped, no `nyx-assistant` process starts in a minute.

### NYX-SHELL-009: Shell Core keeps the trusted-programs list it read at start

- **Component:** nyx-shell `crates/nyx-shell-core/src/peer.rs`, `server.rs`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** `Trust::standard` reads `/etc/nyx/trusted-bin` and takes Shell Core's own
  folder once, when the service starts; the list is rebuilt only when `ipc.ui_runtimes`
  changes. A system update gives nyx-settings, Quickshell's wrapper and `nyx-shellctl` new
  store paths and rewrites the file, but a switch doesn't restart Shell Core.
- **Expected:** Programs installed by an update are recognised without signing out
  (`nyx_peer::program`, used everywhere else, reads the file on each call).
- **Actual:** `peer.rs:36-42`; `server.rs` (the `trust_tx.send` only in the `ui_runtimes`
  branch). In the VM Shell Core had run since 03:35 through six switches. After an update
  that moves those packages, the new programs classify as `read_only()`: Settings loses
  `ConfigWrite`, `nyx-shellctl` loses everything but reading.
- **Reproduce / verify:** static for the effect (the paths didn't change between the VM's
  generations 260–266); the missing restart was observed.
- **Evidence:** `systemctl --user show nyx-shell-core -p ActiveEnterTimestamp` in the VM.
- **Affected versions:** nyx-shell ee87822
- **User impact:** After such an update, shell settings changed in Settings and shortcuts
  routed through `nyx-shellctl` are refused until the next sign-in.
- **Recommended correction:** Classify with a fresh `nyx_peer::trusted_dirs` per
  connection (or watch the file, as the settings files are), and compare `own_dir` by
  package name on NyxOS.
- **Effort:** S
- **Dependencies:** NYX-HYPR-010 (same cause: store paths fixed at session start)
- **Verification criteria:** Update nyx-settings in a running session; a shell setting still saves.

## P3

### NYX-APP-ARCHIVE-004: Archive's own extraction check misses `./` names and link chains

- **Component:** nyx-archive `apps/archive/src/sevenzip/parse.rs`
- **Category:** security (defence in depth)
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The pre-extraction check added in c99343c (for NYX-APP-ARCHIVE-002) is
  meant not to depend on 7-Zip's version. Two shapes pass it.
- **Expected:** An archive with an entry inside a link, or a link that resolves outside the
  folder, is refused by Archive itself.
- **Actual:** (a) 7-Zip lists a tar entry `./l2` as stored, and
  `"l2/evil.txt".strip_prefix("./l2")` fails, so "inside a link" isn't seen
  (`extraction_risk`). (b) `link_escapes` counts depth and doesn't follow links:
  `d/l1 -> ..` then `l2 -> d/l1/..` passes though `l2` is the folder's parent.
- **Reproduce / verify:** A tar with `d/`, `d/l1 -> ..`, `./l2 -> d/l1/..`,
  `l2/evil.txt`: `7z l -slt` lists `./l2`; Archive's rules report no risk. 7-Zip 26.04
  refuses both links itself ("Dangerous link path was ignored"), so nothing escaped in the
  test.
- **Evidence:** test run on the host, 2026-11-14 (files removed afterwards).
- **Affected versions:** nyx-archive c99343c (not yet pinned by nyx-packages)
- **User impact:** None with 7-Zip 26.04; the README's promise doesn't hold for an older 7-Zip.
- **Recommended correction:** Normalise names (`./`, `//`) before comparing; treat a link
  whose target passes through another link in the archive as escaping.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The tar above is refused by `extraction_risk`.

### NYX-APP-BROWSER-002: Requests without a tab skip a per-workspace VPN; first requests are refused while the VPN's state loads

- **Component:** nyx-browser `src/nyx/modules/NyxVpn.sys.mjs`
- **Category:** privacy / reliability
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `connectionFor(browserId)` falls back to the main switch when a request
  has no tab (service workers, prefetch, Browser's own). With the main switch off and a
  VPN set for one workspace, those requests go direct. Separately, until `nyx-vpn.json`
  is read every request gets an unusable proxy when the kill-switch pref is on (the
  default), also for people who never set a VPN up.
- **Expected:** A workspace's VPN covers its sites' background requests; people without a
  VPN are never blocked.
- **Actual:** `connectionFor`, and `applyFilter`'s `!state` branch.
- **Reproduce / verify:** static; confirm at runtime.
- **Evidence:** file as above.
- **Affected versions:** nyx-browser 37d7341
- **User impact:** Small leak in the per-workspace mode; possibly failed loads in the first
  moments after Browser starts.
- **Recommended correction:** Say in the panel that a workspace's VPN covers pages, not
  background requests, or map service-worker principals to their workspace; block during
  loading only when a marker pref says a VPN was on last session.
- **Effort:** M
- **Dependencies:** NYX-APP-BROWSER-001
- **Verification criteria:** Tests in `nyx/tests`.

### NYX-UPD-004: The profile update checks one revision and installs whatever the branch is then; no protection against going back

- **Component:** nyx-system `crates/nyx-update/src/run.rs`, `signed.rs`
- **Category:** security
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `profile()` verifies the signature of `stable`'s head from
  `git ls-remote`, then runs `nix profile upgrade`, which resolves the branch again by
  itself; the two aren't tied together, and that `ls-remote` has no
  `GIT_TERMINAL_PROMPT=0` or status check. `verify()` accepts any signed `known-good` tag
  at the revision, so a `stable` moved back to an older signed release is installed.
- **Expected:** What is installed is the revision that was checked, and never older than
  what's installed (G9).
- **Actual:** `run.rs:246-255`, `signed.rs:78-101`.
- **Reproduce / verify:** static.
- **Evidence:** as above.
- **Affected versions:** nyx-system c1d9c8a
- **User impact:** Only with control of the repository or its branch; a signed old release
  with known holes could be served.
- **Recommended correction:** Upgrade to `github:…/nyxos/<verified rev>`; remember the
  highest `known-good` number installed and refuse a lower one.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Unit tests for both.

### NYX-ARCH-011: `atomic_write` can't save into a read-only folder and drops ownership

- **Component:** nyx-core `crates/nyx-core/src/cmd.rs:132`; Notepad and other savers
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified (by reading)
- **Description:** Every save is a temporary file plus rename. A file the person may
  write, in a folder they may not, can't be saved; the saved file gets the person's
  owner and group and loses ACLs, extended attributes and hard links. The temporary
  name (`.NAME.tmp-PID`) is predictable and created following links.
- **Expected:** Fall back to writing in place when the folder refuses; keep owner and group
  where allowed.
- **Actual:** `cmd.rs:132-155`.
- **Reproduce / verify:** `chmod a-w dir; nyx-notepad dir/file` (file writable), Ctrl+S:
  "Couldn't save".
- **Evidence:** as above.
- **Affected versions:** nyx-core aac46eb
- **User impact:** Rare; shared folders and files under version-control hooks.
- **Recommended correction:** On `EACCES` creating the temporary file, write in place
  (with fsync); create the temporary file with `O_EXCL|O_NOFOLLOW`; `fchown` to the
  original's owner when possible.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A unit test with a read-only folder.

### NYX-APP-INSTALLER-006: A password containing ":" is refused

- **Component:** nyx-installer `apps/installer/src/choices.rs:210`, `crates/nyx-install/src/plan.rs:173`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified (by reading)
- **Description:** "A password can't have : in it." `chpasswd` splits at the first colon,
  and the login can't contain one, so the rule isn't needed.
- **Expected:** Any password without a line break.
- **Actual:** as described.
- **Reproduce / verify:** Type `a:b` as the password on the You page.
- **Evidence:** as above.
- **Affected versions:** nyx-installer 46d13f2
- **User impact:** People with a colon in their usual password are turned away.
- **Recommended correction:** Drop the check in both places.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Install with such a password and sign in.

### NYX-CI-008: An uncommitted shared-crate bump sits in about fifty working trees

- **Component:** the `~/Projects/nyx-*` checkouts (`Cargo.toml`, `Cargo.lock`)
- **Category:** CI / process
- **Severity:** P3
- **Status of feature:** n/a
- **Description:** 53 repositories have modified `Cargo.lock` (70 files named `Cargo.toml`
  across them), moving nyx-core 32f0c5e → 94e0c8a and nyx-design 4f8e16d → ea8839d,
  last written 2026-11-14 11:28 and never committed.
- **Expected:** A bump is committed and tested per app, or reverted.
- **Actual:** `evidence/heads.tsv`; `git -C nyx-notepad diff`.
- **Reproduce / verify:** `for d in nyx-*/; do git -C $d status --porcelain; done`
- **Evidence:** as above.
- **Affected versions:** working trees only
- **User impact:** None directly; the next `git commit -a` in any of them ships an untested
  bump, and local installs are built from something no commit describes.
- **Recommended correction:** Decide: commit with a build per app, or `git checkout` them.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Clean `git status` in every repository.

### NYX-THEME-006: Launchers copied for themed icons outlive the apps they were copied from

- **Component:** nyx `tools/icons.py`; nyx-packages `modules/nixos/default.nix` (`nyx-icons` unit)
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified (by reading; copies seen in the VM)
- **Description:** To give third-party apps themed icons, `nyx-icons` writes a copy of each
  app's launcher to `~/.local/share/applications`. NyxOS runs only `nyx-icons sync`, and
  sync doesn't remove copies of apps that are gone ("cleaning up removed apps is left to
  generate", `icons.py:448`).
- **Expected:** Removing an app removes its launcher entry.
- **Actual:** The VM has copies for Helix, btop, Foot and Irlume (11 Nov); Irlume's holds
  `Exec`/`TryExec` store paths.
- **Reproduce / verify:** static for the removal; `ls ~/.local/share/applications` in the VM.
- **Evidence:** as above.
- **Affected versions:** nyx (umbrella) at nyx-packages 9045e4c
- **User impact:** A removed app can stay in the dock's drawer and Glimpse and fail to open.
- **Recommended correction:** Let `sync` drop records whose source launcher is gone.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Install and remove a package for everyone; its copy goes at the next sync.

### NYX-UX-005: Thirty apps ask GTK for a renderer by a name GTK has retired

- **Component:** `main.rs` of nyx-activity, -archive, -calculator, -calendar, -capture, -chat, -contacts, -containers, -maps and about twenty more
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Each sets `GSK_RENDERER=ngl` when the variable is unset. GTK now logs
  "The new GL renderer has been renamed to gl" on every start.
- **Expected:** `gl` (or no override).
- **Actual:** `grep -rn '"ngl"'` finds 30 source files; the VM's journal has the notice.
- **Reproduce / verify:** start any of them and read `journalctl --user`.
- **Evidence:** VM journal, 2026-11-14.
- **Affected versions:** current `main` of each
- **User impact:** None today; the apps fall to GTK's default if the old name is dropped.
- **Recommended correction:** One helper in nyx-core that sets `gl`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No notice in the journal.

### NYX-SET-003: Settings' new sidebar and Home cut text short and repeat titles

- **Component:** nyx-settings (two-level sidebar 0611102, Home page be32216)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** At the VM's full width (1680 px): sidebar subtitles end in "…" ("This
  computer and upda…", "Appearance, Window St…", "Keyboard, Mouse, Keyb…", "Wi-Fi,
  Connected Devic…", "Time & Language, Boot …"); three sections repeat their title as the
  subtitle (Accounts/Accounts, Displays/Displays, Sound/Sound); on Home the generation
  row's button reads "Up to…", the processor reads "Intel Core Ultra …", and the Power
  row's subtitle is "For now".
- **Expected:** Text fits or wraps; a subtitle adds something.
- **Actual:** `evidence/smoke-dock/io.github.design_nexus.nyx.Settings.png`.
- **Reproduce / verify:** open Settings.
- **Evidence:** as above.
- **Affected versions:** nyx-settings 1fabffb
- **User impact:** The first page people see looks unfinished.
- **Recommended correction:** Shorter subtitles or none for one-page sections; let the
  button size to "Up to date"; a tooltip or second line for the processor.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No "…" in the sidebar or Home at 1280 px and wider.

### NYX-APP-STORE-003: Store's home shows category symbols for well-known apps and recommends replacements for NyxOS's own

- **Component:** nyx-store (revamp, Home)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** "Everyday essentials" (Firefox, LibreOffice, KeePassXC, VLC, Signal) and
  "Make something extraordinary" (GIMP, Krita, Inkscape) show generic symbols, not the
  apps' icons; the bundles' icon stacks are the same symbols. The essentials are a
  browser, an office suite and a password manager, which NyxOS ships as Browser, Office
  and Passwords. While loading, the sidebar's foot shows a check mark beside "Loading
  apps…".
- **Expected:** App icons for apps; the first shelf doesn't steer people away from the
  suite; no check mark until loaded.
- **Actual:** `evidence/store-home.png`, `evidence/smoke-dock/io.github.design_nexus.nyx.Store.png`.
- **Reproduce / verify:** open the Store.
- **Evidence:** as above; related to the first audit's note that catalog items have no desktop ID.
- **Affected versions:** nyx-store at nyx-packages 9045e4c
- **User impact:** The Store's front page looks like placeholders.
- **Recommended correction:** Ship icons for the featured catalog entries (the Nix
  packages' own icons, cached); revisit the essentials list; a spinner while loading.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** Featured apps show their icons offline.

### NYX-APP-ACTIVITY-002: Activity lists Nix wrapper names

- **Component:** nyx-activity (processes grouped by app, 1840da5-era change)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** "Busiest right now" shows `.nyx-assistant-` (cut from
  `.nyx-assistant-wrapped`) and `start-hyprland` as names.
- **Expected:** "Assistant", "Hyprland": NyxOS wraps most programs as `.NAME-wrapped`.
- **Actual:** `evidence/smoke-dock/io.github.design_nexus.nyx.Activity.png`.
- **Reproduce / verify:** open Activity on NyxOS.
- **Evidence:** as above.
- **Affected versions:** nyx-activity at nyx-packages 9045e4c
- **User impact:** Unfamiliar names for the suite's own programs.
- **Recommended correction:** Strip `.`…`-wrapped` before matching a process to its app.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The Assistant's row reads "Assistant".

### NYX-UX-006: Small interface faults seen in the revamped apps

- **Component:** nyx-mail, nyx-passwords, nyx-theater, nyx-calendar, nyx-music, nyx-news, nyx-maps, nyx-browser
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** From one launch of each in the VM (screenshots in `evidence/smoke-dock/`):
  - **Mail:** with no account, the sidebar's foot says "Not checked yet" and the empty
    Imbox doesn't offer to add an account.
  - **Passwords:** locked, the header still shows the search shortcut "Ctrl F" with no
    search field.
  - **Theater:** "Connect Plex" sits under the message; "Connect Jellyfin" sits alone
    near the bottom of the window.
  - **Calendar:** the quick-add hint is cut ("Add "Lunch with Sam a…"); the week opening
    at midnight is NYX-APP-CALENDAR-004.
  - **Music:** the sidebar row "Recent and most play…" is cut.
  - **News:** "Updated just now" carries a warning triangle.
  - **Maps:** the Home and Work chips show "—" with no hint that they can be set.
  - **Browser:** first start opens a second tab on Passwords' pairing page with the raw
    `moz-extension://…/popup.html#welcome` address in the address bar.
- **Expected:** STYLE.md's empty states and labels that fit.
- **Actual:** as listed.
- **Reproduce / verify:** open each app on a new account.
- **Evidence:** `evidence/smoke-dock/*.png` (Passwords' was deleted: see NYX-PRIV-007).
- **Affected versions:** each app at nyx-packages 9045e4c
- **User impact:** Cosmetic, on first use.
- **Recommended correction:** per item above.
- **Effort:** S each
- **Dependencies:** none
- **Verification criteria:** New screenshots.

### NYX-PRIV-007: The development VM and its snapshots hold a real Passwords sign-in

- **Component:** `nyxos-dev` (Incus VM), snapshots `known-good-23`, `known-good-24`, `pre-audit-20261114`
- **Category:** privacy / process
- **Severity:** P3
- **Status of feature:** n/a
- **Description:** Passwords in the VM is signed in to a personal account on a real
  Vaultwarden server (locked; the address shows on the unlock card). The smoke run's
  screenshot of it was deleted from this audit's evidence so the address isn't committed.
- **Expected:** Test systems use test accounts; evidence folders hold no personal addresses.
- **Actual:** seen in the smoke run, 2026-11-14.
- **Reproduce / verify:** open Passwords in the VM.
- **Evidence:** none kept.
- **Affected versions:** the VM only
- **User impact:** The encrypted vault copy travels with every VM snapshot, and
  screenshots taken for audits or docs can carry the address.
- **Recommended correction:** Sign out in the VM and use a throwaway Vaultwarden account;
  have `scripts/smoke-apps` skip or blur Passwords.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Passwords in the VM shows the sign-in page.

### NYX-SHELL-010: Shell Core's accept loop retries a failing accept without a pause

- **Component:** nyx-shell `crates/nyx-shell-core/src/server.rs` (`accept`)
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified (by reading)
- **Description:** `let Ok((stream, _)) = listener.accept().await else { continue };` loops
  at once on an error that lasts (out of file descriptors).
- **Expected:** A short sleep, and a log line, on error.
- **Actual:** as described; connections aren't limited either, so a client of the same
  user that opens sockets without end causes it.
- **Reproduce / verify:** static.
- **Evidence:** `server.rs`, `accept`.
- **Affected versions:** nyx-shell ee87822
- **User impact:** A full core at 100 % in a rare failure.
- **Recommended correction:** `tokio::time::sleep(100 ms)` and a warning on `Err`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A unit test with a failing listener.

### NYX-SHELL-011: A clean exit of the shell isn't restarted or reported

- **Component:** nyx-shell `data/nyx-shell-qs.service`, `data/nyx-shell-core.service`; nyx-packages (OnFailure)
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified (by reading)
- **Description:** Both units are `Restart=on-failure`. Quickshell leaving with status 0
  (a quit request, the compositor's socket closing in some paths) is neither restarted nor
  a failure, so the new "The shell stopped" notice (G8) doesn't appear.
- **Expected:** The bar and dock come back, or the notice appears.
- **Actual:** unit files as above.
- **Reproduce / verify:** `qs kill` (or `systemctl --user kill -s TERM nyx-shell-qs` and
  compare with a clean quit) in the VM; not run.
- **Evidence:** unit files.
- **Affected versions:** nyx-shell ee87822
- **User impact:** No bar, dock or launcher until the next sign-in, with no hint.
- **Recommended correction:** `Restart=always` for the surfaces, with the existing start limit.
- **Effort:** S
- **Dependencies:** G8
- **Verification criteria:** After a clean quit the surfaces return within seconds.

### NYX-SHELL-012: The bar's privacy indicator dumps PipeWire's whole graph every three seconds

- **Component:** nyx-bar `plugins/privacy/src/main.rs`, system plugin (`wpctl get-volume`)
- **Category:** performance
- **Severity:** P3
- **Status of feature:** verified
- **Description:** `pw-dump` is run every 3 s for the whole session to see whether
  something records; the system plugin runs `wpctl get-volume` on a timer too.
- **Expected:** One long-running `pw-dump --monitor` (or `pw-mon`), as nyx-capability's
  watchers do for `pactl subscribe`.
- **Actual:** `main.rs:5` (its own comment), `main.rs:122`; 4 runs seen in 15 s in the VM.
- **Reproduce / verify:** watch process starts in an idle session.
- **Evidence:** VM generation 266.
- **Affected versions:** nyx-bar 54086da
- **User impact:** Constant small wake-ups; the indicator lags by up to 3 s.
- **Recommended correction:** Follow the monitor stream.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No periodic `pw-dump` in an idle session.

### NYX-SEC-015: Restricting who reads stored notifications doesn't cover the file they're stored in

- **Component:** nyx-notification-center (7711cea, `reader`)
- **Category:** security
- **Severity:** P3
- **Status of feature:** verified
- **Description:** On NyxOS `inbox`, `pinned`, `history` and `apps` answer only callers whose
  executable is a Nyx program. The same text (messages, sign-in codes) is in
  `~/.local/share/nyx/notifications.db`, mode 0600 and owned by the user, so any program
  of that user reads it without asking the service. The caller check also looks the
  process up by PID after the call, which a short-lived caller can race.
- **Expected:** Either the stated protection holds, or it isn't claimed.
- **Actual:** VM: `ls -la ~/.local/share/nyx/notifications.db*`.
- **Reproduce / verify:** `sqlite3 ~/.local/share/nyx/notifications.db .dump` as the user.
- **Evidence:** as above.
- **Affected versions:** nyx-notification-center b893735
- **User impact:** None beyond what was true before; the fix gives a false sense of cover.
- **Recommended correction:** Don't store bodies of notifications marked transient or
  from password and authenticator apps; say in the docs that same-user programs aren't a
  boundary (the first audit's position on app identity).
- **Effort:** S
- **Dependencies:** W1
- **Verification criteria:** A sign-in code's notification isn't in the database afterwards.

### NYX-APP-CALENDAR-004: The week opens at midnight; "Scroll to" has no effect at launch

- **Component:** nyx-calendar `apps/calendar/src/days.rs:167-171` (`scroll_to_hour`), `window.rs:247`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The week should open at the hour set in Settings ("Scroll to", 8 by
  default). `scroll_to_hour` sets the scroll position once, in a single idle callback,
  as `target.min(upper - page_size)`. Before the view has its height that bound is 0.
- **Expected:** 8 AM (or the chosen hour) at the top.
- **Actual:** In four launches in the VM (full and half width, dark and light) the week
  shows 1 AM at the top, with the working day below the fold.
- **Reproduce / verify:** open Calendar.
- **Evidence:** `evidence/smoke-dock/…Calendar.png`, `evidence/half/dark/Calendar.png`, `evidence/half/light/Calendar.png`.
- **Affected versions:** nyx-calendar at nyx-packages 9045e4c
- **User impact:** Every launch starts with an empty night; the setting looks broken.
- **Recommended correction:** Scroll when the adjustment's `upper` first exceeds the page
  size (connect to `changed` once), not in a bare idle.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A screenshot at launch shows the chosen hour at the top.

### NYX-APP-MAIL-004: The Imbox is blank when "Previously seen" is chosen and everything is unread

- **Component:** nyx-mail `apps/mail/src/sorted.rs` (`imbox`)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified (by reading)
- **Description:** With the switch on "Previously seen", the new section is skipped; when no
  conversation has been read the seen section is skipped too, so nothing is appended
  under the page's head, not even a line saying so.
- **Expected:** "Nothing seen yet", as the other branch says "Nothing new".
- **Actual:** `sorted.rs`, `imbox`: `if !seen_only { … }` then `if !seen.is_empty() { … }`.
- **Reproduce / verify:** static; needs an account with only unread mail.
- **Evidence:** as above.
- **Affected versions:** nyx-mail at nyx-packages 9045e4c
- **User impact:** An empty page that looks like mail has gone missing.
- **Recommended correction:** Add the empty line for that branch.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A snapshot test of that state.

### NYX-APP-WELCOME-003: Opening Welcome at a step does nothing when it's already open

- **Component:** nyx-welcome `apps/welcome/src/main.rs` (bfaa1bf)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified (by reading)
- **Description:** Welcome is now a single instance. A second launch parses `--step`,
  `--select` and `--preset` in its own process, then runs with no arguments; the first
  instance's `activate` presents its window and returns. The step and choices are lost.
- **Expected:** Settings' and the Store's buttons that open Welcome at a step move the
  open Welcome there.
- **Actual:** `main.rs`: `app.run_with_args::<&str>(&[])`, and `build` returns early when
  a window exists.
- **Reproduce / verify:** static. Open Welcome, then `nyx-welcome --step software`.
- **Evidence:** as above.
- **Affected versions:** nyx-welcome bfaa1bf
- **User impact:** A button that seems to do nothing while Welcome is open (the first-run
  case the change was made for).
- **Recommended correction:** `HANDLES_COMMAND_LINE` (or an app action) so the open
  instance receives the step and selections.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The second launch moves the open window to the step.

### NYX-SET-004: Settings' "Biggest folders" and folder sizes call /usr/bin/du, which NyxOS doesn't have

- **Component:** nyx-settings `apps/settings/src/backend/cleanup.rs:76,80`, shown from `sections/disks.rs:1405`
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** verified (by reading; the page is on NyxOS)
- **Description:** `folder_size` runs `/usr/bin/du` and `largest` runs `/usr/bin/nice
  /usr/bin/du`. NyxOS's `/usr/bin` holds only `env`, and a failed start is read as empty
  output.
- **Expected:** Sizes on NyxOS.
- **Actual:** Storage & Backup › Disks shows "Biggest folders in your home" on NyxOS
  (`evidence/settings-disks.png`); the list behind it comes back empty and folder sizes
  as 0.
- **Reproduce / verify:** in the VM, `ls /usr/bin` (only `env`); open the row.
- **Evidence:** as above.
- **Affected versions:** nyx-settings 1fabffb
- **User impact:** The page that helps free space shows nothing to free.
- **Recommended correction:** Call `du` and `nice` by name (the package puts coreutils on
  the path), as the rest of the suite does.
- **Effort:** S
- **Dependencies:** W6
- **Verification criteria:** The list fills in the VM.

### NYX-A11Y-004: A few icon buttons have neither a tooltip nor an accessible name

- **Component:** nyx-chat, nyx-notes, nyx-activity
- **Category:** accessibility
- **Severity:** P3
- **Status of feature:** verified (by reading)
- **Description:** STYLE.md asks for icon buttons with tooltips. These are created with an
  icon only: Chat's quick-ask send (`apps/chat/src/quick.rs:105`), two close buttons
  (`sections/chat/composer.rs:828`, `panel.rs:267`) and the reply-branch previous/next
  (`view.rs:284,294`); Notes' add-folder (`crates/notes-app/src/window.rs:854`);
  Activity's row expander (`apps/activity/src/sections/processes.rs:434`).
- **Expected:** A tooltip, which GTK also reads as the name.
- **Actual:** no `set_tooltip_text` or accessible label within the following lines.
- **Reproduce / verify:** hover them; or Orca.
- **Evidence:** as above. A search of every revamped app found no others (Passwords'
  go through its `allow` helper, which sets them).
- **Affected versions:** each at nyx-packages 9045e4c
- **User impact:** Screen-reader users hear "button".
- **Recommended correction:** Tooltips on the seven.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The search finds none.
