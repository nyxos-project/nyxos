# NyxOS audit, 14 November 2026

A second look, two days after the [0.1.0 release-readiness audit](../release-readiness/README.md):
what changed since (about 350 commits in 58 repositories), whether the first round of
fixes holds, and a search for what the first audit didn't cover. Nothing was fixed; this
folder is the only change. Findings already open in the first audit's
[work plan](../release-readiness/work-plan.md) aren't repeated.

Against nyxos `ed46205`, nyx-packages `9045e4c` and each app's `main` on 14 November
(`evidence/heads.tsv`).

## Result

33 findings: **3 P1, 8 P2, 22 P3**, in [issues.md](issues.md). No P0.

The three P1s:

1. **NYX-APP-INSTALLER-005.** The installer's new "An earlier install didn't finish…
   Remove them" appears for a *finished* NyxOS beside Windows too (it goes by partition
   names alone), and one click without confirmation wipes it. On `stable` since
   known-good/24.
2. **NYX-INST-004.** The live USB starts in BIOS mode but NyxOS installs only on UEFI, and
   the installer doesn't check: the disk is erased, then the install fails. Not yet run in
   a VM.
3. **NYX-APP-BROWSER-001.** Browser's VPN sends any host whose name starts like a private
   address (`10.attacker.com`, `192.168.example.org`, `localhost.attacker.com`) around the
   VPN, so a page can read the real address. Confirmed against the pattern.

P2: Browser's native-messaging folder is one level off and works only through a per-user
link (PKG-010, confirmed in the VM); Passwords from Welcome gets no manifest, so autofill
doesn't connect on a fresh install (PKG-011); `nyx install nyx-APP` installs from
nyx-packages' development branch, outside the signed channel (UPD-003); Cloud's accounts
stop silently when its keyring item is missing (APP-CLOUD-003); screen-capture permission
rules name store paths that change with updates (HYPR-010); Maps shows no map in the VM
(APP-MAPS-004); the Assistant's overlays start a failing command every second when its
service isn't running (APP-ASSISTANT-009, confirmed in the VM); Shell Core keeps the
trusted-programs list it read at start, so programs moved by an update lose their rights
until the next sign-in (SHELL-009).

The fixes from the first audit that were re-checked hold ([regressions.md](regressions.md)),
apart from the installer's leftover removal, which brought the first P1 above. Four
data-safety fixes (Archive, Notepad, PDF, Photos) are on their apps' `main` but not yet
pinned by nyx-packages.

## What was covered

| Pass | Done |
| --- | --- |
| Baseline | Every checkout's branch, head and state; nyx-packages' pins against each `main`; CI runs |
| OS, install, update | Every change to nyxos' modules, ISO and scripts and nyx-packages' modules since the first audit; the installer's `plan.rs`, `disks.rs`, `run.rs` and its disk and failure pages in full; release signing; System Manager's staged changes; Recovery's sign-in |
| Security-sensitive changes | Archive's extraction check (tested with crafted archives and 7-Zip 26.04), the AI endpoint's key and Host check, nyx-core's watcher fix, Passwords' daemon and bridge changes, Cloud's configuration encryption, Browser's VPN module |
| Data safety | Notepad's encoding and save path, nyx-core's `atomic_write`, PDF's save |
| Runtime | VM rebuilt at current pins (snapshot `pre-audit-20261114`); every launcher entry opened from the dock (`evidence/smoke-dock/`); one screenshot of each of 44 apps read; journal, failed units and core dumps; the settings in regressions.md |
| Shell | nyx-shell core server and trust; dock plugin; fault-class sweeps over the nine shell repositories; idle process and CPU sampling in the VM |
| Revamps | 27 apps at half width in dark and light (54 screenshots); selected code read; searches over all revamp diffs |
| Suite-wide | Tracked secrets and large files; unfinished-code markers (none); shell command strings (all constant, quoted or behind an approval); hard-coded /usr paths (211, nearly all Arch-only code); in the VM every launcher, D-Bus service and user unit resolves to a program and icon that exist; clippy on five repositories |

## What wasn't

Said plainly, since the plan promised more than this run reached:

- **Shell code** (added in a second sitting): read in full only nyx-shell's socket server,
  peer trust and units, the dock's Hyprland plugin, and the Notification Center's reader
  check. The other eight shell repositories (about 150,000 lines) were swept for classes
  of fault, not read: panics on parsed or outside input (none outside tests), shell
  command strings (one, with constant input), repeating timers and polling (all bounded
  or tied to a subscriber, except SHELL-012), and what an idle session starts (found
  APP-ASSISTANT-009). Not done: overlay focus hand-back, hot-plugged screens, named
  workspaces and the keyboard paths (`--focus`), which need input in the VM.
- **The app revamps** (third sitting): not read diff by diff (about 60,000 changed lines,
  51,000 more in Settings). Done instead: each of 27 apps opened tiled at half width
  (840 px) in the dark and the light theme and its first screen looked at
  (`evidence/half/`): all fit, all follow the theme, none is cut off. Read: Mail's
  sorting page, Welcome's single-instance change, Calendar's scrolling, Chat's shell tool,
  Transfer's mirror. Searched across all: newly silenced dead code (one, Calculator),
  icon buttons without names (NYX-A11Y-004). Still not done: clicking through each app,
  dialogs and second-level pages, 960 px and narrower than half, keyboard reach, Orca.
- **Settings' pages, Welcome start to finish, Store install and remove, lock and greeter**:
  not walked (only Settings' Home and Disks were opened).
- **Tests and lints:** `clippy --all-targets` run on clean exports of nyx-installer,
  nyx-system, nyx-archive, nyx-notepad and nyx-cloud: style lints only. `cargo test` not
  rerun: each package's tests run in the Nix build CI does for every pin (green).
  `nix flake check` not run (CI's result used).
- **Browser** beyond the VPN module and packaging; **nyx-biometrics**, **nyx-accounts**,
  **nyx-agents**, **nyx-share** changes; **nyx-tv** beyond its manifest and ignored files.
- **An ISO install**, the BIOS case, real hardware, real accounts.
- Most rows of the first audit's remediation table (see regressions.md).

Uncommitted work in the checkouts was left alone and not audited, except to note the
shared-crate bump lying in about fifty of them (NYX-CI-008).

## Evidence

`evidence/heads.tsv` (repositories), `evidence/smoke-dock/` (report and screenshots;
Passwords' removed, NYX-PRIV-007), `evidence/maps-blank.png`, `evidence/store-home.png`,
`evidence/notes.md` (working notes, including what was checked and found fine).
