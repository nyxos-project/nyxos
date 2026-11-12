# Nyx Biometrics scorecard (user-facing side)

- **Repository:** design-nexus/nyx-biometrics at `1fe62af00a` (pinned in nyx-packages: yes, 0 behind origin); lock screen and polkit agent from nyxos-project/nyx-greeter at `6c4cce1692` (pinned: yes)
- **Release tier:** not offered (packaged with a NixOS module; on per machine, e.g. the dev VM; no catalog item). Nyx Locker and Nyx Prompt are base (`nyx.locker`, `nyx.prompt`).
- **Purpose:** face, fingerprint and security-key sign-in under one policy, the `io.github.design_nexus.nyx.Auth` broker for app confirmations, and the TPM key service for Passwords
- **Stack:** Rust (8.9k lines), PAM, fprintd/Irlume/Gaze/pam_u2f; Omarchy-shell QML overlays and an SDDM theme (Arch only, not packaged)
- **Binaries / services:** `nyx-authd` (D-Bus activated), `nyx-authctl`, `lib/nyx-biometrics/{nyx-auth-helper,nyx-auth-gate,nyx-auth-notify,nyx-auth-keyd}`, `nyx-auth-keyd.socket` (system), two polkit policies (`nyx-packages/pkgs/nyx-biometrics.nix`); PAM stacks from `modules/nixos/biometrics.nix`. Locker: `nyx-locker`; prompt: `nyx-prompt` user unit (`default.nix:551-580`).

PAM and broker security are covered by the security audit (SEC findings); this card covers settings, enrolment and the lock/prompt experience.

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Enrolment CLI, broker, locker with parallel methods implemented; no way to turn it on from the desktop |
| UX | 1 | Settings' Sign-in page shows Arch commands and PAM buttons that refuse on NixOS; prompt password waits behind fingerprint |
| Accessibility | 2 | Locker labels the password entry (`apps/locker/src/ui.rs:387`); prompt and Settings rows partly labelled |
| Reliability | 2 | Password always available on every surface; sequential PAM in the prompt; 16 unwrap/expect |
| Integration | 1 | Not in the System Manager or Settings on NyxOS; trusted-bin entry overwritten |
| Packaging | 2 | Thorough module (gate, per-method lock services, assertions); one `/etc` conflict |
| Maintainability | 3 | 114 tests, CI `check.yml`, threat model, recovery, enrolment and hardware docs |

## Functionality

- **Enrolment:** `nyx-authctl face enroll|manage`, `finger enroll`, `keys add NAME --pin`, `ssh-key create` run in a terminal from Settings (`nyx-settings/apps/settings/src/sections/sign_in.rs:199-343`). On NixOS, `pam apply/restore/preview` and `helper install` refuse with an explanation (`crates/nyx-authctl/src/pam.rs:93,224,292,308-314`; `enroll.rs:230-231`; helper `main.rs:61-63`).
- **Turning it on:** only `nyx.biometrics.*` in the NixOS configuration (`modules/nixos/biometrics.nix:169-222`); nyx-system has no biometrics option; only `hosts/incus-dev` sets it. The Settings page appears only when `nyx-authctl` exists (`sign_in.rs:16-18`). The release inventory's "set in Settings" is inaccurate.
- **Password fallback:** login/sudo/polkit add each method as `sufficient` ahead of `pam_unix`, which stays (`biometrics.nix:115-160`); the gate skips biometrics for remote sessions, inactive seats and a closed lid. The locker runs each method as its own PAM service alongside `nyx-lock-password`; "the password is always there" (`nyx-greeter/crates/nyx-lock-core/src/lib.rs:49`), behind "Use password" or the first key typed (`apps/locker/src/ui.rs:396-408`).
- **Prompt:** Nyx Prompt shows PAM info text ("Place your finger…") and enables the password entry when PAM asks for it (`nyx-greeter/apps/prompt/src/dialog.rs:135-156`, `helper.rs:32`).

## UX and accessibility (static)

Locker: ring, name, status, password with accessible label; fingerprint retries then the password. Prompt: one card, Cancel/Continue. Settings Sign-in: device status, methods, where each signs you in, but with Arch actions (NYX-APP-BIOMETRICS-001).

## Reliability

Broker D-Bus activated; key service socket-activated. `pam_fprintd` uses `max-tries=2 timeout=30` (`biometrics.nix:94-100`); on sequential stacks (sudo, polkit) the password prompt comes only after the module gives up (NYX-APP-BIOMETRICS-002).

## Integration and packaging

No desktop entry (by design). Omarchy references (96) are the Arch PAM generator, Omarchy FIDO2 import, SDDM theme and shell overlays; none run on NyxOS except wording such as `login-theme` status ("Omarchy's login screen", `nyx-authctl/src/main.rs:250`). `biometrics.nix:276` sets `environment.etc."nyx/trusted-bin"`, but the main module's activation script replaces `/etc/nyx/trusted-bin` with a file built from `trusted-bin.system`, dropping that line (`default.nix:265-283`) (NYX-APP-BIOMETRICS-004).

## Maintenance

114 tests; CI `check.yml`; nyx-greeter 18 tests. Pins nyx-core `4f05fb8`. Docs complete (ARCHITECTURE, THREAT_MODEL, RECOVERY, ENROLLMENT, HARDWARE, STATUS); README still "for Omarchy".

## Runtime results

- Lock screen: face first with 'Use password'; locker crash → hyprlock takes over → locker restarted; session stayed locked (logs/lock-crash.txt). Face/fingerprint gates fail in the VM (no hardware) and the password works. NYX-SEC-002 key-service spoof confirmed.

## Findings

### NYX-APP-BIOMETRICS-001: Settings' Sign-in page offers Arch-only actions on NyxOS

- **Component:** nyx-settings `apps/settings/src/sections/sign_in.rs:130,159,215,247,413`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Buttons open terminals running `nyx-authctl pam restore`, `sudo nyx-authctl helper install`, `yay -S <backend>`, `sudo pacman -S --needed fprintd libfprint` and `nyx-authctl pam apply <surface>`; on NixOS these refuse or don't exist.
- **Expected:** On NyxOS the page shows what the system configuration enables and changes surfaces through the System Manager (H09 Settings and defaults).
- **Actual:** No platform branch in `sign_in.rs`; authctl prints "set in the system configuration… nixos-rebuild".
- **Reproduce / verify:** On the dev VM (biometrics on), open Settings › Sign-in & Security and press Apply on a surface. Static; confirm at runtime.
- **Evidence:** as above; `nyx-biometrics/crates/nyx-authctl/src/pam.rs:308-314`
- **Affected versions:** nyx-settings `7e76622f35`, nyx-biometrics `1fe62af00a`
- **User impact:** Dead-end buttons and package-manager commands that don't exist on NyxOS.
- **Recommended correction:** NyxOS branch: hide install/apply/restore, show configured surfaces read-only or write them via the System Manager.
- **Effort:** M
- **Dependencies:** NYX-APP-BIOMETRICS-003
- **Verification criteria:** No pacman/yay/apply actions on NyxOS; surface changes go through the System Manager.

### NYX-APP-BIOMETRICS-002: Admin prompt and sudo make the password wait behind a fingerprint/face attempt

- **Component:** `nyx-packages/modules/nixos/biometrics.nix:94-160`; nyx-greeter `apps/prompt/src/dialog.rs:135-156`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** On `sudo`/`polkit` surfaces the methods run in order before `pam_unix`; Nyx Prompt enables the entry only when PAM requests the password, so with a reader present the user waits up to the fprintd timeout (30 s) unless they scan.
- **Expected:** Password usable at once, as in the locker ("Use password").
- **Actual:** No skip control in the prompt. Static; confirm at runtime.
- **Reproduce / verify:** VM with `surfaces.polkit = [ "fingerprint" ]` and a virtual reader; trigger a polkit action and try typing.
- **Evidence:** as above
- **Affected versions:** nyx-greeter `6c4cce1692`, nyx-packages `d69e87e`
- **User impact:** Slow or confusing admin prompts for people who'd rather type.
- **Recommended correction:** Let the prompt cancel the biometric step (restart the conversation password-first) or run methods in parallel as the locker does.
- **Effort:** M
- **Dependencies:** SEC review of the PAM stack
- **Verification criteria:** Password accepted within a second of the prompt appearing with a reader attached.

### NYX-APP-BIOMETRICS-003: No desktop path to turn biometrics on

- **Component:** nyx-system (no biometrics option), nyx-settings `sections/sign_in.rs:16-18`
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** approved, not implemented
- **Description:** `nyx.biometrics` can be set only in the NixOS configuration; the Settings page is hidden until the package is installed.
- **Expected:** Release inventory says "set in Settings".
- **Actual:** Only `hosts/incus-dev/default.nix:63` sets it.
- **Reproduce / verify:** `rg -i biometric nyx-system`.
- **Evidence:** as above
- **Affected versions:** nyx-system and nyx-settings at audit time
- **User impact:** Feature not offered (not a blocker); docs overstate it.
- **Recommended correction:** System Manager settings for `nyx.biometrics.*`, or correct the inventory.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** A user can enable fingerprint sign-in from Settings with one rebuild.

### NYX-APP-BIOMETRICS-004: Biometrics' trusted-bin line is overwritten by the main module

- **Component:** `nyx-packages/modules/nixos/biometrics.nix:276`, `modules/nixos/default.nix:265-283`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `environment.etc."nyx/trusted-bin"` (symlink) is replaced after `etc` activation by a regular file from `trusted-bin.system` plus profile apps, which doesn't include `${bio}/bin`.
- **Expected:** One source for `/etc/nyx/trusted-bin` that includes every contributor.
- **Actual:** As cited; impact depends on whether the broker needs to trust `nyx-authctl`. Static; confirm at runtime.
- **Reproduce / verify:** On the VM, `cat /etc/nyx/trusted-bin | grep nyx-biometrics`.
- **Evidence:** as above; `nyx-biometrics/crates/nyx-auth-core/src/system.rs:34-42`
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** Possible refused calls from Biometrics' own tools; NixOS etc warnings.
- **Recommended correction:** Add `bio` to `enabledPackages`/`trusted-bin.system` instead of defining the file.
- **Effort:** S
- **Dependencies:** SEC findings on trusted-bin
- **Verification criteria:** `/etc/nyx/trusted-bin` lists the biometrics bin folder after a switch.
