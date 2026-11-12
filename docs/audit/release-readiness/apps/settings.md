# Nyx Settings scorecard

- **Repository:** design-nexus/nyx-settings at `7e76622f35` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** base (`nyx.settings.enable` in nyxos `modules/nixos/apps.nix`)
- **Purpose:** system and desktop settings; on NyxOS every system change goes through the Nyx System Manager
- **Stack:** Rust/GTK4 (nyx-design `nyx-ui`), built with the `nyxos` feature; printers through cups-pk-helper (D-Bus); 1 QML file
- **Binaries / services:** `nyx-settings` (the `nyx-settings-helper` root helper is deleted in `postInstall`), action manifest `share/nyx/actions/<app>.json` (`actions = [ "nyx-settings" ]`), desktop entry and icon (`nyx-packages/pkgs/nyx-settings.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | NyxOS has its own system pages (Users, Region, Services, Software, Boot, Lock Screen, Updates, Accounts); VPN provider install and OpenVPN import still go to Omarchy/pacman |
| UX | 2 | Twelve-category sidebar, per-option and per-page reset; some pages near-empty on NyxOS and some strings still say "Omarchy" |
| Accessibility | 2 | 98 tooltips for 42 icon buttons; no explicit accessible labels in the app (relies on tooltip fallback) |
| Reliability | 2 | Debounced atomic writes of `state.json`; few `unwrap()` on runtime data; Omarchy probes degrade to hidden groups |
| Integration | 2 | Action manifest, System Manager, cups-pk-helper; Omarchy calls left in shared pages |
| Packaging | 3 | `nyxos` feature, root helper removed, polkit enabled by the module |
| Maintainability | 2 | 288 tests, but the package runs only `--bin nyx-settings` tests; 560 Omarchy references in the dual-platform code |

## Functionality

- Platform split is explicit: `apps/settings/src/platform/mod.rs:20` picks `Platform::NyxOS` with the `nyxos` feature; `platform/nyxos/layout.rs:62-75` replaces Accounts, Users, Region, Services, Software, Boot and Lock Screen with NyxOS pages and hides the `nyx` page (`layout.rs:79-81`).
- **Pages that still call Omarchy scripts on NyxOS.** Most shared pages guard Omarchy groups with `cmd::present("omarchy-…")` and simply don't show them (Capture `sections/capture.rs:42,156,215,260`, Network `sections/network.rs:57,179,200,218`, Trackpad `sections/trackpad.rs:194`, Displays `sections/displays.rs:189`, Night Light `sections/nightlight.rs:82`). Ungated calls that run on NyxOS:
  - Accounts › VPN: AUR providers install with `omarchy-pkg-aur-add … && sudo systemctl …` in a terminal (`sections/vpn_accounts.rs:341-345`; providers at `:71,80,98,107`); OpenVPN import checks `/usr/lib/NetworkManager/VPN/nm-openvpn-service.name` (never present on NixOS) and runs `omarchy-pkg-add networkmanager-openvpn` (`sections/vpn_accounts.rs:414-418`). See NYX-APP-SETTINGS-001.
  - Harmless probes that fail and fall back: `omarchy-toggle-enabled suspend-off` (`sections/power.rs:189`), `omarchy-version` (`sections/home.rs:144`), `omarchy-font-list`/`-current` (`sections/theme.rs:218,225`).
- Reset to defaults: per option (`widgets.rs:692-706`, six call sites), per page in About › changed options (`sections/about.rs:169-183`), Nyx Bar layout `sections/nyxbarlayout.rs:200`, Shell Core keys `backend/shell_core.rs:78`. There's no "reset everything" for the whole app.
- Persistence: `state.json` in nyx-core's app folder (`paths.rs:23`, `nyx_core::paths::app_dir`) plus the generated Hyprland `hypr/settings.lua` (`backend/store.rs:1-5`); Nyx Bar in `~/.config/nyx/bar.toml`.
- On NyxOS, Settings › Capture & Tools only has voice dictation and possibly an empty Tools group, because every other group needs an `omarchy-*` script (`sections/capture.rs:12-19,305-309,430-470`).

## UX and accessibility (static)

- Search keywords on each section; sidebar categories in `platform/nyxos/layout.rs:7-20`.
- Icon-only reset buttons have tooltips only (`widgets.rs:693-696`); GTK uses tooltips as the accessible description, and as the name only by fallback. Static; confirm names with a screen reader at runtime.
- 37 hard-coded hex colours, 9 of them in `widgets.rs` (graph and swatch drawing).
- Omarchy wording on NyxOS: the reset tooltip says "use the value from your own config or Omarchy's default" (`widgets.rs:696`); the About reset toast says "Back to your own config and Omarchy's defaults" (`sections/about.rs:177`); desktop entry `Keywords=…omarchy…` (`apps/settings/data/io.github.design_nexus.nyx.Settings.desktop:11`).

## Reliability

- 41 `unwrap()` and 6 `expect()` outside `#[cfg(test)]` modules by rough count, most in tests the count missed (`platform/nyxos/updates.rs:593-613`) or on drawing data (`fangraph.rs:132,143`). No `todo!`/`unimplemented!`.
- System changes are asynchronous calls to the System Manager; failures go to toasts.

## Integration and packaging

- Desktop entry with actions `sound` and `trackpad`; icon in `crates/nyx-icons/apps/`. Action manifest installed by `installActions` (`nyx-packages/lib/default.nix:139-154`), using `nyx_actions` in `control.rs`.
- No systemd user unit (none needed). The polkit policy file in `data/` is for the Omarchy helper and is unused on NyxOS.
- Pins: nyx-core `166ff17` (main `9187295`), nyx-design `997a2c1` (main `e311c2f`), nyx-accounts `afdc148`, nyx-cloud `ba6385f` (main), nyx-share `53a5cac` (main `148dc74`); `Cargo.lock` has two nyx-system revisions (`f68ecc8`, `88962d8`).

## Maintenance

- 288 Rust tests (inventory); nix runs `-p nyx-settings --bin nyx-settings` only, as the repository's CI (`tools/ci.py`) does. The CI runs in an Arch container (`.github/workflows/check.yml:10`), not NixOS with the `nyxos` feature.
- README (320 lines) mentions Omarchy 17 times and NyxOS 4 times; `docs/configuration.md`.

## Runtime results

- Smoke test (Settings): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 913 / 941 ms (two warm runs), RSS 233 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- Connected Devices with fluxd stopped shows 'Flux isn't running … Start Flux' (shots/settings-devices-fluxd-stopped.png). 55/55 visible buttons named with the bridge forced on. Launch logs 'Failed to register: Unable to acquire bus name' though the window opens (NYX-REL-001).

## Findings

### NYX-APP-SETTINGS-001: VPN provider install and OpenVPN import run Omarchy/pacman commands on NyxOS

- **Component:** nyx-settings `apps/settings/src/sections/vpn_accounts.rs`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** On NyxOS, Accounts › VPN offers "Install" for NordVPN, ExpressVPN, PIA and Mullvad, which opens a terminal running `omarchy-pkg-aur-add`. Importing an `.ovpn` file always tries to install NetworkManager's OpenVPN plugin with `omarchy-pkg-add`, because it checks an Arch path.
- **Expected:** On NyxOS, software comes from the System Manager or the catalog (nyx-packages `pkgs/nyx-settings.nix:1-3`); OpenVPN support is detected through NetworkManager, not `/usr/lib`.
- **Actual:** `vpn_accounts.rs:341-345` (AUR install), `:414-418` (`/usr/lib/NetworkManager/VPN/nm-openvpn-service.name`, `omarchy-pkg-add`); reached from the NyxOS Accounts page (`platform/nyxos/accounts.rs:10-20`).
- **Reproduce / verify:** On NyxOS, Settings › Accounts › add VPN › NordVPN › Install; or import any `.ovpn` file.
- **Evidence:** source references above.
- **Affected versions:** `7e76622f35`
- **User impact:** A terminal opens with "command not found"; OpenVPN files can never be imported, even with the plugin installed.
- **Recommended correction:** Gate the install path on `Platform::Omarchy`; on NyxOS offer the catalog item or a System Manager package change and detect the plugin through `nmcli`/NetworkManager's VPN plugin directory under `/run/current-system/sw/lib`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** On NyxOS no `omarchy-*` command is spawned from Accounts › VPN; `.ovpn` import works when `networkmanager-openvpn` is in the system.

### NYX-APP-SETTINGS-002: Omarchy wording and near-empty pages on NyxOS

- **Component:** nyx-settings `widgets.rs:696`, `sections/about.rs:177`, `sections/capture.rs`, desktop entry
- **Category:** UX
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Reset controls tell NyxOS users they restore "Omarchy's default"; Capture & Tools shows almost nothing on NyxOS; the desktop entry's keywords include "omarchy".
- **Expected:** Platform-neutral or NyxOS wording on NyxOS builds.
- **Actual:** see Component lines; `sections/capture.rs:42,156,215,260,430` gate every group but dictation on `omarchy-*` scripts.
- **Reproduce / verify:** Hover a reset button; open Capture & Tools on NyxOS.
- **Evidence:** source references above.
- **Affected versions:** `7e76622f35`
- **User impact:** Confusing references to a different distribution.
- **Recommended correction:** Use `platform::` for the wording; hide or redirect Capture & Tools to Nyx Capture's settings on NyxOS.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No "Omarchy" string is visible in a NyxOS build's pages except under Omarchy-only conditions.

### NYX-APP-SETTINGS-003: NyxOS build not tested in CI; package runs only the binary's tests

- **Component:** nyx-settings `.github/workflows/check.yml`, nyx-packages `pkgs/nyx-settings.nix:21-26`
- **Category:** CI
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** CI builds in an Arch container without the `nyxos` feature; the Nix build runs `--bin nyx-settings` tests only, so the extensions and goa helper go untested there.
- **Expected:** The shipped feature set is tested where it ships.
- **Actual:** see Component.
- **Reproduce / verify:** Read the workflow and package.
- **Evidence:** `.github/workflows/check.yml:10-27`; `pkgs/nyx-settings.nix:21-26`.
- **Affected versions:** `7e76622f35`
- **User impact:** NyxOS-only regressions reach users unseen.
- **Recommended correction:** Add a `--features nyxos` test job (or rely on the nyx-packages build in CI and say so).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A CI run exercises `cargo test --features nyxos`.
