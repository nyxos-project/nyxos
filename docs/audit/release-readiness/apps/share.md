# Nyx Share scorecard

- **Repository:** design-nexus/nyx-share at `148dc74178` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** base (`nyx.share.enable`)
- **Purpose:** Share Sheet, D-Bus service and CLI: nearby sharing (LocalSend protocol), linked phones (Flux), Bluetooth, NAS folders, clipboard, apps
- **Stack:** Rust/GTK4 sheet; `nyx-share-daemon` (zbus, D-Bus `io.github.design_nexus.nyx.Share1`, LocalSend HTTPS receiver on TCP 53317); wl-clipboard, libsecret, zbar
- **Binaries / services:** `nyx-share-sheet`, `nyx-share-daemon`, `nyx-share` CLI; user unit `nyx-share.service` (D-Bus activated, no autostart) and activation file (`nyx-packages/pkgs/nyx-share.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Sending, offers, trust, NAS and clipboard implemented; receiving from nearby devices blocked by NyxOS's firewall; extensions off on NixOS |
| UX | 2 | Every unverified offer asks first, with a deadline; visibility tied to the service's lifetime is documented |
| Accessibility | 2 | No icon-only button constructors; 11 tooltips |
| Reliability | 2 | Idle exit only when nothing is pending; `Restart=on-failure`; `expect`s on piped handles and validated indices |
| Integration | 2 | D-Bus activation, Files provider, Flux, Settings › Sharing; no firewall integration on NyxOS |
| Packaging | 2 | Unit and activation file rewritten to the store; bubblewrap deliberately left off PATH |
| Maintainability | 2 | 75 tests; 13 crates; docs for protocol, providers and NAS; no CI workflow |

## Functionality

- Receiving: `crates/nyx-share-localsend/src/receiver.rs:1-2` ("Every offer is put to the person at this computer first"), binding `0.0.0.0:53317` or a random port (`receiver.rs:93-95`, `lib.rs:26`).
- Trust: a verified, trusted computer is received from without asking; everyone else gets a Pending answer and a Share Sheet prompt with a deadline (`apps/daemon/src/nearby.rs:243-285`). Received files go to `XDG_DOWNLOAD_DIR` or `~/Downloads` unless a receive folder is set (`nearby.rs:114-126`).
- The service lives while used and for a minute after (`apps/daemon/src/main.rs:2,22,57-63`); `busy()` keeps it while calls, offers, jobs or holders exist (`state.rs:213-220`). The README says the computer is visible only while the service runs (`README.md:28-31`).
- Extensions can't run on NixOS: their bubblewrap sandbox binds `/usr` and sets `PATH=/usr/bin` (`crates/nyx-share-external/src/lib.rs:196`; `pkgs/nyx-share.nix:2-3`).
- No TODO/`unimplemented!` markers; one "not yet" is a comment (`nyx-share-external/src/lib.rs:307`).

## UX and accessibility (static)

- Launcher entry "Share" (`data/desktop/io.github.design_nexus.nyx.Share.desktop`, GenericName "Nearby Sharing"); offers ask in a dialog; transfers continue after the sheet closes (README).
- One hard-coded colour; the app icon SVG is fixed-colour (`data/icons/io.github.design_nexus.nyx.Share.svg`).

## Reliability

- 4 `unwrap()` and 15 `expect()` outside tests: piped child handles (`nyx-share-external/src/lib.rs:331-332`, `nyx-share-localsend/src/tailnet.rs:62`), paths with parents (`apps/daemon/src/config.rs:28`, `nearby.rs:72,217`), and a channel result (`apps/daemon/src/service.rs:82`).
- Unit: `Type=dbus`, `Restart=on-failure`, `RestartSec=2`, `TimeoutStopSec=30` (`data/systemd/nyx-share.service`).

## Integration and packaging

- No Omarchy references in code (1 in a comment).
- NyxOS turns the firewall on (`nyxos/modules/nixos/network.nix:6`); nyx-packages opens only Flux's 12100 (`modules/nixos/default.nix:367-369`). Nothing opens LocalSend's 53317 (TCP for transfers, UDP for multicast discovery). See NYX-APP-SHARE-001.
- Pins: nyx-core `4f05fb8` (main `9187295`), nyx-design `cf39397` (main `e311c2f`).

## Maintenance

- 75 tests; `docs/` (LOCALSEND, PROVIDERS, NAS). No `.github/workflows`.

## Runtime results

- Smoke test (Share): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Firewall on the dev VM and the installed system accepts only 22 (dev VM), 12100, 5353 and ICMP: 53317 closed, confirming SHARE-001's premise (logs/runtime-security-probes.txt, installed-state.txt).

## Findings

### NYX-APP-SHARE-001: NyxOS's firewall blocks nearby sharing's port, so phones and computers can't send to NyxOS

- **Component:** nyx-share `crates/nyx-share-localsend/src/receiver.rs:93-95`, `lib.rs:26`; nyxos `modules/nixos/network.nix:6`; nyx-packages `modules/nixos/default.nix:362-372`
- **Category:** functionality
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** The receiver listens on TCP 53317 and discovery uses UDP 53317 multicast, but NyxOS enables the NixOS firewall and nothing opens 53317 (only Flux's 12100). Incoming offers and multicast announcements from other devices are dropped.
- **Expected:** "Send files, text and links to nearby phones and computers" (desktop entry) works both ways on a default install while Share is visible.
- **Actual:** No `53317` or `allowedTCPPorts` for Share in nyxos or nyx-packages; Share has no firewall code (`rg -i firewall nyx-share` finds nothing).
- **Reproduce / verify:** On the NyxOS VM, open Share, then send from LocalSend on another device on the LAN; `nft list ruleset | grep 53317`. Static; confirm at runtime.
- **Evidence:** source references above.
- **Affected versions:** `148dc74178`, nyxos at audit time
- **User impact:** Receiving from phones (Share's headline feature) fails silently; other devices may not see this computer.
- **Recommended correction:** In nyx-packages' `share` module open TCP and UDP 53317 (optionally only while visible, through nftables sets), or make Settings › Sharing ask the System Manager to open them.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A phone running LocalSend sees the NyxOS VM and its offer reaches the Share Sheet.

### NYX-APP-SHARE-002: Share extensions are unavailable on NyxOS

- **Component:** nyx-share `crates/nyx-share-external/src/lib.rs:196`
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** approved, not implemented
- **Description:** The extension sandbox binds `/usr` and sets `PATH=/usr/bin`, which hold nothing on NixOS, so the package leaves bwrap off PATH and extensions never load.
- **Expected:** Extensions documented in `docs/PROVIDERS.md` work, or the UI says they aren't available on NyxOS.
- **Actual:** see Component; `pkgs/nyx-share.nix:2-3`.
- **Reproduce / verify:** Install a provider extension on NyxOS (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `148dc74178`
- **User impact:** Third-party share targets don't appear.
- **Recommended correction:** Bind `/nix/store` and `/run/current-system/sw` as Glimpse's plugin sandbox does (`nyx-glimpse/apps/glimpse/src/plugins.rs:356-363`).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** An example extension shows in the Share Sheet on NyxOS.
