# Nyx Backup scorecard

- **Repository:** design-nexus/nyx-backup at `7ac27aece9` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** base (`nyx.backup.enable`)
- **Purpose:** encrypted Restic backups of selected user data, selective restore with rollback, user migration, offline disk recovery
- **Stack:** Rust/GTK4 app; headless `nyx-backupd` (D-Bus `io.github.design_nexus.nyx.Backup1`, private Unix socket for privileged operations); Restic, Rclone, libsecret (Secret Service)
- **Binaries / services:** `nyx-backup`, `nyx-backupd`, `nyx-backupctl`, `nyx-backup-recovery`, `nyx-backup-setup` (workspace build); user unit `nyx-backup.service` (autostart `default.target`), D-Bus activation file (`nyx-packages/pkgs/nyx-backup.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Backup, verify, selective restore with preview, receipts and rollback, password export; recovery kit and migration don't work on NyxOS |
| UX | 2 | Review sheets, explicit approvals and confirmations; offers a recovery feature that fails on NyxOS |
| Accessibility | 2 | 13 tooltips for 4 icon-button sites; mostly labelled buttons |
| Reliability | 1 | Schedules write the Nix store path of `nyx-backupctl` into `~/.config/systemd/user`; they break after an update plus garbage collection |
| Integration | 2 | D-Bus activated service, Secret Service, notifications; integration API rejects restore and deletion by design |
| Packaging | 2 | Units rewritten to the store path; recovery-kit tools and their dependencies not packaged |
| Maintainability | 2 | 38 Rust tests run in the Nix build; restore and service smoke scripts are manual; no CI workflow |

## Functionality

- **Encryption.** Restic repositories (always encrypted); the repository password comes from the Secret Service through a `--password-command` helper (`crates/backup-engine/src/lib.rs:307-340`), never in TOML or job state (`docs/QUALIFICATION.md`, 2026-11-02 smoke results). "Export recovery password…" writes it to a file the user keeps elsewhere (`apps/backup/src/destinations.rs:75,477-503`).
- **Integrity verification.** `verify` runs `restic check`, `verify-full` adds `--read-data` (`backup-engine/src/lib.rs:596-597`).
- **Restore path.** Snapshot browsing, staged preview without writes, skip/keep-both/replace, Quick Dotfiles Restore, receipts and rollback, run through the daemon's private socket (`crates/backup-restore/src/lib.rs`, `fs_safe.rs`; `docs/RESTORE.md`). The D-Bus integration API refuses restore (`docs/QUALIFICATION.md`, Phase 2). Ownership, ACLs, xattrs and hard links aren't restored (same).
- **Has restore been tested?** Yes on the developer's Arch machine: 12 `#[test]`s in `backup-restore` (run by the Nix build, `cargoTestFlags --workspace`) and `tools/restore-smoke.py` / `tools/sftp-smoke.py` against real Restic (recorded 2026-11-02 in `docs/QUALIFICATION.md`). No record of a restore on NyxOS, and the smoke scripts aren't automated.
- **Scheduling.** `backup_system::schedule` writes `nyx-backup-<id>.service` with `ExecStart="<current_exe dir>/nyx-backupctl" backup <id> --wait` and a timer into `~/.config/systemd/user`, then enables it (`crates/backup-system/src/lib.rs:500-555`). Units are rewritten only when a schedule is turned on or a scheduled profile is edited (`apps/backup/src/backups.rs:964,1334`). See NYX-APP-BACKUP-001.
- **Not on NyxOS.** Offline disk recovery: "Create boot kit…" runs `~/.local/share/nyx-backup/tools/build-recovery.py` (`apps/backup/src/recovery_ui.rs:31-36`), which the package doesn't install and which needs mkinitcpio (`pkgs/nyx-backup.nix:1-4`); `nyx-backup-recovery` runs `/usr/bin/restic` (`crates/backup-recovery/src/main.rs:305`). Migration reads packages with `pacman` (`crates/backup-system/src/migration_inventory.rs:100-129`) and only hands off between Arch/Omarchy (`crates/backup-migrate/src/lib.rs:216-226`).
- Persistence: profiles and job state under nyx-core's config/state folders; Restic cache under the store's cache (`backup-engine/src/lib.rs:324`).

## UX and accessibility (static)

- Destructive actions (retention deletion, restore replace) need explicit confirmation in the daemon (`docs/QUALIFICATION.md`, Phase 1 completion).
- No hard-coded colours. Curated config sources include "Hyprland, Omarchy, Nyx and terminal settings" (`apps/backup/src/backups.rs:1359`).

## Reliability

- 23 `unwrap()` outside tests, 10 of them in `apps/backup/src/ui_review.rs` (a review fixture view); service code has three (`backup-service/src/daemon.rs:527`, `cli.rs:676,877`).
- The service unit: `Type=dbus`, `UMask=0077`, `NoNewPrivileges=true`, `TimeoutStopSec=15`, no `Restart=` (D-Bus activation starts it again) (`data/nyx-backup.service`).
- Failure notifications come from `nyx-backupctl` itself (`backup-system/src/lib.rs:575-589`), so a timer whose program is missing never notifies.

## Integration and packaging

- `@BIN@` in the unit and D-Bus file is replaced with the store path (`nyx-packages/lib/default.nix:118-129`). Two tests skipped because the sandbox lacks host mounts (`pkgs/nyx-backup.nix:28-31`).
- Pins: nyx-core and nyx-sync `4f05fb8` (main `9187295`), nyx-design `cf39397`.

## Maintenance

- 38 tests (backup-engine 11, backup-restore 12, others 1-4). Nine documents in `docs/` (architecture, security review, restore, recovery, qualification). No `.github/workflows`.

## Runtime results

- Smoke test (Backup): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- CLI backup to a local repository, full verify (0 errors) and restore to a separate folder: byte-identical (logs/backup-restore*.txt). `schedule --enable` writes a timer whose ExecStart is a /nix/store path (BACKUP-001 premise confirmed).

## Findings

### NYX-APP-BACKUP-001: Scheduled backups stop silently after an update and garbage collection

- **Component:** nyx-backup `crates/backup-system/src/lib.rs:500-555`
- **Category:** reliability
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** The schedule's service unit names `nyx-backupctl` by the running binary's directory, which on NyxOS is `/nix/store/…-nyx-backup-…/bin`. User units in `~/.config/systemd/user` don't keep that path alive. After Backup is updated, NyxOS's weekly garbage collection (`--delete-older-than 30d`) removes the old path and the timer starts a unit whose program doesn't exist. The program that would report the failure is the one missing.
- **Expected:** Scheduled backups keep running across updates (data integrity), or fail loudly.
- **Actual:** `lib.rs:522` (`std::env::current_exe()?.with_file_name("nyx-backupctl")`), `:530-537` (ExecStart); rewritten only at `apps/backup/src/backups.rs:964,1334`; GC in nyxos `modules/nixos/base.nix:25-27`; notification only from backupctl (`lib.rs:575-589`).
- **Reproduce / verify:** On the NyxOS VM, enable a schedule, update nyx-backup, run `nix-collect-garbage --delete-older-than 0d`, then `systemctl --user start nyx-backup-<id>.service` (expect status 203/EXEC). Static; confirm at runtime.
- **Evidence:** source references above.
- **Affected versions:** `7ac27aece9`
- **User impact:** Backups the person believes are running stop without a message; found out only at restore time.
- **Recommended correction:** Write `ExecStart=nyx-backupctl …` resolved through the profile (`/run/current-system/sw/bin/nyx-backupctl` or `/etc/profiles/per-user/%u/bin`), or ship a templated `nyx-backup@.service` in the package and only write timers; have `nyx-backupd` rewrite existing units when it starts, and alert on schedules with no recent success.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** After update and GC, the timer's next run succeeds; a stale unit is detected and repaired at service start.

### NYX-APP-BACKUP-002: Offline disk recovery is offered on NyxOS but can't work there

- **Component:** nyx-backup `apps/backup/src/recovery_ui.rs:22-50`, `crates/backup-recovery/src/main.rs:305`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Restore › Offline disk recovery › Create boot kit runs a Python builder from `~/.local/share/nyx-backup/tools` that the package doesn't install and that needs mkinitcpio; the recovery helper itself runs `/usr/bin/restic`, which NixOS doesn't have.
- **Expected:** Features that can't work on NyxOS are hidden there, or ported (package comment `pkgs/nyx-backup.nix:1-4` says only the restore side applies).
- **Actual:** the entry is shown unconditionally (`apps/backup/src/restore_ui.rs:213`); the restore side also hard-codes `/usr/bin/restic`.
- **Reproduce / verify:** On NyxOS, open the sheet and press Create boot kit (expect "No such file"); run `nyx-backup-recovery` against a repository (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `7ac27aece9`
- **User impact:** A recovery feature that fails when tried; whole-disk recovery isn't available on NyxOS (NyxOS Recovery and snapshots are the system's path).
- **Recommended correction:** Hide the sheet on NixOS; find `restic` on PATH in `backup-recovery`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** NyxOS shows no boot-kit entry; `nyx-backup-recovery` runs Restic from PATH.

### NYX-APP-BACKUP-003: Restore and scheduling were never qualified on NyxOS, and the smoke tests are manual

- **Component:** nyx-backup `tools/*.py`, `docs/QUALIFICATION.md`
- **Category:** CI
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The end-to-end evidence (real Restic backup, restore, rollback, D-Bus activation, timers) was recorded on Arch on 2026-11-02 with scripts nobody runs automatically; there's no CI workflow, and none of it was repeated on NyxOS.
- **Expected:** A base backup app has a restore test on the target system before release.
- **Actual:** `.github/workflows` absent; QUALIFICATION.md has no NyxOS run.
- **Reproduce / verify:** Run `tools/restore-smoke.py` and `tools/service-smoke.py` in the NyxOS VM.
- **Evidence:** as above.
- **Affected versions:** `7ac27aece9`
- **User impact:** Unknown whether restore works on NyxOS.
- **Recommended correction:** Run the smoke scripts in the VM in Phase F and in CI.
- **Effort:** M
- **Dependencies:** NYX-APP-BACKUP-001
- **Verification criteria:** A recorded NyxOS restore and scheduled-run pass.

### NYX-APP-BACKUP-004: User migration only works between Arch/Omarchy machines

- **Component:** nyx-backup `crates/backup-system/src/migration_inventory.rs:100-129`, `crates/backup-migrate/src/lib.rs:216-226,600`
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Package inventory uses `pacman`; handoff requires both systems to be Arch/Omarchy and installs with `pacman -S`.
- **Expected:** Migration to NyxOS maps packages to the catalog, or says it's unsupported.
- **Actual:** inventory reports "unavailable", handoff falls to "review_platform".
- **Reproduce / verify:** Prepare a migration on NyxOS (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `7ac27aece9`
- **User impact:** File migration works; software must be reinstalled by hand.
- **Recommended correction:** Hide package handoff on NixOS until it maps to the catalog.
- **Effort:** M
- **Dependencies:** nyx-catalog
- **Verification criteria:** NyxOS migration review states the package step is manual.
