# Installation, first run, updates and recovery (handoff 10 sections 20, 21)

Tested 2026-11-12 with the ISO built in Phase C (`nyxos-0.1.0-installer.iso`, sha256
`7b5c27e4…`) in a fresh UEFI VM (`nyxos-install-test`, 4 vCPU, 6 GiB, empty 64 GiB disk).
The install used `nyx-install run PLAN.json --yes`, the headless form of the installer:
the same `Plan::steps()` the graphical installer runs, with a plan equivalent to what
the GUI writes (erase disk, LUKS2, keyboard `us`, channel `stable`, the ISO's own NyxOS
source for an offline install, detected hardware). A serial console was added to the
kernel command line so the passphrase prompt could be answered. Evidence:
[evidence/logs/install-*](evidence/logs/), `installed-*.txt`,
[evidence/runtime-notes.md](evidence/runtime-notes.md) ("Install test").

## What happened

| Step | Result | Time |
| --- | --- | --- |
| Live ISO boots to the graphical installer | pass | agent up 14 s after power-on |
| Install (43 steps) | **FAIL at step 11/43**, "Making subvolumes didn't work: mount failed" (`/mnt` doesn't exist) | 12 s |
| Same install after `mkdir /mnt` by hand | pass ("NyxOS is installed") | 112 s, offline |
| First boot: LUKS prompt, unlock | pass | prompt at 7.8 s |
| Boot to login | pass, no failed units | 15.5 s (`systemd-analyze`) |
| Greeter | pass: user card, password field focused, power buttons | |
| Sign in (password typed into the real greeter) | pass: session up 2.0 s later | |
| First run | pass: Welcome opens on its first page (14 steps); bar, dock, all shell services running, no failed user units | ~30 s |
| `nyx update --dry-run` on the fresh install | "Nothing to update"; fwupd not installed | 5 s |
| A system change after the first weekly garbage collection | **FAIL**: path in flake.lock deleted (NYX-INST-002) | |
| Installing two Welcome apps per user (Calendar, Mail) | **FAIL** for the second (NYX-PKG-008, [packaging-ci.md](packaging-ci.md)) | |

Not exercised: the graphical installer's own pages (keyboard layout on password fields:
NYX-APP-INSTALLER-001 stays static), installing beside Windows, Secure Boot, Welcome's
"Review and apply" end to end, Restore from the boot menu's Recovery entry.

## Updates and rollback

- **Rollback works.** `nyx-system rollback` on the dev VM: 245 → 244 in 4 s, history entry
  written; switching forward again took 2 s; the shell stayed up
  ([evidence/logs/rollback.txt](evidence/logs/rollback.txt)).
- **Failed builds are undone.** A System Manager change whose build failed reported "the
  change was undone, so nothing on the system changed", and the time zone stayed as it was
  ([evidence/logs/installed-after-gc-settings.txt](evidence/logs/installed-after-gc-settings.txt)).
- **An interrupted change is not undone** (NYX-REL-002 in [reliability.md](reliability.md)).
- **The channel is behind the release.** The installer writes `nyxos.url =
  "github:nyxos-project/nyxos/stable"`; `stable` (7454358, 2026-11-10) is 40 commits
  behind `v0.1.0`. On the fresh install `nyx update` reported nothing to update, so it does
  not move the system backwards, but apps installed per user come from `stable` and are
  the 2026-11-09 builds, older than the ones built into the system (NYX-CI-003).
- **Firmware:** fwupd is off by default; `nyx update` says so on every run.
- **Development VM:** `nyx update` can't check the system channel there ("this system's
  flake has no nyxos input"), so system updates can only be tested on an installed machine.

## Findings

### NYX-INST-001: The 0.1.0 live USB can't install: `/mnt` doesn't exist

- **Component:** nyxos `iso/live-image.nix`; nyx-installer `crates/nyx-install/src/plan.rs`
- **Category:** functionality
- **Severity:** P0
- **Status of feature:** partial (installer works once `/mnt` exists)
- **Description:** Every install from the current ISO stops at step 11 of 43. The installer mounts the new filesystem at `ROOT = "/mnt"` without creating it, and NyxOS's own live image, which replaced NixOS's installation-CD modules on 2026-11-11 at 22:09 (2e874ed), has no `/mnt` (NixOS's installer image provided it).
- **Expected:** The installer completes on the shipped ISO (handoff 10 section 20; Gate B).
- **Actual:** `mount: /mnt: mount point does not exist` → "Making subvolumes didn't work: mount failed" after 12 s. `ls /` on the live system has no `mnt`. `rg '/mnt' iso/` finds nothing that creates it; `plan.rs:12` defines `ROOT`; no step runs `mkdir -p /mnt`. The `v0.1.0` tag (d632770) contains the new live image.
- **Reproduce / verify:** `nix build .#iso`; `scripts/install-vm create`; in the live system `nyx-install run plan.json --yes` with any erase plan (or use the graphical installer).
- **Evidence:** evidence/logs/install-run.log, install-plan-steps.txt; evidence/runtime-notes.md
- **Affected versions:** nyxos 2e874ed and later (v0.1.0, 97f1573); nyx-installer 1ea97f2
- **User impact:** Nobody can install NyxOS 0.1.0. Disks are partitioned and encrypted before the failure, so the target disk is already erased (for "erase") or has new partitions (for "beside Windows": see NYX-APP-INSTALLER-002).
- **Recommended correction:** Make the installer create its mount point (`std::fs::create_dir_all(ROOT)` before the first mount, or a `mkdir -p /mnt` step), and add `systemd.tmpfiles` or `boot.postBootCommands` for `/mnt` in the live image. Add an automated install test (the headless plan above, in the install VM or a NixOS VM test) to CI so the ISO can't ship untested.
- **Effort:** S (fix); M (automated install test)
- **Dependencies:** NYX-CI-005 (CI doesn't build the ISO)
- **Verification criteria:** A fresh ISO installs end to end with the graphical installer and with `nyx-install run`, and the automated install test passes in CI.

### NYX-INST-002: Installed machines lose the ability to change the system after the first weekly garbage collection

- **Component:** nyx-installer `plan.rs` (flake lock step); nyxos `modules/nixos/base.nix` (`nix.gc`); nyx-system (rebuild path)
- **Category:** reliability
- **Severity:** P1
- **Status of feature:** implemented, verified broken
- **Description:** The installer locks the machine flake with `--override-input nyxos path:/nix/store/…-source` (the ISO's copy of NyxOS), so `flake.lock` pins `nyxos` to that store path (`"type": "path"`, `lastModified: 0`). Nothing keeps that path alive: it isn't a GC root and isn't in the system closure. The weekly `nix-gc.service` (`--delete-older-than 30d`, which collects all dead paths) deletes it, after which every rebuild that needs a fresh evaluation fails.
- **Expected:** Settings, Welcome, Store and Recovery can change the system for the machine's whole life (handoff 08 section 8; handoff 09).
- **Actual:** On the installed VM: `nix-store --gc --print-dead` lists the path; after `systemctl start nix-gc.service` it's gone; `sudo nyx-system set time-zone America/Denver` → "The new system couldn't be built: path '//nix/store/wn5hsy…-source' does not exist; the change was undone". `nyx update --dry-run` and `nyx update check` still say "Everything is up to date", so nothing repairs the lock.
- **Reproduce / verify:** Install; `sudo systemctl start nix-gc.service`; change any system setting in Settings (or `sudo nyx-system set time-zone …`).
- **Evidence:** evidence/logs/installed-flake-source-gc.txt, installed-gc-rebuild*.txt, installed-after-gc-update.txt, installed-after-gc-settings.txt
- **Affected versions:** nyx-installer 1ea97f2; nyxos 97f1573
- **User impact:** Within a week of installing (the timer runs weekly), changing the computer's name, time zone, keyboard, services, system packages, or anything else system-wide fails, and an update doesn't fix it. Data is safe and failed changes are undone.
- **Recommended correction:** After installing, re-lock `nyxos` to the channel's GitHub revision that matches the ISO (or write the lock with the GitHub input and only *substitute* from the ISO), or add the source path as a GC root (`/nix/var/nix/gcroots/nyxos-install-source`) until the first successful update re-locks it. Have `nyx update` treat a `path:` lock as needing an update.
- **Effort:** S
- **Dependencies:** NYX-CI-003 (the channel must point at a revision at least as new as the ISO)
- **Verification criteria:** On a fresh install, run nix-gc, then change the time zone in Settings: it builds and switches.

### NYX-INST-003: The machine's lock records the installer's `/mnt` overrides path

- **Component:** nyx-installer `plan.rs` (`nix flake lock … --override-input nyxos-overrides path:/mnt/etc/nyxos/overrides`)
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** verified
- **Description:** `flake.lock` keeps `nyxos-overrides` as `path:/mnt/etc/nyxos/overrides`; every later rebuild warns "not writing modified lock file … Updated input 'nyxos-overrides' … → 'path:/etc/nyxos/overrides'".
- **Expected:** The lock refers to `/etc/nyxos/overrides`.
- **Actual:** evidence/logs/installed-gc-rebuild.txt (warning text).
- **Reproduce / verify:** `nixos-rebuild build --flake /etc/nyxos/flake#HOST --override-input nyxos-overrides path:/etc/nyxos/overrides` on a fresh install.
- **Evidence:** as above
- **Affected versions:** nyx-installer 1ea97f2
- **User impact:** Noise in every rebuild log; confusing when diagnosing.
- **Recommended correction:** Lock against `path:/etc/nyxos/overrides` (e.g. write the lock inside `nixos-enter`, or rewrite the path afterwards).
- **Effort:** S
- **Dependencies:** NYX-INST-002 (same step)
- **Verification criteria:** No lock warning on the first rebuild after install.
