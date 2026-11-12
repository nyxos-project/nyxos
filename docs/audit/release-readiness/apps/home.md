# Nyx Home scorecard

- **Repository:** design-nexus/nyx-home at `f70d1e63d0` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("Smart home devices and automations.")
- **Purpose:** native Home Assistant client plus desktop automations (When/If/Then builder, graph editor) run by a user daemon
- **Stack:** Rust/GTK4, reqwest (native TLS) to Home Assistant REST/WebSocket, libmpv for camera streams, `nyx-homed` daemon on D-Bus `io.github.design_nexus.nyx.Home.Automation`, `nyx-homectl` CLI, nyx-actions (API 2) served by the daemon
- **Binaries / services:** `nyx-home`, `nyx-homed`, `nyx-homectl` (`nyx-packages/pkgs/nyx-home.nix`: `actions = [ "nyx-homed" ]`, `userUnits = [ data/nyx-homed.service ]`, `dbusServices = [ …Home.Automation.service ]`, `passthru.autostart."nyx-homed" = "graphical-session.target"`; runtime `gtk4` (gtk-launch), `wireplumber`, `libnotify`, `libsecret`); option `nyx.home.enable` (`modules/nixos/default.nix:32`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Devices, rooms, scenes, climate, cameras, vacuum/mower maps, HA automation editing, desktop and hybrid workflows; no stubs |
| UX | 2 | Rich but dense (canvas, builder, robot map); clear keyring/token error states (`overview.rs:536-557`) |
| Accessibility | 3 | 164 explicit accessible-property calls, 41 tooltips; one unnamed button flagged (`app.rs:316`) |
| Reliability | 2 | Daemon `Restart=on-failure`, hardened unit; 24 non-test unwraps (mostly mutex locks; graph unwraps after `validate()`) |
| Integration | 3 | User unit with D-Bus activation, actions manifest with confirmation for routines, Glimpse `home` panel |
| Packaging | 3 | Units rewritten to the store path by `installServices`; autostart for per-user installs |
| Maintainability | 2 | 56 tests, ARCHITECTURE/IMPLEMENTATION_PLAN docs; only `release.yml` CI, no check workflow |

## Functionality

- Connection: address (http or https) + long-lived access token; token stored in the Secret Service through `src/credentials.rs` (`secret-tool`), never in settings; locked/missing/rejected token states each have a recovery action (`connection.rs:28-70`, `overview.rs:536-557`).
- Desktop actions in automations: notify, volume (`wpctl`), launch app (`gtk-launch`), switch Hyprland workspace (`bin/homed.rs:620-650`), all argv-based, no shell.
- Assistant actions: devices (read-only), switch/light/scene/climate (writes), routines (read-only), run routine (`confirmation: ask`), open (`bin/homed/actions.rs:30-58`). Locks, alarms and covers aren't exposed as actions.
- Persistence: workflows, runs and event receipts in the daemon's SQLite database (WAL; `bin/homed.rs:28`); prefs via `nyx_core` (`src/prefs.rs`).
- Offline: daemon keeps desktop-only workflows running without Home Assistant (static; confirm).

## UX and accessibility (static)

- Keyboard: 9 shortcut/controller sites; builder supports drag-and-drop placement.
- Colours: robot map fallbacks `#9d7cd8`/`#f7768e` when theme colours are missing (`robot_map.rs:281-282`); `style.css:234` one literal.

## Reliability

- `nyx-homed.service`: `Type=dbus`, `Restart=on-failure`, `RestartSec=3`, `UMask=0077`, `NoNewPrivileges`, `LockPersonality`, `RestrictRealtime` (`data/nyx-homed.service`).
- Started with the graphical session for every user who has Home, and by D-Bus on demand.

## Integration and packaging

- Desktop entry `data/io.github.design_nexus.nyx.Home.desktop` (Utility;Settings); icon `data/icons/io.github.design_nexus.nyx.Home.svg`.
- Glimpse panel `nyx-glimpse/quickshell/Glimpse/panels/home`.
- Omarchy: no references outside a gated theme default (`prefs.rs:41`) and a comment.

## Maintenance

- Tests: 56; CI `release.yml` only (manual dispatch).
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`.
- Docs: README (224 lines) and `docs/` current to Phase 7; "Assistant integration was left for later" (`docs/IMPLEMENTATION_PLAN.md:28-29`) is outdated now that actions exist.

## Runtime results

- Smoke test (Home): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-HOME-001: No CI check workflow

- **Component:** nyx-home `.github/workflows/` (only `release.yml`)
- **Category:** CI
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Tests (56) only run on manual release dispatch; pushes to main aren't checked.
- **Expected:** `check.yml` on push/PR as in the other apps.
- **Actual:** `evidence/inventory.json` `"workflows": ["release.yml"]`.
- **Reproduce / verify:** `ls nyx-home/.github/workflows`
- **Evidence:** as above
- **Affected versions:** `f70d1e63d0`
- **User impact:** Regressions in the daemon may ship unnoticed.
- **Recommended correction:** Add the shared `check.yml`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Green check on main.

### NYX-APP-HOME-002: Plain-HTTP Home Assistant addresses accepted without a warning

- **Component:** nyx-home `src/connection.rs:273,361`, `src/hybrid.rs:386`
- **Category:** security
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The connection dialog suggests `http://homeassistant.local:8123` and accepts any `http://` address; the long-lived token then crosses the network in clear text. Typical for LAN Home Assistant, but there's no warning for non-local hosts.
- **Expected:** Warn when using http to a non-private address; prefer https.
- **Actual:** `valid_url` accepts http (`connection.rs:448-449` test).
- **Reproduce / verify:** Enter `http://example.org:8123`; no warning (static; confirm at runtime).
- **Evidence:** as cited
- **Affected versions:** `f70d1e63d0`
- **User impact:** Token exposure on untrusted networks.
- **Recommended correction:** Show a warning for http outside RFC 1918/`.local`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Warning appears for public http addresses.

### NYX-APP-HOME-003: Implementation plan says Assistant integration is pending

- **Component:** nyx-home `docs/IMPLEMENTATION_PLAN.md:28-29`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The plan says Assistant integration was left for later, but `bin/homed/actions.rs` serves eight actions.
- **Expected:** Docs match the code.
- **Actual:** as cited.
- **Reproduce / verify:** read both files
- **Evidence:** as cited
- **Affected versions:** `f70d1e63d0`
- **User impact:** None for users; misleads contributors.
- **Recommended correction:** Update the plan.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Plan lists the actions.
