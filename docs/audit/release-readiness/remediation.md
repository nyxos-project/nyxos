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
