# Nyx Transfer scorecard

- **Repository:** design-nexus/nyx-transfer at `8f55e6ae2c` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** store (`catalog.toml:469-474`; per-user install)
- **Purpose:** two-pane file transfer between local, SFTP, FTP, FTPS and WebDAV (and imported rclone remotes), with background jobs and sync workflows
- **Stack:** Rust/GTK4 (6.3k lines), rclone subprocess, SQLite, Secret Service; D-Bus `io.github.design_nexus.nyx.Transfer1`
- **Binaries / services:** `nyx-transfer` (app), `nyx-transferd` (Type=dbus, autostart `default.target`, `UMask=0077`); D-Bus activation; runtime rclone and openssh (`nyx-packages/pkgs/nyx-transfer.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Browse/copy/sync/bisync implemented; FTPS not checked end to end (README) |
| UX | 2 | Tabs, history, breadcrumbs, drag and drop, queue with ETA |
| Accessibility | 2 | 27 tooltips for 26 icon buttons (`apps/nyx-transfer/src/main.rs:183-197`); no accessible properties |
| Reliability | 3 | Jobs persisted, interrupted jobs marked failed for safe retry, targets protected; 5 unwrap/expect |
| Integration | 2 | D-Bus service; no actions manifest, Glimpse or Share; catalog text wrong |
| Packaging | 2 | Workspace build, rclone tests serialised; no LICENSE file |
| Maintainability | 2 | 9 Rust tests plus Python service test; `main.rs` 2.5k lines; release workflow only |

## Functionality

- **rclone config:** Transfer's own connections pass settings as `RCLONE_CONFIG_<name>_*` environment variables; imported remotes keep their original config path, which rclone manages (`crates/transfer-rclone/src/lib.rs:42,492-531`, README).
- **Credentials:** passwords saved in the Secret Service (`crates/transfer-storage/src/lib.rs:132-143`) and handed to rclone obscured via environment (`transfer-rclone/src/lib.rs:597-623`), not on the command line. Every NyxOS install has gnome-keyring through `nyx.accounts` (`modules/nixos/default.nix:677-682`).
- **Safety:** SFTP requires a trusted host key; FTP/HTTP WebDAV need an explicit plaintext choice; FTPS validates certificates (README).
- **Persistence:** jobs and history in SQLite; queued jobs resume with the service.

## UX and accessibility (static)

Icon buttons labelled with tooltips; no hard-coded colours.

## Reliability

Service restarts on failure (`RestartSec=5`); workflows abort when the previewed state changes.

## Integration and packaging

Desktop entry and icon (`data/`). No Omarchy references. Catalog calls it "Send files between your devices" (`catalog.toml:471`), which describes Share/Connect, not this app. No LICENSE in the repository (nyx-packages declares MIT by default, `lib/default.nix:189`).

## Maintenance

9 tests; `release.yml` only. Pins nyx-core `4f05fb8`, nyx-design `cf39397`. Docs: ARCHITECTURE, BACKENDS, ROADMAP.

## Runtime results

- Smoke test (Transfer): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-TRANSFER-001: Store description misstates the app

- **Component:** nyx-system `crates/nyx-catalog/catalog.toml:469-474`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** "Send files between your devices" suggests phone/device sharing; Transfer is an SFTP/FTP/WebDAV client.
- **Expected:** Summary matching `nyx-transfer.nix` meta ("Copy files between local, SFTP, FTP, FTPS and WebDAV locations").
- **Actual:** As cited.
- **Reproduce / verify:** Search the Store for Transfer.
- **Evidence:** as above
- **Affected versions:** nyx-system catalog at audit time
- **User impact:** Wrong app installed for device sharing.
- **Recommended correction:** "Copy files to and from servers (SFTP, FTP, WebDAV)."
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Catalog text updated.

### NYX-APP-TRANSFER-002: No LICENSE file and no CI test run

- **Component:** nyx-transfer (repository)
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Repository lacks a LICENSE while the package declares MIT; only a release workflow exists.
- **Expected:** LICENSE like peer repos; `check.yml`.
- **Actual:** inventory `has_license: false`, `workflows: ["release.yml"]`.
- **Reproduce / verify:** `ls nyx-transfer`.
- **Evidence:** `evidence/inventory.json`
- **Affected versions:** `8f55e6ae2c`
- **User impact:** Licensing ambiguity for redistribution.
- **Recommended correction:** Add LICENSE; add CI.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** LICENSE present; CI runs tests.
