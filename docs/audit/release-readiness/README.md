# NyxOS 0.1.0 release-readiness audit

Handoff 10, run 2026-11-12 against nyxos `97f1573` and nyx-packages `d69e87e` (the
`origin/main` of both at the start; tag `v0.1.0` is nyxos `d632770`). Evidence-based:
static review of every repository, full builds, an ISO install, and functional, failure
and performance tests in two VMs. **Nothing was fixed**; this folder is the only change.

## 1. Executive summary

**NyxOS is not ready for a public release, but it's close in most places.** The desktop
itself is in good shape: everything builds reproducibly from its pins, the installed
system boots in 15 s and signs in to Welcome in 2 s, 46 of 48 launcher entries open (the other two are helper entries) in under a
second, the shell's backends recover from crashes within 4 s, the lock screen can't be
bypassed by crashing it, live theme changes reach every surface, rollback and backup
restore work, and the apps look like one suite.

What blocks release is concentrated in installation, the update channel, packaging for
per-user apps, and accessibility:

1. **The 0.1.0 ISO can't install** (P0, NYX-INST-001). NyxOS's new live image (added
   the night before the tag) has no `/mnt`; the installer fails at step 11 of 43 after
   erasing the disk. With `/mnt` created, the same install completes in 112 s.
2. **Installed machines stop accepting system changes after the first weekly garbage
   collection** (P1, NYX-INST-002): the machine's lock points at the ISO's copy of NyxOS,
   which nothing keeps alive. Verified end to end; `nyx update` doesn't repair it.
3. **The release pipeline doesn't gate anything** (P1, NYX-CI-001/002/003): CI has
   failed on every push since 10 November at a format check, there's no branch protection,
   and the `stable` channel the installer writes is 40 commits behind `v0.1.0`.
4. **Welcome can't install two suite apps that run session services** (P1,
   NYX-PKG-008), and per-user apps don't get their D-Bus activation and actions
   (NYX-PKG-009).
5. **Assistive technology is switched off on every install** (P1, NYX-A11Y-001); the
   default theme fails WCAG AA for secondary text (NYX-THEME-002, NYX-A11Y-002).
6. **Some advertised features don't exist or don't work** (P1): Podman in Containers,
   Passwords autofill, Mail's Google/Microsoft accounts without your own OAuth app, the
   Assistant opening apps by voice, phones sending to NyxOS through Share (blocked by the
   firewall), scheduled backups after garbage collection, the installer's keyboard
   layout for passwords, and Office's in-place save of Word files (untested at runtime).
7. **No physical hardware has been tested** (P1, NYX-HW-001).

No P0/P1 security issue was found. The worst security issues are P2: an unauthenticated
local AI endpoint reachable through DNS rebinding, spoofable app identity at a root key
service, Connect's port open on every network, the primary user in `input`, and a
passwordless recovery console.

**Recommended next action:** fix the fourteen blockers in
[remediation.md](remediation.md) §1 (about 1–2 weeks plus a hardware pass), ship a
smaller 0.1 (move Lyra, Pulse, Assistant and Containers to a labelled Preview), and rerun
the gates in [gates.md](gates.md). Every finding: [issues.md](issues.md) (232: 1 P0,
15 P1, 89 P2, 127 P3).

## 2. Verified release inventory

[release-inventory.md](release-inventory.md): what an install actually ships (base tier,
Welcome tier, Store tier), with the audit's status per component. Corrections to the
handoffs' picture: Desktop Widgets are packaged but enabled nowhere; Notification Center
and Switcher still run their GTK front ends; Biometrics can only be enabled in the
machine's NixOS configuration; Aura lives inside the Assistant. All 68 repositories (plus 7 worktrees and folders):
[inventory.md](inventory.md) (pins current except Flux, deliberately at v0.19.1; shared
crates drift across 10 nyx-core and 7 nyx-design revisions).

## 3. Architecture assessment

[architecture.md](architecture.md). Hyprland (patched) is the compositor, Quickshell draws
the shell surfaces, Rust services own backends, nothing in the shell runs as root. The
main deviation from handoffs 01 and 03: Shell Core exists but most of the shell bypasses
it (six processes watch Hyprland themselves; most surfaces skip its overlay registry; no
shortcut goes through its router). Five IPC mechanisms coexist. Hyprland patch series:
13 patches, +2,834/−75, replays cleanly on upstream main; four high-risk patches and no
automated tests ([hyprland-patches.md](hyprland-patches.md)).

## 4. System assessment

| Area | Score | Basis |
| --- | ---: | --- |
| Installation | 0 | Broken on the 0.1.0 ISO (NYX-INST-001); fine once `/mnt` exists ([installation.md](installation.md)) |
| Boot | 3 | Installed system: LUKS prompt at 7.8 s, login at 17.6 s, no failed units |
| Recovery | 2 | Rollback 4 s; failed builds undone; interrupted change not undone (NYX-REL-002); recovery console untested and unprotected (NYX-SEC-005) |
| Updates | 1 | Channel behind the release (NYX-CI-003); system changes break after GC (NYX-INST-002); no package diff in plans (NYX-UPD-001) |
| Security | 2 | No bypass found; P2 issues listed above ([security.md](security.md)) |
| Hardware compatibility | 0 | Nothing tested on metal ([hardware.md](hardware.md)) |

Scores: 0 broken or missing, 1 major gaps, 2 minor gaps, 3 no significant gaps found;
based only on this audit's evidence.

## 5. Shell assessment

| Area | Score | Basis |
| --- | ---: | --- |
| Reliability | 2 | Backends recover in < 4 s; lock chain robust; crash loop leaves no shell (NYX-SHELL-001); no bar/dock on hot-plugged monitors (NYX-REL-003) |
| Performance | 2 | 1.7 % idle CPU; theme change 375 ms; Quickshell 297 MB in one process |
| UX | 2 | Consistent, fast; Glimpse unavailable while Shell Core is down (NYX-SHELL-002) |
| Accessibility | 1 | AT disabled (NYX-A11Y-001); keyboard paths missing outside Glimpse (NYX-SHELL-005) |
| Architecture compliance | 1 | Shell Core largely bypassed (NYX-ARCH-001/002) |

Details: [shell.md](shell.md), [reliability.md](reliability.md).

## 6. Application assessment

One scorecard per app in [apps/](apps/) (static review plus smoke test, startup time and
memory where measured). Scores 0–3 as above; "n/v" not verifiable.

| App | Tier | Funct. | UX | A11y | Relia. | Integ. | Pack. | Maint. | P1 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| [activity](apps/activity.md) | base | 3 | 2 | 2 | 3 | 2 | 3 | 2 | |
| [backup](apps/backup.md) | base | 2 | 2 | 2 | 1 | 2 | 2 | 2 | BACKUP-001 |
| [capture](apps/capture.md) | base | 2 | 2 | 2 | 2 | 2 | 2 | 2 | |
| [files](apps/files.md) | base | 3 | 3 | 2 | 2 | 3 | 3 | 2 | |
| [glimpse](apps/glimpse.md) | base | 3 | 2 | n/v | 2 | 3 | 2 | 2 | |
| [greeter](apps/greeter.md) | base | 3 | 2 | 2 | 2 | 3 | 3 | 2 | |
| [installer](apps/installer.md) | media | 2 | 2 | 2 | 2 | 2 | 3 | 1 | INSTALLER-001 (+ NYX-INST-001 P0) |
| [settings](apps/settings.md) | base | 2 | 2 | 2 | 2 | 2 | 3 | 2 | |
| [share](apps/share.md) | base | 2 | 2 | 2 | 2 | 2 | 2 | 2 | SHARE-001 |
| [store](apps/store.md) | base | 2 | 2 | 2 | 2 | 2 | 2 | 2 | |
| [welcome](apps/welcome.md) | base | 3 | 2 | 2 | 2 | 3 | 3 | 1 | |
| [archive](apps/archive.md) | welcome | 3 | 2 | 2 | 2 | 2 | 3 | 2 | |
| [assistant](apps/assistant.md) | welcome | 2 | 2 | 1 | 2 | 1 | 2 | 2 | ASSISTANT-001 |
| [calculator](apps/calculator.md) | welcome | 3 | 2 | 2 | 3 | 2 | 2 | 2 | |
| [calendar](apps/calendar.md) | welcome | 2 | 2 | 2 | 3 | 2 | 3 | 2 | |
| [chat](apps/chat.md) | welcome | 2 | 3 | 2 | 3 | 2 | 2 | 2 | |
| [contacts](apps/contacts.md) | welcome | 2 | 2 | 2 | 3 | 2 | 3 | 2 | |
| [containers](apps/containers.md) | welcome | 2 | 2 | 2 | 3 | 2 | 2 | 2 | CONTAINERS-001 |
| [git](apps/git.md) | welcome | 3 | 3 | 3 | 3 | 2 | 3 | 3 | |
| [home](apps/home.md) | welcome | 3 | 2 | 3 | 2 | 3 | 3 | 2 | |
| [lyra](apps/lyra.md) | welcome | 2 | 2 | 2 | 2 | 3 | 2 | 1 | |
| [mail](apps/mail.md) | welcome | 2 | 2 | 2 | 3 | 2 | 2 | 3 | MAIL-001 |
| [media-player](apps/media-player.md) | welcome | 3 | 3 | 2 | 3 | 2 | 3 | 2 | |
| [music](apps/music.md) | welcome | 3 | 3 | 2 | 3 | 3 | 3 | 2 | |
| [news](apps/news.md) | welcome | 3 | 2 | 2 | 3 | 3 | 3 | 2 | |
| [notepad](apps/notepad.md) | welcome | 3 | 2 | 2 | 3 | 2 | 3 | 2 | |
| [notes](apps/notes.md) | welcome | 3 | 2 | 2 | 3 | 3 | 3 | 2 | |
| [office](apps/office.md) | welcome | 2 | 2 | 2 | 2 | 2 | 3 | 2 | OFFICE-001 |
| [passwords](apps/passwords.md) | welcome | 2 | 2 | 2 | 3 | 2 | 2 | 3 | PASSWORDS-001 |
| [pdf](apps/pdf.md) | welcome | 3 | 2 | 2 | 2 | 2 | 3 | 2 | |
| [photos](apps/photos.md) | welcome | 2 | 2 | 2 | 3 | 2 | 3 | 2 | |
| [pulse](apps/pulse.md) | welcome | 2 | 2 | 2 | 2 | 2 | 2 | 2 | |
| [theater](apps/theater.md) | welcome | 3 | 3 | 2 | 3 | 2 | 3 | 3 | |
| [torrents](apps/torrents.md) | welcome | 3 | 2 | 2 | 3 | 2 | 3 | 2 | |
| [clipboard](apps/clipboard.md) | store | 3 | 2 | 2 | 3 | 2 | 2 | 2 | |
| [cloud](apps/cloud.md) | store | 2 | 2 | n/v | 3 | 2 | 3 | 2 | |
| [maps](apps/maps.md) | store | 2 | 2 | 2 | 2 | 2 | 2 | 2 | |
| [reminders](apps/reminders.md) | store | 2 | 3 | 2 | 2 | 3 | 3 | 2 | |
| [transfer](apps/transfer.md) | store | 2 | 2 | 2 | 3 | 2 | 2 | 2 | |
| [weather](apps/weather.md) | store | 3 | 3 | 2 | 3 | 2 | 3 | 2 | |
| [agents](apps/agents.md) | not offered | 2 | 2 | 1 | 2 | 2 | 2 | 2 | |
| [biometrics](apps/biometrics.md) | not offered | 2 | 1 | 2 | 2 | 1 | 2 | 3 | |
| [fonts](apps/fonts.md) | not offered | 3 | 3 | 2 | 3 | 2 | 3 | 2 | |

App accessibility scores rate the apps' own controls; system-wide, assistive technology
is off until NYX-A11Y-001 is fixed. App scores are mostly static; runtime added smoke
launches for all, startup and memory for 18, and targeted tests for Files, Backup, Archive
and the per-user install path (each scorecard's "Runtime results").

## 7. Shared infrastructure assessment

[infrastructure.md](infrastructure.md) (scorecard per component: API stability, security,
performance, failure isolation, test coverage, documentation). Theme Engine works live and
consistently but is compiled into apps at 7 revisions; AI Core is well designed
(versioned API, leases, supervision) with an unauthenticated public endpoint; Nyx Voice
models are unverified downloads and dictation isn't wired on NyxOS; Connect is a thin,
correct layer over upstream fluxd; the System Manager restores on failed builds but not on
interrupted ones; Settings' configuration layers are sound.

## 8. UX and accessibility assessment

[ux-accessibility.md](ux-accessibility.md). Design consistency is good across the suite.
Accessibility fails Gate G: AT disabled system-wide, contrast below WCAG AA in 15 of 17
themes for secondary text (default included), shell surfaces largely pointer-only, no
screen reader at the login screen. With the AT bridge forced on, GTK apps expose
well-named controls, so the apps themselves are close.

## 9. Security and privacy assessment

[security.md](security.md), [privacy.md](privacy.md). No P0/P1. Confirmed at runtime:
NYX-SEC-001 (AI endpoint open to any local user, DNS rebinding, text/plain POSTs),
NYX-SEC-002 (key service spoof), NYX-SEC-003, NYX-SEC-004, NYX-PRIV-001 (silent screen
capture). Installed systems have no autologin or preset password and SSH is off.

## 10. Performance and reliability assessment

[performance.md](performance.md), [reliability.md](reliability.md). VM-only numbers: boot
13.9–15.5 s, login 2 s, apps 0.45–0.94 s to first window and 130–235 MB each, idle 1.7 %
CPU. Failure tests: backends, lock screen, low memory, disk full, network loss, rollback
and backup restore pass; crash loop, monitor hot-plug and interrupted changes fail.

## 11. Packaging and CI assessment

[build-report.md](build-report.md), [packaging-ci.md](packaging-ci.md),
[dependencies.md](dependencies.md), [docs-review.md](docs-review.md). Builds are
reproducible from pinned inputs (all checks and the ISO pass; 373 tests ran in the rebuilt
derivations, 0 failed), but CI is red, unprotected and doesn't build the ISO; 16 core
repositories have no CI; nine hand-pinned packages and several forks need manual upkeep;
no automated dependency monitoring; no user documentation.

## 12. Release blockers

| ID | Sev | Summary |
| --- | --- | --- |
| [NYX-INST-001](installation.md) | P0 | 0.1.0 ISO can't install (`/mnt` missing) |
| [NYX-INST-002](installation.md) | P1 | System changes fail after the first weekly GC |
| [NYX-CI-001](packaging-ci.md) | P1 | CI red since 10 Nov; nothing built |
| [NYX-CI-002](packaging-ci.md) | P1 | No branch protection; ungated `stable` |
| [NYX-CI-003](packaging-ci.md) | P1 | Installer's channel (`stable`) is behind 0.1.0 |
| [NYX-PKG-008](packaging-ci.md) | P1 | Two session-service apps can't both install per user |
| [NYX-A11Y-001](ux-accessibility.md) | P1 | Assistive technology disabled |
| [NYX-HW-001](hardware.md) | P1 | No physical hardware tested |
| [NYX-APP-INSTALLER-001](apps/installer.md) | P1 | Passwords typed in US layout regardless of choice (static) |
| [NYX-APP-BACKUP-001](apps/backup.md) | P1 | Scheduled backups stop after GC |
| [NYX-APP-SHARE-001](apps/share.md) | P1 | Firewall blocks receiving through Share |
| [NYX-APP-OFFICE-001](apps/office.md) | P1 | In-place save may drop document content (static) |
| [NYX-APP-MAIL-001](apps/mail.md) | P1 | Google/Microsoft need the user's own OAuth app |
| [NYX-APP-PASSWORDS-001](apps/passwords.md) | P1 | Autofill advertised, no extension |
| [NYX-APP-CONTAINERS-001](apps/containers.md) | P1 | Podman advertised, not supported |
| [NYX-APP-ASSISTANT-001](apps/assistant.md) | P1 | Voice app launches call Omarchy tools |

## 13. Recommended remediation roadmap

[remediation.md](remediation.md): immediate blockers in dependency order, required
pre-release corrections, recommended improvements, post-release enhancements, deferred
roadmap work, and the recommended smaller first-release scope.

## 14. Deferred enhancements

[remediation.md](remediation.md) §4–5: Quickshell migration of the Notification Center
and Switcher, Desktop Widgets, Assistant on the shared action registry, Chat voice through
Nyx Voice, firmware updates by default, CUDA in CI, and the unimplemented handoff items
that aren't first-release requirements.

## 15. Release gate checklist

[gates.md](gates.md). A pass at pinned revisions (not enforced); B fail; C fail
(conditional); D pass with conditions; E not verified; F fail; G fail; H fail; I fail.

## 16. Evidence appendix

| What | Where |
| --- | --- |
| Finding format and severity scale | [evidence/FINDINGS-FORMAT.md](evidence/FINDINGS-FORMAT.md) |
| Runtime working notes (everything observed, in order) | [evidence/runtime-notes.md](evidence/runtime-notes.md) |
| Repository facts | evidence/inventory.json, evidence/shared-crate-pins.txt |
| Build logs and timings | evidence/logs/build-summary.txt, `*-flake-check.log.gz`, `iso-build.log.gz` |
| Install test | evidence/logs/install-*, `installed-*` (credentials redacted), shots/installed-*.png |
| Functional and failure tests | evidence/logs/shell-*, lock-crash, rollback, backup-restore*, archive-zipslip, connect-*, network-loss, low-memory, disk-full, monitor-hotplug, interrupted-system-change, config-corruption |
| Smoke tests | evidence/smoke-dock/ (report and 47 screenshots), evidence/smoke-glimpse/report.tsv |
| Performance | evidence/logs/perf-*.txt, runtime-ai-core*.txt |
| Security probes | evidence/logs/runtime-security-probes.txt, runtime-listening.txt, runtime-ai-core-*.txt |
| Accessibility | evidence/contrast.md, evidence/logs/atspi-buttons.txt |
| Screenshots | evidence/shots/ |
| Scripts to reproduce | evidence/scripts/ (inventory, build validation, contrast, serial console driver, issue register, scorecard filler) |

## Method and limits

- Phases A–G of handoff 10 §35. Static review used nine parallel reviewers with one
  finding format; their claims were spot-checked and the P1s re-verified (CI runs, channel
  lag, installer channel) before inclusion.
- All runtime work ran in VMs: the dev VM (restored to its prior snapshot afterwards) and
  a disposable install VM (left stopped, with a `fresh-install` snapshot). The dev VM was
  on generation 245 (another session's rebuild at 00:56: nyx-packages `9557afd`, which
  differs from the audited pins only by one nyx-files commit).
- Not covered: physical hardware, suspend/resume, Bluetooth, Wi-Fi, audio, voice and
  wake word, phone pairing, the graphical installer's pages, Welcome's apply step,
  Office round trips, frame timing, and cloud accounts.
