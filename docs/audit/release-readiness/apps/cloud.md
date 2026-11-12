# Nyx Cloud scorecard

- **Repository:** design-nexus/nyx-cloud at `ba6385f605` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** store (`catalog.toml:477-482`; per-user install)
- **Purpose:** headless rclone storage service: cloud accounts mounted in the home folder for Files, Settings and Notes
- **Stack:** Rust (1.9k lines), glib, rclone + FUSE3; D-Bus `io.github.design_nexus.nyx.Cloud1`; private setup/Notes Unix sockets
- **Binaries / services:** `nyx-cloudd` (Type=dbus, autostart `default.target`, `UMask=0077`), wrapped with rclone on PATH so `fusermount3` stays the setuid wrapper; D-Bus activation; `nyx-cloud` client library (`nyx-packages/pkgs/nyx-cloud.nix`). No window; Settings › Cloud Storage manages accounts.

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Discover/adopt/setup/mount/reauth/Notes sessions implemented; quota, sharing, pinning, cache clearing not (README) |
| UX | 2 | Lives in Settings and Files; no own entry, which the Store item doesn't explain |
| Accessibility | n/v | No UI in this repository |
| Reliability | 3 | Disconnect refuses pending uploads, bounded reconnect, auth errors wait for the user; 1 unwrap |
| Integration | 2 | Online Accounts link, Files, Notes; per-user D-Bus activation unverified |
| Packaging | 3 | Correct FUSE wrapper handling, units and D-Bus file |
| Maintainability | 2 | 2 Rust tests; Python integration test outside CI; CI only builds |

## Functionality

- **rclone config:** new accounts in `$XDG_CONFIG_HOME/nyx/cloud/rclone.conf` (0600); existing remotes discovered without modification; adoption adds only mount preferences; managed reauth staged and tested before replacing credentials (README "Storage and ownership").
- **Credential storage:** rclone-obscured passwords (reversible) and OAuth tokens in that file; no Secret Service or encrypted config (README "Security and limitations") (NYX-APP-CLOUD-001). D-Bus never returns secrets; setup credentials travel over a private socket.
- **Mounts:** `~/<Account Name>`, never over a non-empty folder; per-account VFS cache 2 GiB target.
- No TODO markers.

## UX and accessibility (static)

Not applicable in this repository; see the Settings and Files scorecards.

## Reliability

`Restart=on-failure`, `RestartSec=10`, `TimeoutStopSec=30`; periodic probes of mounted accounts; cache preserved across shutdown.

## Integration and packaging

No desktop entry (headless). Store installs it per user (`catalog.toml:11-15`); the module's generator links its units and autostart (`modules/nixos/default.nix:84-127`); since it autostarts at `default.target`, D-Bus activation from the profile matters only after a crash (confirm at runtime). No Omarchy references.

## Maintenance

2 Rust tests; `build.yml` runs `cargo build` only; `tests/integration.py` needs FUSE and a session bus. Pins nyx-accounts `afdc148` (origin `e0df68a`).

## Runtime results

- nyx-cloudd listens on 127.0.0.1:35951 (logs/runtime-listening.txt).

## Findings

### NYX-APP-CLOUD-001: Cloud credentials stored reversibly in rclone.conf

- **Component:** nyx-cloud `README.md` ("Security and limitations"), `src/main.rs`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Managed accounts keep obscured passwords and OAuth refresh tokens in a 0600 file; obscuring is reversible, and the config isn't encrypted.
- **Expected:** Credentials in the Secret Service, as Online Accounts and Transfer do (H06/H09 credential handling).
- **Actual:** Documented limitation; any same-user process can read the tokens.
- **Reproduce / verify:** Add a WebDAV/Drive account; inspect `~/.config/nyx/cloud/rclone.conf`.
- **Evidence:** README; `nyx-transfer/crates/transfer-storage/src/lib.rs:132` for contrast
- **Affected versions:** `ba6385f605`
- **User impact:** Token theft by any malicious user-level process or a leaked backup of `~/.config`.
- **Recommended correction:** rclone encrypted config with the password in the Secret Service, or pass tokens via environment from the keyring at mount time.
- **Effort:** M
- **Dependencies:** Security audit (SEC) for the suite's same-user threat model
- **Verification criteria:** No usable token or password in plain files.

### NYX-APP-CLOUD-002: Store item has no visible app, and tests barely run

- **Component:** nyx-system `catalog.toml:477-482`; nyx-cloud `.github/workflows/build.yml`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** "Nyx Cloud: Your cloud storage in Files" installs a service only; users must find Settings › Cloud Storage. CI doesn't run tests; the Nix build runs 2.
- **Expected:** Store text points to Settings; CI runs the integration test.
- **Actual:** As cited.
- **Reproduce / verify:** Install from the Store; look for Cloud in the launcher.
- **Evidence:** as above
- **Affected versions:** `ba6385f605`
- **User impact:** "Installed, now what?"; untested mount paths.
- **Recommended correction:** Add "Set up in Settings › Cloud Storage" to the item note; run `tests/integration.py` in CI.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Store note present; CI runs integration test.
