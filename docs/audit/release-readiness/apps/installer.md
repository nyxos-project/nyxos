# Nyx Installer scorecard

- **Repository:** nyxos-project/nyx-installer at `1ea97f219d` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** install media only (live USB; not on installed systems)
- **Purpose:** install NyxOS: erase a disk or install beside Windows in free space, LUKS2, Btrfs subvolumes, swap file for hibernation, the machine's flake
- **Stack:** Rust/GTK4 app (`apps/installer`) over a UI-free library (`crates/nyx-install`); runs as root in `cage` (`nyxos/iso/default.nix:84-96`); sgdisk, cryptsetup, mkfs.btrfs, nixos-install
- **Binaries / services:** `nyx-installer` (window) and `nyx-install` (CLI), with util-linux, gptfdisk, dosfstools, btrfs-progs, cryptsetup, parted, systemd, nixos-install-tools, nix on PATH (`nyx-packages/pkgs/nyx-installer.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Both install modes, LUKS2, hibernation, offline sources; the keyboard choice isn't applied while typing passwords |
| UX | 2 | Explicit erase confirmation, Beside Windows chosen by default, failures in plain words with a log |
| Accessibility | 2 | Keyboard navigation (Alt+Left/Right, Ctrl+Enter, focus on first control); no icon-only buttons |
| Reliability | 2 | Every input validated; stops at the first failure and cleans mounts; no rollback of new partitions |
| Integration | 2 | Writes the flake, overrides and hardware layer the System Manager reads; installs from the USB's own sources |
| Packaging | 3 | All tools in `runtimeInputs`; cage session as root with the system's theme |
| Maintainability | 1 | 13 tests, 10-line README, no CI workflow |

## Functionality

- **Plan validation** (`crates/nyx-install/src/plan.rs:134-171`, `check` at `:466-473`): the disk is the plan's and not busy (live system or mounts), login and hostname rules, password without `:` or newline, channel `stable`/`testing` (both exist on GitHub), swap 1-256 GiB, GUIDs, passphrase ≥ 8 characters, kernel parameters and locale/keyboard/time zone limited to safe characters, 32 GB minimum, GPT required beside another system, and the target range inside the disk's free gap. Tests at `plan.rs:596-616`.
- **Destructive-step confirmation.** Erase needs the "I understand — Erase /dev/… and install NyxOS on it" switch on Review, listing every partition that goes (`apps/installer/src/pages.rs:408-431`); Next stays disabled until then (`pages.rs:49`) and turns destructive-styled (`window.rs:101-110`); choosing a disk resets the confirmation and picks Beside Windows when Windows or a 32 GB gap exists (`pages.rs:171-173`). The window can't be closed while installing (`window.rs:216`).
- **Dual-boot safety.** Beside Windows, no Windows partition is named in any step (test `plan.rs:558-578`); NyxOS gets its own EFI partition and `boot.windows` points Limine at Windows' ESP (`plan.rs:397-400`). No BitLocker recovery-key or Secure Boot warning (NYX-APP-INSTALLER-003).
- **LUKS.** `cryptsetup luksFormat --type luks2 --batch-mode --label NyxOS --key-file=-` with the passphrase on stdin (`plan.rs:236-246`); systemd initrd with discards (`plan.rs:392-393`).
- **What it writes** (`plan.rs:267-337`): `/etc/nyxos/flake/flake.nix` (input `github:nyxos-project/nyxos/<channel>`, `nyxos-overrides` from `/etc/nyxos/overrides`, `:349-389`), `host.nix` (stateVersion 26.05, hostname, user, LUKS, Btrfs options, swap and `resume_offset`, snapshots on, `standaloneApps = "per-user"`, `:391-435`), `hardware-configuration.nix` (generated, header rewritten, `run.rs:75-89`), `resume-offset`, `overrides/system.json` (time zone, keyboard, locale, hardware, `:439-448`), a `flake.lock` pinned to the USB's NyxOS (`/etc/nyxos/source`, `choices.rs:205`); then builds the system on the live store, `nixos-install --no-root-passwd`, `nix flake archive` of every source into the new store for offline recovery, `chpasswd` through `nixos-enter`, and copies the log to `/var/log/nyxos-install.log`.
- **Failure mid-install.** Steps stop at the first failure with the step's title and the tool's last line, the tools' output going to `/tmp/nyxos-install.log` (`crates/nyx-install/src/run.rs:1-3,38-58`). "Back to the review" unmounts `/mnt` and closes `cryptroot` (`pages.rs:547-553`). Nothing removes partitions it created (NYX-APP-INSTALLER-002).
- Secrets: passwords go only to stdin and never to the log or the step list (`plan.rs:450-463`, test `:549`).

## UX and accessibility (static)

- Pages: Welcome (language, keyboard, time zone), Disk, You, Review, install, done/failed (`pages.rs:1`). Restart button on success; on failure the log path and Ctrl+Alt+F2 console hint (`pages.rs:517-556`).
- "Keep the computer plugged in" (`pages.rs:456`) but no AC or battery check.

## Reliability

- No `unwrap()`/`expect()` outside tests. Partition numbers are the first two free (`plan.rs:191-196`); `udevadm settle` and `partprobe` before formatting (`plan.rs:232-234`).
- Sizes beside Windows assume 512-byte sectors (`plan.rs:167,211`), though the disk list records `sectorsize` (`disks.rs:170-212`) (NYX-APP-INSTALLER-004).

## Integration and packaging

- No Omarchy references. Pins: nyx-core `4378e24`, nyx-design `40db521`, nyx-system `8e723ee` (Welcome and Store use `8514a6d`; main `6f0c47c`), so the installer writes `system.json` with an older `SystemSettings` than the installed System Manager reads.
- nyxos `modules/nixos/security.nix:1-2` says "Full-disk encryption, TPM2 unlock and Secure Boot come with the installer"; the installer sets up neither TPM2 unlock nor Secure Boot (`nyxos.boot.secureBoot` stays off, `modules/nixos/boot.nix:47-51`).

## Maintenance

- 13 tests (plans, refusals, written files, step runner, wording). README is 10 lines. No `.github/workflows`.

## Runtime results

- Headless install with the same steps fails at step 11 on the 0.1.0 ISO (`/mnt` missing, NYX-INST-001); with `/mnt` created it installs in 112 s and boots (installation.md). GUI pages and the keyboard-layout issue (INSTALLER-001) not exercised.

## Findings

### NYX-APP-INSTALLER-001: The chosen keyboard layout isn't used while typing the password and passphrase, but is used at sign-in

- **Component:** nyx-installer `apps/installer/src/pages.rs:120-124`; nyxos `modules/nixos/desktop.nix:17-22`, `modules/nixos/overrides.nix:124-125`
- **Category:** functionality
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** The Keyboard row only stores the choice ("Also for the disk's passphrase at startup."); nothing applies it to the cage session, so the account password and disk passphrase are typed with cage's default layout (US). The installed greeter runs Hyprland with `kb_layout` set to the chosen layout, so someone who chose, say, German and whose password contains y, z or layout-dependent symbols types different characters at sign-in. At boot the LUKS prompt uses the initrd's keymap; nyxos sets `console.useXkbConfig` but not `console.earlySetup`, so it probably stays US, which contradicts the hint.
- **Expected:** The password is typed in the layout it will be entered with at sign-in, and the passphrase in the boot prompt's layout (installation must not lock the user out).
- **Actual:** no layout code in the installer (`rg -i 'xkb|keymap|setxkbmap' nyx-installer` finds only the dropdown); greeter layout substitution `desktop.nix:18`.
- **Reproduce / verify:** On the VM, install with keyboard "de" and password "yz#1"; try to sign in at the greeter; then reboot and unlock LUKS. Static; confirm at runtime. If confirmed, this is a lockout on a fresh install (P0 class for affected layouts).
- **Evidence:** as above.
- **Affected versions:** `1ea97f219d`
- **User impact:** Non-US users may be unable to sign in or unlock the disk after installing.
- **Recommended correction:** Apply the chosen layout live in cage (`XKB_DEFAULT_LAYOUT` via a restart, or switch through the compositor), show the active layout beside password fields, and set `console.earlySetup = true` in installed systems with LUKS so the boot prompt matches.
- **Effort:** M
- **Dependencies:** NYX-APP-GREETER-002
- **Verification criteria:** With a non-US layout, the password and passphrase typed in the installer work at the greeter and at the LUKS prompt.

### NYX-APP-INSTALLER-002: A failed install beside Windows leaves its partitions behind, and the only remaining choice erases Windows

- **Component:** nyx-installer `apps/installer/src/pages.rs:533-556`, `crates/nyx-install/src/plan.rs:210-231`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** After a failure past "Making NyxOS's partitions", "Back to the review" unmounts and closes but keeps the new EFI and root partitions. The free gap is gone, so Beside Windows is no longer offered; the disk page offers "Erase the disk … Windows too".
- **Expected:** A recovery path that doesn't put the user one click from erasing Windows: remove the partitions this run created (their GUIDs are known), or reuse them on retry.
- **Actual:** no cleanup of partitions; Alongside requires a free gap (`plan.rs:466-473`).
- **Reproduce / verify:** In the VM with a Windows-like layout, make a later step fail (for example a gap just over 32 GB with a large swap file) and press "Back to the review" (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `1ea97f219d`
- **User impact:** The user must delete partitions by hand or risk erasing Windows.
- **Recommended correction:** On failure beside another system, delete the partitions with `efi_guid`/`root_guid` (`sgdisk --delete`) after confirmation, or detect them and offer "Try again in the same space".
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** After a forced failure the free space is back and Beside Windows is offered again.

### NYX-APP-INSTALLER-003: No BitLocker or Secure Boot guidance for dual boot, and docs claim TPM2 and Secure Boot setup the installer doesn't do

- **Component:** nyx-installer `apps/installer/src/pages.rs:219-224`; nyxos `modules/nixos/security.nix:1-2`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Beside BitLocker Windows (detected, `crates/nyx-install/src/disks.rs:31-34`), turning Secure Boot off to boot the USB or adding a boot entry commonly makes Windows ask for its BitLocker recovery key; the installer doesn't say so. It doesn't check the firmware's Secure Boot state, and the installed Limine is signed only when `nyxos.boot.secureBoot` is set.
- **Expected:** A warning to have the BitLocker recovery key before installing beside Windows; docs that match what the installer does.
- **Actual:** no `bitlocker|secure boot|recovery key` text in the installer UI.
- **Reproduce / verify:** Read the Disk page texts; install beside a BitLocker VM image (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `1ea97f219d`
- **User impact:** A Windows user can be locked out of Windows without the key.
- **Recommended correction:** Add the warning when the disk has a BitLocker volume; correct `security.nix`'s comment or implement TPM2/Secure Boot setup.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The warning shows for a BitLocker disk; docs match the installer.

### NYX-APP-INSTALLER-004: Sizes beside another system assume 512-byte sectors

- **Component:** nyx-installer `crates/nyx-install/src/plan.rs:167,211`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `sectors * 512` and `EFI_SIZE / 512` ignore the disk's sector size, which `disks.rs` reads. On a 4Kn disk the EFI partition becomes 8 GiB and the 32 GB check needs 256 GB of free space. The partitions still stay inside the gap.
- **Expected:** Byte sizes from `sectorsize`.
- **Actual:** see Component; `disks.rs:170-212` uses `t.sectorsize`.
- **Reproduce / verify:** A plan test with `sectorsize = 4096`.
- **Evidence:** as above.
- **Affected versions:** `1ea97f219d`
- **User impact:** Wasted space or a refused install on 4Kn drives; no data loss.
- **Recommended correction:** Carry `sectorsize` in `Target::Alongside` or the disk, and compute with it.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A 4Kn test plan gets a 1 GiB EFI partition.
