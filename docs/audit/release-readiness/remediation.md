# Remediation roadmap (handoff 10 section 34)

**For approval. Nothing here has been implemented.** Findings are prioritised by severity,
user impact, security and data-loss risk, frequency, fix complexity, dependency order and
release relevance. Effort: S = hours, M = days, L = weeks. Several static findings
describe the same defect from two angles; they're merged below (SEC-001 = AI-001,
SEC-003 = CONN-001, SEC-005 = SYS-001, SEC-007 = VOICE-002, THEME-002 ⊂ A11Y-002,
PRIV-002 = ASSISTANT-003, MAIL-002/CALENDAR-002 ⊂ PKG-009).

## 1. Immediate release blockers

In this order; items on the same line can run in parallel.

| # | Finding(s) | What to do | Effort | Unblocks |
| --- | --- | --- | --- | --- |
| 1 | NYX-CI-001 | Run `nix fmt` on both repos; CI green again | S | everything below gets real CI signal |
| 2 | NYX-INST-001 | Installer creates `/mnt` (and the live image provides it); rebuild ISO | S | Gate B |
| 3 | NYX-CI-005 | Build the ISO in CI and run the headless install plan against it (install VM or NixOS VM test), then boot the result | M | keeps #2 fixed |
| 4 | NYX-INST-002, NYX-INST-003 | Lock the installed machine's `nyxos` to the channel's GitHub revision (or GC-root the ISO source until the first update); lock overrides at `/etc/nyxos/overrides` | S | Gate C, F |
| 5 | NYX-CI-003, NYX-CI-002 | Promote `stable` to the release revision; protect `main`/`stable` (required CI); document promotion | S | Gate A, F |
| 6 | NYX-PKG-008, NYX-PKG-009 | Per-package autostart files; per-user D-Bus services and actions found immediately after install | S–M | Welcome, Gate C |
| 7 | NYX-A11Y-001 | `services.gnome.at-spi2-core.enable = true`; Orca in the catalog | S | Gate G |
| 8 | NYX-APP-BACKUP-001 | Timer units call the app through a stable path (`/etc/profiles/per-user/%u/bin` or the system profile), not a store path | S | Gate E |
| 9 | NYX-APP-SHARE-001 | Open 53317/tcp+udp when Share is enabled (or only on trusted networks, with SEC-003's zone design) | S | Gate I |
| 10 | NYX-APP-INSTALLER-001 | Apply the chosen layout to the installer's own input before the password pages, and to the LUKS prompt (console keymap in initrd) | S–M | Gate B |
| 11 | NYX-APP-OFFICE-001 | Round-trip test with real documents; if lossy, Save in place of a foreign format warns and offers Save As | M | Gate E |
| 12 | NYX-APP-CONTAINERS-001, NYX-APP-PASSWORDS-001, NYX-APP-MAIL-001, NYX-APP-ASSISTANT-001 | Make the catalog/Welcome text match reality now (S each); fix the features later (Podman backend, browser extension, project OAuth clients, Assistant launch via desktop entries) | S (wording) / M–L (features) | Gate I |
| 13 | NYX-DOC-001 | Install guide, hardware requirements, recovery/rollback, troubleshooting, known limitations | M | Gate H |
| 14 | NYX-HW-001 | Hardware test pass (two laptops, one NVIDIA desktop, one HiDPI display) after #2–#10 | M | Gate B |

Estimated: about 1–2 weeks of focused work plus the hardware pass.

## 2. Required pre-release corrections

P2 findings that touch security, privacy, data, recovery or the core desktop.

**Security and privacy**
- NYX-SEC-001 (= AI-001): require a token for the OpenAI endpoint (written to the user's runtime dir for coding tools) or make the TCP endpoint opt-in; check `Host` against loopback names.
- NYX-SEC-002: identify callers by package (store path of the trusted packages) and drop `~/.local/bin` from the root key service's trust.
- NYX-SEC-003 (= CONN-001): keep fluxd's port closed until a device is paired, or limit to trusted networks.
- NYX-SEC-004: remove `input` from the default user groups; grant per feature.
- NYX-SEC-005 (= SYS-001): require the root password (or the disk passphrase) for the Recovery console.
- NYX-SEC-006: don't allow webcam face matching (Gaze) as a sole factor for sudo/polkit.
- NYX-SEC-007 (= VOICE-002): hash-pin model downloads; no moving branches.
- NYX-SEC-008: sign releases and checksums; document how user apps update.
- NYX-PRIV-001: enable Hyprland's permission system for screen capture (`ecosystem:enforce_permissions`) with portal prompts, and show capture in the bar.
- NYX-PRIV-002 (= ASSISTANT-003): wake word off by default, consent when enabling.

**Reliability and recovery**
- NYX-SHELL-001: let Shell Core (or a systemd `OnFailure=`/higher start limit) restore the shell surfaces; split the bar from the other surfaces later.
- NYX-SHELL-002: Glimpse works without Shell Core (fallback) and resyncs on its return.
- NYX-REL-002: stage overrides; commit after a successful switch.
- NYX-REL-003: bar and dock follow monitor hot-plug.
- NYX-AI-002: AI Core's app socket independent of port 8080.
- NYX-APP-INSTALLER-002/003: clean up after a failed dual-boot install; BitLocker guidance.
- NYX-UPD-001: show package changes in the plan before confirming.
- NYX-HYPR-001/002: test fullscreen-own-workspace with games/mpv/browsers; make the dock and bar model those workspaces (or turn the default off).

**Data**
- NYX-APP-NOTEPAD-001 (encoding preserved on save), NYX-APP-PDF-001 (redaction semantics: say "covers", or truly remove text), NYX-APP-PHOTOS-002 (keep EXIF), NYX-APP-ARCHIVE-001 (pass passwords via stdin), NYX-APP-CLOUD-001 (Secret Service for rclone secrets).

**Accessibility**
- NYX-A11Y-002 (with THEME-002): contrast to WCAG AA in the default theme; stricter built-in check.
- NYX-SHELL-005: keyboard operation of dock, bar and Control Center.
- NYX-APP-GREETER-002/003: layout/Caps Lock indicator; screen reader at login (after A11Y-001).

**NyxOS correctness (Omarchy leftovers that run on NyxOS)**
- NYX-APP-SETTINGS-001, NYX-APP-CONTAINERS-002, NYX-APP-BIOMETRICS-001, NYX-APP-CAPTURE-001, NYX-APP-PHOTOS-001, NYX-APP-CLIPBOARD-001, NYX-APP-AGENTS-001, NYX-VOICE-001.

**Build and test hygiene**
- NYX-PKG-002 then NYX-THEME-001: align every app on one nyx-core and one nyx-design revision (scripted re-pin) so fixes reach all apps.
- NYX-PKG-001 / NYX-APP-FILES-001: run Files' skipped safety tests somewhere (a VM check).
- NYX-DOC-002: rewrite READMEs of release-included apps for NyxOS.

Estimated: 2–4 weeks.

## 3. Recommended improvements

- Architecture: NYX-ARCH-001/002 (one desktop-state source in Shell Core; overlay registry for all surfaces), ARCH-003..005, ARCH-010.
- CI and dependencies: NYX-CI-004 (CI on push for app repos; CI for the 16 core repos), CI-006, CI-007, NYX-DEP-001 (Renovate or similar for crates and flake inputs), DEP-003/004 (reduce hand-pinned packages and forks), NYX-HYPR-004..008 (patch tests and hygiene), NYX-PKG-003..006.
- Performance: NYX-PERF-001 (profile the 130 MB floor), NYX-PERF-002, NYX-SHELL-004/006.
- UX polish: NYX-UX-001..004, NYX-REL-001, theme items THEME-003..005, the remaining P3s in [issues.md](issues.md).

## 4. Post-release enhancements

- Move Notification Center and Switcher to Quickshell and retire the GTK versions (NYX-ARCH-007, handoff 03).
- Enable Desktop Widgets once tested (NYX-ARCH-006).
- Assistant on the shared action registry (NYX-AI-003); Chat's voice through Nyx Voice (NYX-APP-CHAT-001, NYX-VOICE-003).
- Firmware updates on by default once fwupd is validated on hardware.
- CUDA acceleration path built and tested in CI (NYX-PKG-004).

## 5. Deferred roadmap work

Approved in handoffs but not required for a first release (not regressions): the remaining
handoff 01 Shell Core modules (shortcut router adoption, component restart supervision),
handoff 03 per-workspace widgets and dock quick panels where partial, handoff 05 Aura as a
shell component and on-demand vision, handoff 06 Universal Clipboard and Nyx Share device
destinations beyond Flux's, handoff 08 individual-target polish, handoff 09 remaining
capability-aware pages. See the feature tables in [shell.md](shell.md) and
[infrastructure.md](infrastructure.md).

## Recommended first-release scope

A smaller 0.1 is more reliable than the full catalog. Recommendation:

| Keep in 0.1 (after the fixes above) | Move to "Preview" (Store only, labelled) | Exclude |
| --- | --- | --- |
| Base tier: shell, Settings, Store, Files, Capture, Activity, Backup, Share, Welcome, Glimpse, greeter, locker | Lyra (private YouTube API, ToS risk, "In progress", no CI, 0.8–1.9 GB) | Nyx Agents (already not offered) |
| Welcome: Notepad, Calculator, Archive, Photos, Calendar, Contacts, Notes, PDF, News, Music, Media Player, Theater, Home, Git, Torrents, Passwords (with the autofill wording fixed) | Pulse (calls unverified; shared API credential) | Desktop Widgets (already off) |
| Mail (with honest account wording) | Assistant (Omarchy launch paths, always-on mic default) and Chat voice | Nyx Browser (prototype, not packaged) |
| Office (only if OFFICE-001 is resolved or Save-in-place warns) | Containers (until Podman wording or backend is fixed) | |

This scope removes four of the fifteen P1s from the release (ASSISTANT-001 and
CONTAINERS-001 by moving the apps; MAIL-001 and PASSWORDS-001 by rewording), and keeps
every remaining blocker inside the base system, installer and packaging, which are needed
regardless.

## Progress (2026-11-12, after the audit)

Fixed and verified (VM or installed-VM test, as noted), rolled out to the dev VM, and on
`stable` as `known-good/23` (nyxos `3a680df`, nyx-packages `f14b203`) unless marked
later:

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-CI-001 | `nix fmt` (nyxos 05eb0bc, nyx-packages 82bbb1a) | CI green again |
| NYX-INST-001 (P0) | installer makes `/mnt`; live image provides it (nyx-installer 7cca914, nyxos 0dd4cbe) | fresh ISO installs, no workaround |
| NYX-INST-002 | GC root for the live USB's NyxOS source (nyx-installer 7cca914) | system change builds after nix-gc on an install |
| NYX-INST-003 | lock names /etc/nyxos/overrides (nyx-installer 0fbc8c3) | unit test |
| NYX-PKG-008 | per-package `share/nyx/autostart.d` (nyx-packages bc5b6fc, nyx-system 6225952) | Calendar, Mail, Passwords in one profile |
| NYX-PKG-009 (part) | session bus reloaded after profile changes (nyx-system 6225952) | code; the rest was the stale channel (CI-003) |
| NYX-A11Y-001 | `services.gnome.at-spi2-core.enable` (nyxos 04752a7) | a11y bus answers, variables gone |
| NYX-APP-BACKUP-001 | schedules use profile paths; daemon repairs old ones (nyx-backup ab1f13b) | VM: new and repaired units |
| NYX-APP-SHARE-001 | 53317/tcp+udp open with Share (nyx-packages bc5b6fc) | firewall rules present |
| NYX-APP-INSTALLER-001 | installer restarts in the chosen layout; keymap in initrd (nyx-installer 3307990, nyxos 198488b) | live ISO: German layout after choosing it |
| Installer time zone search | DropDown expression (nyx-installer 83a74c3) | VM: "berlin" filters |
| NYX-APP-OFFICE-001 | measured fidelity check: warn on open, no autosave, ask before saving over (nyx-office dae3e1a, 00ef3fe) | VM: dialog, file unchanged; samples report nothing |
| NYX-APP-ASSISTANT-001 (part) | browser, Files, About and desktop-entry launches without Omarchy (nyx-assistant eb67650) | unit tests; desktop toggles still unmapped |
| NYX-APP-CONTAINERS-001, PASSWORDS-001, MAIL-001 (wording) | catalog text matches reality (nyx-system f8a75e7) | — |
| NYX-CI-002 | `scripts/promote-stable` (CI-gated), `ci` summary job, `stable` protected (requires `ci`, admins included), no force-push on `main` (nyxos ee40718, nyx-packages b902551) | dry runs; protection set via the API |
| NYX-CI-003 | `stable` promoted to 3a680df / f14b203 (`known-good/23`) | — |
| NYX-DOC-001 | user guide in docs/guide (nyxos af19863) | links checked |

Still open from §1: NYX-HW-001 (hardware pass). Everything in §2–5 is unchanged.

### W2: shell, sign-in and accessibility (2026-11-12)

On the dev VM with nyxos `147bb6a` (nyx-packages `1840da5`); on `stable` with W3 as
`known-good/24`.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-SHELL-001 | start limit 10/min; `OnFailure=nyx-shell-failed` notifies with **Restart the shell** (nyx-shell 03f30a2, nyx-packages 29a2a73) | VM: 11 kills, unit failed, notification shown; its restart commands bring the shell back |
| NYX-SHELL-002 | transient overlays open and close locally while Shell Core is away (nyx-shell 27dca32) | VM: Glimpse opens and closes with Shell Core stopped |
| NYX-REL-003 | already fixed before W2 | VM: headless output gets bar and dock, both leave on removal |
| NYX-REL-002 | changes built from staged overrides; leftover staging finished or dropped at start (nyx-system 7374426) | unit test |
| NYX-SHELL-005 | `nyx-dock --focus`, `nyx-bar --focus` (Super+Ctrl+Alt+D / B), named tiles and items, Page Up/Down and named page dots in the Control Center, OSD as an alert | VM: dock and bar take the keyboard with a focus ring |
| NYX-A11Y-002, THEME-002 | readability floor in the resolver (secondary/tertiary text 4.5:1, control outlines 3:1, labels on accent 4.5:1), stricter check, Catppuccin roles (nyx-design 0073144), every app on it | Mocha secondary text 7.4:1 (computed); contrast check clean for all built-ins |
| NYX-APP-GREETER-001 | Try again, and starts over by itself after 10 s (nyx-greeter 040d6fd) | code |
| NYX-APP-GREETER-002 | layout and Caps Lock under the password | VM: layout shown |
| NYX-APP-GREETER-003 | Super+Alt+S toggles Orca at login, Super+Ctrl+Alt+S in a session; Orca in the base system and catalog | VM: Orca starts and stops at the greeter, AT-SPI bus present |
| NYX-HYPR-001, 002 | named workspaces (0.57 gives them no id) get one from their name; fullscreen ones count as their origin (nyx-core 94e0c8a) | VM matrix in nyx-hyprland `docs/testing.md` |
| NYX-HYPR-003 | labelled experimental; `nyx display` and Settings put an unkept change back themselves | VM: two unconfirmed changes, no hang, but Hyprland's timer didn't revert (still open) |
| W2-P3 | SHELL-003 Glimpse in the panels group; SHELL-004 brightness polled only while the panel is open; SHELL-007 swipe plugin built for 0.57; SHELL-008/ASSISTANT-005 Aura makes room for Nyx Bar; UX-001 helper launcher entries hidden; UX-003 session named NyxOS (the wordmark is NYX by design, not cut); A11Y-003, MUSIC-002, OFFICE-002 accessible names; CALCULATOR-002 graph in theme colours; AGENTS-002 terminal readable by screen readers, CI added; THEME-003 unreadable theme.toml kept as .broken; THEME-004 clones shallow, 5 min, 200 MB; THEME-005 Mocha fallbacks; REL-001 no duplicate D-Bus listings of our own, CardPopup warning gone | VM: plugins load, our system-bus duplicates gone |

Left as is: the session bus still logs a duplicate for every service, as NixOS lists the
system profile both in `services.dbus.packages` and through `XDG_DATA_DIRS`; Caps Lock and
the greeter's Try again weren't exercised at runtime.

### W3: installer and dual boot (2026-11-14)

On the dev VM with nyxos `d547f6e` (nyx-packages `c1a6225`), every Nyx input at `main`
except nyx-files (`bc00197`: its `main` fails a test in the build sandbox). With W1–W2,
`stable` is `known-good/24` (nyxos `171f062`, nyx-packages `67911ba`; G10). Installer checks ran on a separate test VM from a fresh ISO, deleted afterwards.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-APP-INSTALLER-002 | the installer's partitions are named ("NyxOS EFI", "NyxOS"); found beside other partitions, the disk page offers **Remove them**, the failure page **Remove what this install made**; `nyx-install remove-leftovers` unmounts first and deletes only those (nyx-installer d408149, 6a6a9ec, c00ecbe) | test VM: install beside a Windows-like layout killed after partitioning; both found and removed, Windows partitions untouched, the free space and a valid plan back |
| NYX-APP-INSTALLER-003 | warning on the disk page when a BitLocker volume is found and installing alongside; guide: recovery key before Secure Boot changes, no Secure Boot or TPM unlock yet (nyxos ef50592) | test VM: banner shown (lsblk reporting BitLocker) |
| NYX-APP-INSTALLER-004 | gaps and plans carry the disk's sector size (512 or 4096) (nyx-installer d408149) | test VM: 4096-byte-sector NVMe disk, gap 38.5 GB, EFI exactly 1 GiB; unit tests |
| NYX-APP-WELCOME-002 | single instance; closing while it applies asks first (nyx-welcome bfaa1bf) | dev VM: a second launch opens no second window; the close question is code only |
| Found in rollout | Hyprland plugins load from `/etc/nyxos/hyprland-plugins/`, so an update no longer asks to load nyx-decor (the permission rules are read only at Hyprland's start) (nyx-packages c1a6225, nyxos d547f6e) | dev VM after reboot: both plugins loaded, no prompt |

## Audit 2 (2026-11-14 findings), 2026-11-15

Fixes for [the second audit](../2026-11-14/issues.md), on each repository's `main`, pinned
by nyx-packages `e807660` (nyxos ee9b985). Before the fixes, the uncommitted shared-crate bump was committed
in 52 repositories after building all 55 workspaces (NYX-CI-008). VM results below are
from the dev VM rebuilt at those pins on 2026-11-16; "code" means unit tests and builds only.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-APP-INSTALLER-005 (P1) | partitions made as "NyxOS EFI (installing)" / "NyxOS (installing)", renamed as the last step; only those count as leftovers; removal names partitions and sizes and asks; a finished NyxOS is described (nyx-installer cfe9575) | test VM from an ISO of nyxos ee9b985, Windows-shaped disk: an install stopped at step 34 left only partitions 4–5 "(installing)", and `remove-leftovers` removed just those (Windows' three intact); the full install beside Windows renamed them "NyxOS EFI"/"NyxOS", `remove-leftovers` then refused ("nothing an unfinished install left"), and the installed system booted through Limine to its login prompt with no failed unit | unit tests (finished beside Windows: no leftovers; both kinds on one disk: only the unfinished) |
| NYX-INST-004 (P1) | no `/sys/firmware/efi`: Welcome page says how to start in UEFI mode, no Next; `check_here` refuses for the app and `nyx-install run` (nyx-installer cfe9575) | test VM in SeaBIOS mode: no `/sys/firmware/efi`, `nyx-install run` refused with the UEFI message, disk untouched |
| NYX-APP-BROWSER-001 (P1) | `NyxLocalHosts`: only loopback/private/link-local IP literals and localhost, *.localhost, *.local go direct (nyx-browser 918be89) | `node --test nyx/tests/local_hosts.test.mjs`; released as Browser 1.24.2b-3 (nyx-packages e807660), running in the dev VM |
| NYX-PKG-010 | `MOZ_SYSTEM_DIR=$out/lib/mozilla`; install check that the manifest is where it leads (nyx-packages 800a428, a847d7b) | VM: with `~/.mozilla/native-messaging-hosts` moved away, Browser started both bridge processes from the package |
| NYX-PKG-011 | after each profile change, the profile's native-messaging manifests are linked into ~/.mozilla and ~/.config/chromium, dangling ones removed (nyx-system abe07aa) | unit test (the dev VM installs apps system-wide, not in a profile) |
| NYX-UPD-003 | `nyx` maps `nyx-*` to the system's channel from flake.lock (nyxos ecedc43) | VM: `ref nyx-calculator` → `github:nyxos-project/nyxos/stable#nyx-calculator`, which the system flake evaluates; `htop` → nixpkgs |
| NYX-APP-CLOUD-003 | waits for the keyring; a missing or wrong password sets rclone.conf and accounts.json aside, starts over and notifies (nyx-cloud 6c92501) | VM: keyring item deleted, `nyx-cloud` restarted → files set aside in `unreadable-<time>/`, fresh config, notification "Cloud couldn't open its saved accounts"; with the item back, it opens them without setting aside |
| NYX-HYPR-010 | capture rules match `/nix/store/<hash>-<pname>[-<version>]/` (nyxos 64bb182) | VM: the rules match the running Switcher's and grim's current store paths |
| NYX-APP-MAPS-004 | cause: no glib-networking, so libsoup (libshumate's tile downloads) had no TLS and every tile failed quietly. Maps package gets it (nyx-packages 3a622c3); every session gets it, for all apps (nyxos 412a2de) | VM: GIO's TLS backend is gnutls, the map draws |
| NYX-APP-ASSISTANT-009 | HUD, Aura and visual back off to a minute while the daemon is away (nyx-assistant c739e41) | VM, daemon stopped: no `listen` process in a minute; session-wide process starts down from 170 to ~0 per 20 s (the 65 pids counted were the measuring shell's). The overlays still run while idle |
| NYX-SHELL-009 | trusted folders re-read per connection (nyx-shell 431fd03) | tests |
| NYX-APP-ARCHIVE-004 | names normalised; links through links refused (nyx-archive f107568) | unit test with both shapes |
| NYX-APP-BROWSER-002 | no hold at start without a VPN last time (`nyx.vpn.in-use`); panel says what a workspace VPN covers (nyx-browser a207502) | parse check; in Browser 1.24.2b-3 |
| NYX-UPD-004 | revision installed is verified after the upgrade (else rollback); newest release remembered, older refused (nyx-system 604387b) | unit tests |
| NYX-ARCH-011 | in place when the folder refuses; owner/group kept; O_EXCL temp name (nyx-core a258c31; apps get it with the next crate bump) | unit test |
| NYX-APP-INSTALLER-006 | colon allowed (nyx-installer 8a09b6f) | unit test |
| NYX-CI-008 | committed (see above) | 55 workspaces built |
| NYX-THEME-006 | `sync` removes copies of removed apps (nyx 6b2350c) | scratch run: copy made, app removed, copy cleaned |
| NYX-UX-005 | `GSK_RENDERER=gl` in 29 apps | builds |
| NYX-SET-003 | summaries wrap, no repeated titles, generation value uncut, facts wrap, Power subtitle (nyx-settings 7fce7d3) | VM screenshot |
| NYX-APP-STORE-003 | suite shelf first, complementary essentials, spinner (nyx-store 0add2cb); **icons not done** | VM screenshot (home after loading) |
| NYX-APP-ACTIVITY-002 | `.NAME-wrapped` unwrapped (nyx-activity 49141ed); names cut to 15 characters (`.Hyprland-wrapp`) taken from argv[0] (nyx-activity 76b8a08) | unit tests; the VM showed the first fix missed cut names |
| NYX-UX-006 | Mail (1688db1), Passwords (a1520e8, db2dd15), Theater (04a550a), Calendar (d67cce2), Music (526400e), News (cdca752), Maps (fdf0d98; "Not set" smaller so it isn't cut, ff772a2) | VM screenshots (Passwords not shot: see PRIV-007) |
| NYX-PRIV-007 | owner signed Passwords out in the VM; 15 snapshots made while it was signed in deleted. Passwords had no Sign out while unlocked: added to its Settings (nyx-passwords ce44dc2). Smoke runs skip Passwords' screenshot | `pre-audit2-batch1` (this batch's rollback point) still has it: delete after `stable` is promoted |
| NYX-SHELL-010, -011 | accept pauses on error; surfaces `Restart=always` (nyx-shell a5d528e) | tests; VM: both units `Restart=always` |
| NYX-SHELL-012 | one `pw-dump --monitor` (nyx-bar e9598f1) | unit test; stream parsed on the host |
| NYX-SEC-015 | transient and password/authenticator bodies blanked on close, secure_delete; README (nyx-notification-center 741fa95) | tests |
| NYX-APP-CALENDAR-004 | scrolls when the view first has room (nyx-calendar 20eadca) | VM screenshot: week view opens at 6 AM |
| NYX-APP-MAIL-004 | "Nothing seen yet" (nyx-mail c9e0353) | build |
| NYX-APP-WELCOME-003 | command line handled by the open instance (nyx-welcome e12ce1a) | second launch with `--step` exits 0, first stays |
| NYX-SET-004 | du, nice, journalctl by name (nyx-settings 0fd7a4a) | VM: no `/usr/bin/` tool path left in the binaries |
| NYX-A11Y-004 | tooltips on the seven (nyx-chat 453caab, nyx-notes 2aec963, nyx-activity 656eeba) | builds |

Found on the way: Passwords and the Assistant locked nyx-biometrics ceb41b2, which brought a
second nyx-core into their locks and broke the Nix vendor step (fixed with nyx-biometrics
03117ea: nyx-passwords 2f247e3, nyx-assistant 983477d). nyx-browser's "Nyx checks" CI fails
on rustfmt in the bridge, since before these changes.

Also found in the VM: nyx-design's Nyx.Theme fallback was stale after the Messages accent,
failing nyx-theme's tests (regenerated, nyx-design 57d5bf9). The release workflow for Browser
had never run: mach needs a commit in `engine/` (nyx-browser f1c0bfd). Files' smoke launch
now logs a second, D-Bus-activated copy that exits because the name is taken (not in the
first audit; to look at). Smoke run 2026-11-16: 44 opened, the same 3 without a window as in
the audit (Foot Server, Foot Client, uuctl).

Installer tests: an ISO must be built from nyxos' committed lock. One built with
`--override-input nyx-packages` carries a different system from the one its source pins,
so the install rebuilt ~1000 packages in the live system's memory and stalled (8 GiB) or
failed (12 GiB); from the committed lock it built 122 small pieces and finished in 8 GiB.
The test VM's Incus agent doesn't come back after the live ISO restarts (a new VM is
needed per boot of the ISO).

## W5a (advertised features, first batch), 2026-11-16

Choices in [work-plan.md](work-plan.md#w5-advertised-features). Pinned by nyx-packages
`e59e5e0` (nyxos 3377445 and the pin after it); checked in the dev VM rebuilt at those pins.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-APP-THEATER-001 | MPRIS player `org.mpris.MediaPlayer2.nyx_theater`: play/pause/stop, seek, position, volume, playlist next/previous, title and show in the metadata, Raise and Quit (nyx-theater 3a19d02) | unit tests; VM: a local video's metadata (title, length), PlayPause → Paused → Playing, Seek +5 s, the bar's media card shows it, Quit closes Theater. No cover art yet (Theater's posters are cached per view size) |
| NYX-APP-MAPS-002 | GeoClue on for every desktop (nyxos 3377445); the IP fallback was already off unless turned on in Maps' settings; the no-location message no longer points at a system Location setting (nyx-maps babece6) | VM: GeoClue answers `where-am-i` (beacondb's IP fallback, no Wi-Fi in a VM) |
| NYX-APP-MAPS-001 (B) | directions from OSRM's demo server say so under the route, with the Geoapify key as the way round; the key's description says the same (nyx-maps babece6) | build, tests |
| NYX-APP-GIT-001 | `git-credential-libsecret` (built alone from git's source) as git's helper; `SSH_ASKPASS` = a "Sign in" window (zenity) that git also uses for its username and password questions; gcr's SSH agent was already on (nyxos 3377445) | VM: a credential approved, read back with no prompt, rejected; the window shows git's question with a hidden field. Not yet: a push to a real private remote, and a passphrase key through gcr's agent |
| NYX-APP-CONTAINERS-001 | rootless (`$XDG_RUNTIME_DIR/podman/podman.sock`) and system Podman sockets as Docker candidates, shown as "Podman 5.x" (nyx-containers 1d40af2, bdaf15a); each user's `podman.socket` started when Podman is on (nyxos 3377445); catalog names Podman (nyx-system 71dd711) | VM with Podman on through the overrides file: socket active at login, a rootless container listed running (CPU, memory, uptime), then as exited once its command ended; engine "Podman 5.8.9" |

## W5b, W5c and W5-P3 (advertised features, the rest), 2026-11-16

Pinned by nyx-packages `b22bca5`; checked in the dev VM rebuilt at those pins.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-APP-MAIL-001, CALENDAR-001, CONTACTS-001 (G3) | app passwords as the way in: Settings' Add screen lists Fastmail, Nextcloud, Zoho, Other mail (Gmail, iCloud, any IMAP) and CalDAV/CardDAV servers first, Google and Microsoft sign-in last as "Advanced: needs an OAuth client of your own", its setup guide opening the published copy (NyxOS installed none); catalog and READMEs say the same (nyx-settings 038db63, nyx-system b92590a, nyx-mail ccac23d, nyx-calendar 6c7b3a3) | VM screenshot of the Add screen (full and half width) |
| NYX-APP-REMINDERS-001 | catalog: "Reminders and to-do lists", sync a preview; README's development-branch banner replaced by the status (nyx-reminders ed50fb6) | text. Provider round-trip not run (needs real accounts) |
| NYX-APP-LYRA-001/002/003 (G1: ships, made ready) | catalog note, README and About say unofficial; CI: locked release build and the tests, the YouTube Music parser fixtures among them, on every push (nyx-lyra 1a90863) | first CI run green; memory on NyxOS (VM), signed out and idle 3 min: 20 processes, PSS 454 MB (Lyra 113, three web processes 187/57/26, network process 68; the rest sandbox helpers under 1 MB each). Signed in not measured (needs the account) |
| NYX-APP-PASSWORDS-001 (B for now) | catalog makes no autofill claim; publishing the extension waits for the repository reorganization | — |
| NYX-APP-ASSISTANT-001 (rest) | NyxOS routes for night light, keep awake (Control Center's unit), switching audio output (wpctl), the Theme and Keyboard Shortcuts pages, a private browser window and full width (a typed Hyprland action); the twelve with nothing like them on NyxOS (next wallpaper, bar, gaps, animations, transparency, layout, copy text, touchpad, screensaver, fullscreen desktop, pop window, emoji) left the defaults; Music, Passwords, Write, Calculator and the colour picker open the Nyx apps; a test fails on any default without a NyxOS route (nyx-assistant abd5280, dd11450) | unit tests; VM: keep awake registers and drops the idle inhibitor, the audio switch picks the next sink, night light 4000 K on, 6500 K off. Not spoken to (voice tests wait for you) |
| NYX-APP-CHAT-001, NYX-VOICE-003 | dictation (push to talk) and reading aloud through Nyx Voice when it runs; whisper.cpp and Piper stay as the fallback (nyx-chat 2161b99) | build, tests. Not spoken to |
| NYX-APP-PULSE-002 | deferred with Pulse (G1: out of 0.1) | — |
| NYX-APP-FONTS-001 | Store item (nyx-system b92590a) | VM: `nyx-system catalog` lists nyx-fonts |
| NYX-APP-FONTS-002 | downloads fall back to Google's google/fonts repository on GitHub; the Google and Nerd Fonts lists are fetched apart and a failing one keeps its saved copy with a message naming it (nyx-fonts 401adc7) | unit tests; the GitHub folder and file names checked against the live repository |
| NYX-APP-CLOUD-002 | Store note "Set up in Settings › Cloud Storage"; CI runs the unit tests and the integration test, on a private bus where no Secret Service can start (nyx-cloud f364454, f805e64, 6576279) | CI green (it had been red since 2026-11-02: glib's development files were missing, and Ubuntu's rclone is too old) |
| NYX-APP-TRANSFER-001 | "Copy files to and from servers (SFTP, FTP, WebDAV)." | text |
| NYX-APP-MEDIA-PLAYER-002, THEATER-003 | Media Player's summary says videos; Theater claims no video types (nyx-theater 93031ea); NyxOS makes Media Player the default for the 19 video types (nyxos b92eb9e) | VM: `xdg-mime query default video/mp4` → Media Player |
| NYX-APP-NEWS-001 | the README's "reserved" line was stale: sync, discovery and summaries are implemented; README corrected (nyx-news a636915) | code read |
| NYX-APP-TORRENTS-002 | on NyxOS, Settings › Connection has "Allow incoming connections" (both protocols through `nyx-system apply`, as an administrator); a one-time notice says UPnP opens the port on the router and where to turn it off (nyx-torrents b34afd0) | unit tests; VM: the notice on first run. The switch itself not screenshotted (opening the settings page from the command line didn't work twice) |

Found on the way: hyprsunset wasn't installed, so Settings' Night Light and the Control
Center's tile couldn't work on NyxOS (now in the desktop's packages, nyxos b92eb9e); and
turning night light off left hyprsunset reporting the night temperature, so the tile
stayed on (nyx-control-center c2dc19e). Running Cloud's integration test under a plain
`dbus-run-session` let gnome-keyring hand it the session's real keyring; the item was
checked unchanged, and the test now runs on its own bus.

## W6 and W6-P3 (Omarchy leftovers that run on NyxOS), 2026-11-16

Pinned by nyx-packages `2e1eff4`; checked in the dev VM rebuilt at those pins.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-APP-SETTINGS-001 | VPN: providers whose app is AUR-only import their WireGuard or OpenVPN file on NyxOS (no `omarchy-pkg-*`); OpenVPN detected through `/etc/NetworkManager/VPN`; NyxOS ships NetworkManager's OpenVPN plugin (nyx-settings 2ee5cfa, nyxos network.nix) | VM: `/etc/NetworkManager/VPN/nm-openvpn-service.name` present. Import with a real `.ovpn` not run |
| NYX-APP-CONTAINERS-002, -003, -004 | on NixOS, Fix is Open Store at the Docker or Incus catalog item (service, group and consent there); no VTE check in a Nix build; group checks and the catalog's consent say docker, incus-admin and libvirtd amount to administrator rights; the user from the user ID, no literal name (nyx-containers 282867e, nyx-system 9601ad1) | unit tests (catalog consent text, NixOS commands) |
| NYX-APP-BIOMETRICS-001, -003 | a System Manager setting `biometrics` (nyx.biometrics: face, fingerprint, keys and where each signs in), checked as the module checks it; Settings' Sign-in page on NyxOS reads `/etc/nyx/biometrics.json`, changes go through the System Manager, "Turn on…" instead of yay/pacman, no helper install, Apply banners or PAM undo (nyx-system ee28efd, nyx-settings 2ee5cfa, 56c72d2, nyxos overrides.nix) | unit tests; VM screenshot: the table shows the configuration (sudo face then fingerprint, lock screen fingerprint then face), NyxOS footer, no terminal actions. A change applied from the page not run |
| NYX-APP-BIOMETRICS-002 | Nyx Prompt: "Use password instead", or typing, while a face, finger or key is awaited ends the conversation and starts it again password first; the gate skips the methods for administrator prompts while the person's fresh marker (`/run/user/UID/nyx-auth/password-first`) is there; skipping only ever leaves the password (nyx-greeter 85cf308, nyx-biometrics f0ae8ad) | unit tests; VM: the gate skips for polkit-1 with the marker, not without. With a reader not run (the VM has none). sudo in a terminal still waits for its fingerprint timeout |
| NYX-APP-BIOMETRICS-004 | already fixed (trusted-bin.system) | VM: `/etc/nyx/trusted-bin` lists Biometrics' bin |
| NYX-APP-CAPTURE-001 | NyxOS's Hyprland rules float, pin and place WebcamOverlay-small/medium/large bottom right without focus; Settings' Capture page opens Nyx Capture's settings instead of a warning about Omarchy's tools (nyxos hyprland.nix, nyx-settings 637f36b) | rules in the rendered hyprland.lua. Overlay with a webcam not run |
| NYX-APP-PHOTOS-001 | Set as background through nyx-themed's new `SetWallpaper` (Omarchy's command where installed) (nyx-system 9a40ba7, nyx-photos 442a69f) | D-Bus test; VM: sets the wallpaper, refuses a missing file, `""` goes back to the theme's |
| NYX-APP-CLIPBOARD-001, NYX-APP-AGENTS-001 | Settings reads `nyx-settings/extensions` in `$XDG_DATA_DIRS` (user's own win, packaged ones can be turned off, not removed); Clipboard's, Passwords' and Glimpse's pages packaged (nyx-settings 2ee5cfa, nyx-packages 2e1eff4) | VM: Agents, Clipboard, Glimpse and Passwords listed; Agents and Clipboard tabs in Settings |
| NYX-VOICE-001 | F9 and Right Alt held, Super+Ctrl+X bound; Nyx Voice on by default; Settings offers the speech model (650 MB) when it's missing; a key press without it says so in a notification (nyxos hyprland.nix, apps.nix, nyx-voice 81fb1e5, nyx-settings 27742a3) | VM: the five binds, `nyx-voiced.socket` active. Not spoken to |
| NYX-APP-BACKUP-002, -004 | no offline boot kit on NixOS; Restic from Arch's or NixOS's system folders; package handoff marked manual (install from the Store) (nyx-backup 6e79f14) | unit tests |
| NYX-APP-ACTIVITY-001 | already fixed by the Startup page's rewrite (Omarchy's entries only when its file exists) | code read |
| NYX-APP-FILES-002 | the media-plugin hint names Arch only where pacman is; dead "Follow Omarchy" search entries removed (nyx-files 6cdc8d15, 69f49a64) | package build (its locale test caught two missing translations) |
| NYX-APP-GIT-002 | no editor set opens the folder; terminal error without Omarchy (nyx-git 860b780) | build |
| NYX-APP-WEATHER-001 | NyxOS: no nyx.lua rule or Hyprland reload; the window is floated live when it opens (nyx-weather 2bb699f) | build |
| NYX-APP-PULSE-003 | Telegram device name from os-release ("Nyx Desktop (NyxOS 0.1.0)") (nyx-pulse fd2cbdf) | unit test |
| NYX-APP-ASSISTANT-008 | package and admin tools offered only where pacman is (nyx-assistant 433063f) | unit tests (one canvas test fails before and after the change) |
| NYX-APP-SHARE-002 | the sandbox binds the Nix store and system profile on NixOS; bwrap on the package's PATH (nyx-share 9c0b141) | unit tests. An extension in the Share Sheet not run |
| NYX-APP-STORE-002 | a failing later step says what was already done ("System changes applied; Flathub failed: …") (nyx-store f0b3497) | unit tests |
| NYX-APP-PASSWORDS-003 | the newest Hyprland instance's socket when the daemon lacks HYPRLAND_INSTANCE_SIGNATURE (nyx-passwords a8be05a) | build (no live Passwords tests) |
| NYX-SET-001 | resets name NyxOS's defaults (nyx-settings 2ee5cfa) | build |
| NYX-ARCH-009 | minimize was already left out on NyxOS; the Control Center's switches are the `toggles` provider (`toggles.*` ops, old names still answered) (nyx-control-center c0fa3e4) | tests |
| NYX-UX-002 | one offline message for rebuilds, Flathub and Nix profile installs, the Store's Flathub header and Nyx AI downloads (nyx-system 9601ad1, nyx-store f0b3497, nyx-ai 277b9a5) | unit test of the matcher. Not run offline |
| NYX-UX-004 | `nyx-system generations` prints local dates (nyx-system 9601ad1) | VM |

Found on the way: the shell's "stopped" notice fired after every crash, also one systemd
restarted at once (the old shell crashed in Qt's icon loader during a switch); it now
waits and stays quiet when the shell is back (nyx-packages 2e1eff4; VM: a crash restarts
the shell without the notice).

## W7 and W7-P3 (integration: actions, Glimpse, per-user apps), 2026-11-17

Pinned by nyx-packages `da4fca5`; checked in the dev VM rebuilt at those pins.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-APP-GLIMPSE-001 | a semantic hit without a path is skipped instead of panicking the search (nyx-glimpse 058ad7a) | Glimpse's tests |
| NYX-APP-MAIL-002 | Glimpse read plugins only from its own folder, so no app's plugin loaded on NyxOS, system or per user; it now also lists `nyx-APP/glimpse` in the user's data folder and every `$XDG_DATA_DIRS` folder (Nix profiles included), to enable after review; a packaged one is turned off, not removed, and updates with its app (nyx-glimpse 058ad7a) | unit test; VM: `nyx-glimpse plugins list` shows Agents, Calendar, Capture, Mail, News, Notes, Pulse and Reminders |
| NYX-APP-CALENDAR-002, NYX-PKG-009 | no change needed now: the session bus reads `~/.nix-profile/share/dbus-1/services` (dbus-broker's `XDG_DATA_DIRS`), the catalog reloads it and starts the app's units after a per-user install, and nyx-actions reads `nyx/actions` in every `$XDG_DATA_DIRS` folder | VM: a new user service file is activatable after the reload (not before); Calendar's manifest alone in a folder on `XDG_DATA_DIRS` makes `calendar` appear in `nyx-actions apps`, and not without it. A real per-user install not repeated (every app with actions is system-wide in the VM) |
| NYX-AI-003 | already done (nyx-assistant 2b8e8f6, 2026-11-09): the nyx-apps ability's `actions.list` and `actions.run` use AI Core's registry (running one always asks first), and its app tools go through AI Core as Glimpse's do | VM: AI Core lists Calendar's 11 actions and runs `calendar.search`; the packaged ability has `actions.run` |
| NYX-APP-ASSISTANT-002 | launcher entry "Assistant" opening Settings › Assistant (where it's turned on), with an icon in the suite's set (nyx-assistant fd8871f, nyx-design 1e07cd8) | VM: entry and icon installed |
| NYX-APP-CAPTURE-002, MEDIA-PLAYER-001, THEATER-002, TORRENTS-003, FONTS-003, CONTACTS-003 | control API 2 descriptions with risks and D-Bus activation, manifests installed (`actions = [ … ]`); started for a call: Capture and Contacts' lookups and Media Player's search answer without a window (Media Player waits for its library), Theater, Torrents, Fonts and changes in Contacts open the window first (Torrents waits for its engine); one required argument can be given bare; Torrents' and Fonts' READMEs and Torrents' python hint for NyxOS (nyx-capture 775e918, nyx-contacts 67d0e79, nyx-media-player 59c978c, nyx-theater fab75f8, nyx-torrents e7c9eb4, nyx-fonts 6370f70) | unit tests; VM, each app closed: `nyx contacts find`, `nyx video search` and `nyx capture search` answer with no window; `nyx torrents list`, `nyx theater search`, `nyx fonts installed` open their app and answer at once |
| NYX-APP-CHAT-003 | READMEs: the system theme, NyxOS's or Omarchy's; catalog: "Chat with AI models on this computer or your own servers." (nyx-chat 3909270, nyx-system 39ced93) | text |

## W8 (updates and the System Manager), 2026-11-17

Pinned by nyx-packages `b0ccdaa`.

| Finding | Fix | Verified |
| --- | --- | --- |
| NYX-UPD-001 | The System Manager's Upgrade takes a stage: `prepare` fetches and builds, compares the build with the running system (package versions from `nix store diff-closures`, closure size change, a kernel/initrd change meaning a restart, programs running from replaced files) and puts flake.lock and tools.json back, keeping the new ones aside, so nothing changes and another system change can't take the update along; `finish` puts them back in place, builds again (from the store) and switches only if the result is exactly the prepared build; `discard` drops it (prepared updates expire after a day or when the generation changes). The default stays all at once for unattended updates. `nyx update` shows the changes, size and restart before "Update?" (declining sets it aside); `--dry-run` shows them and sets them aside; `--prepare`, `--finish`, `--discard` for other programs. The Store's review lists the system's package changes, size and restart and confirms with `--finish` (cancelling discards); Settings shows a dialog with the same before any update that rebuilds the system (nyx-system 3f3c454, nyx-store ef87942, nyx-settings a8189de) | unit tests (request stages, serialisation an older manager reads); VM: finish with nothing prepared says so, discard answers, the new options are in `nyx update --help`. A prepare against a real channel update not run: the dev VM's flake has no channel, and an installed test VM following one wasn't available (and memory was short) |
| NYX-UPD-002 | README corrected: stable's flake.lock pins nyx-packages to the commit nyx-packages' stable branch points at, both moved together by `promote-stable` (signed tag, CI green on both commits, fast-forward only — already in place). The input URL stays nyx-packages' main: stable is always a commit of main, so it can't have its own flake.nix, and pointing main at nyx-packages' stable would make every development pin bump fetch the old release; pins change on main and reach stable only by promotion | `promote-stable` read; README |
