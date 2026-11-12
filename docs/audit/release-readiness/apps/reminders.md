# Nyx Reminders scorecard

- **Repository:** design-nexus/nyx-reminders at `6907cd65cd` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** store (`catalog.toml:451-456`; per-user install)
- **Purpose:** Today/Scheduled/Flagged task lists from every account and this computer, with alerts
- **Stack:** Rust/GTK4 (5k lines), `nyx-pim` (aliased `nyx-eds`) native store, `nyx-accounts-service`, libical
- **Binaries / services:** `nyx-reminders` (D-Bus activated for actions with `--gapplication-service`), `nyx-remindersd` (alerts; autostart with the graphical session, hardened unit), `reminders-glimpse`; action manifest (`nyx-packages/pkgs/nyx-reminders.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Lists, natural-language add, repeats, subtasks, alerts implemented; provider sync is an unverified preview |
| UX | 3 | Full keyboard map (N, J/K, Space, S, 1-4, Ctrl+F, F1), offline copy |
| Accessibility | 2 | 7 tooltips, 7 accessible properties; 9 hard-coded colours |
| Reliability | 2 | 2 unwrap/expect; `nyx-remindersd` `Restart=on-failure`, `NoNewPrivileges`, `UMask=0077` |
| Integration | 3 | Actions (nyx, Glimpse, Assistant), Glimpse plugin, D-Bus activation, Nyx Bar completion (`--complete`) |
| Packaging | 3 | Units, actions, Glimpse plugin and autostart from the package |
| Maintainability | 2 | 16 tests, CI; README contradicts the code |

## Functionality

- **Sync backends:** accounts from Online Accounts (Google Tasks, Microsoft To Do, Nextcloud/CalDAV) and local lists, stored in `nyx-pim`'s SQLite with queued writes (`README.md:7-25`; `apps/reminders/Cargo.toml:18-21`). nyx-accounts says real provider delivery "remains unverified" and its branch must not merge without validation (`nyx-accounts/docs/IMPLEMENTATION.md:27,43`).
- **Persistence:** `nyx-pim` store; sidecar for what VTODO can't hold (`crates/nyx-reminders-core/src/lib.rs:3-5`).
- **Offline:** works from the saved copy, catches up later (README).
- "VTODO"/"todo" matches are iCalendar terms, not stubs.

## UX and accessibility (static)

Keyboard-first, tiled half-screen; accessible properties set on rows. Theme via nyx-theme (`ThemeMode::Omarchy` means "follow the system").

## Reliability

Alerts daemon hardened (`apps/remindersd/data/nyx-remindersd.service`); the app quits when idle after a D-Bus call.

## Integration and packaging

Desktop entry and icon present; Glimpse plugin installed to `share/nyx-reminders/glimpse`; action manifest with D-Bus activation. Omarchy references (11) are comments and README.

## Maintenance

16 tests (package sets `TZDIR`); CI `check.yml`, `release.yml`. Pins nyx-core `4f05fb8`, nyx-design `cf39397`, nyx-accounts `afdc148` (origin `e0df68a`), nyx-glimpse `6f9f732`.

## Runtime results

- Smoke test (Reminders): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-REMINDERS-001: Account sync rests on an unverified Online Accounts preview, and main still says "not merge-ready"

- **Component:** nyx-reminders `README.md:1-5`; nyx-accounts `docs/IMPLEMENTATION.md:27,43`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The catalog sells "Reminders and to-do lists, synced"; the sync path is nyx-accounts' native providers, whose own docs say real Google/Microsoft delivery is unverified, and the Reminders README on `main` still carries the feature-branch banner.
- **Expected:** Advertised sync verified against real providers before release (handoff 10 status rules).
- **Actual:** As cited.
- **Reproduce / verify:** Add a Google and a Microsoft account on the VM; create, complete and edit tasks both ways. Runtime check needed.
- **Evidence:** as above; `nyx-system/crates/nyx-catalog/catalog.toml:453`
- **Affected versions:** `6907cd65cd`, nyx-accounts `afdc148`
- **User impact:** Possible lost or duplicated task edits with real accounts.
- **Recommended correction:** Run the provider validation; remove the banner or keep sync marked preview in the Store text.
- **Effort:** M
- **Dependencies:** Accounts audit findings
- **Verification criteria:** Documented provider round-trip passes; README matches status.

### NYX-APP-REMINDERS-002: Docs contradict the backend

- **Component:** nyx-reminders `README.md:1-5,10-18`, `crates/nyx-reminders-core/src/lib.rs:3`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The core crate says tasks live in Evolution Data Server; the README says EDS was replaced; the README also says "for Omarchy".
- **Expected:** One accurate description.
- **Actual:** As cited.
- **Reproduce / verify:** Read both files.
- **Evidence:** as above
- **Affected versions:** `6907cd65cd`
- **User impact:** Maintainer confusion.
- **Recommended correction:** Update the module doc and README.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Docs describe `nyx-pim`.
