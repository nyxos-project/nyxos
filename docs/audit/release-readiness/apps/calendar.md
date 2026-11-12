# Nyx Calendar scorecard

- **Repository:** design-nexus/nyx-calendar at `54113d6511` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user)
- **Purpose:** calendar with online and local calendars, invitations and reminders
- **Stack:** Rust/GTK4; storage through nyx-core's native `nyx-pim` (SQLite + libical 4, imported under the alias `nyx-eds`); accounts via nyx-accounts `afdc148`; `nyx-calendard` reminder daemon
- **Binaries / services:** `nyx-calendar`, `nyx-calendard`, `nyx-calendar-glimpse`; user unit `nyx-calendard.service` (graphical session); action manifest `nyx-calendar` (`nyx-packages/pkgs/nyx-calendar.nix`, `buildInputs = nyx.pimInputs`, TZDIR for tests)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Views, natural-language entry, repeats, invitations, .ics import/export; per-event time zones and moving events between calendars open |
| UX | 2 | Keyboard map, agenda/day/week/month; README banner calls `main` "not merge-ready" |
| Accessibility | 2 | 9 explicit labels, 17 tooltips |
| Reliability | 3 | 3 non-test `unwrap()`, all on constants in `online_check.rs`; hardened unit with restart |
| Integration | 2 | text/calendar MIME, actions manifest, Glimpse plugin; D-Bus activation for per-user installs unverified |
| Packaging | 3 | libical 4 provided by nyx-packages; no EDS needed |
| Maintainability | 2 | 36 tests; README states a branch status that no longer matches |

## Functionality

README lists day/week/month/agenda, natural-language add, repeat exceptions, invitations,
reminders with snooze, .ics import/export, offline cache. Open items in docs/PLAN.md:34-35
(per-event time zone, moving an event to another calendar). Persistence: nyx-pim SQLite
stores (`crates/nyx-calendar-core/Cargo.toml:13`). **EDS:** not in the NyxOS package or
module, and not required: the code links `nyx-pim`, not libecal; nyx-packages blocks the
EDS crates and `nyx-pim-migrate` (`nyx-packages/lib/default.nix:47-56`), so the README's
EDS migration path (README.md:1-5) isn't available on NyxOS (no prior EDS data there anyway).

## UX and accessibility (static)

Keys N/T/D/W/M/A/J/K/R, Ctrl+F, F1. Colour literals are calendar colour choices
(`apps/calendar/src/menus.rs:115-122`, `account_logo.rs:86-87`), not chrome.

## Reliability

`nyx-calendard.service`: `Restart=on-failure`, `UMask=0077`, `NoNewPrivileges`. `unwrap()`s
only on fixed values in `apps/calendar/src/online_check.rs:25-57`.

## Integration and packaging

Desktop entry with `text/calendar;application/ics`; icon present. Action manifest declares
`"activation": "dbus"` (`apps/calendar/src/control.rs:70`), so nyx-packages writes a D-Bus
service file (`nyx-packages/lib/default.nix:147-152`). Glimpse plugin present (same per-user
linking gap as NYX-APP-MAIL-002). Only Omarchy reference: theme default (`prefs.rs:60`).

## Maintenance

36 tests. CI: check + release. Pins: nyx-accounts `afdc148`, nyx-glimpse `6f9f732`, common
nyx-core/nyx-design pins. README.md:1-5 banner and "A calendar for Omarchy" are stale.

## Runtime results

- Smoke test (Calendar): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 623 / 638 ms (two warm runs), RSS 150 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- Per-user install on the installed system works, but its D-Bus name isn't activatable, `nyx calendar` is unknown and its daemon waits for the next sign-in (NYX-PKG-009); a second app with session units then can't install (NYX-PKG-008).

## Findings

### NYX-APP-CALENDAR-001: Google/Microsoft calendars need a self-registered OAuth client

- **Component:** nyx-accounts `afdc148`; nyx-calendar README
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Same accounts limitation as NYX-APP-MAIL-001. CalDAV with app passwords (Fastmail, Nextcloud, iCloud) works without it; Google does not.
- **Expected:** "Calendars, synced with your online accounts" (catalog) works for Google without developer setup.
- **Actual:** README.md:9-10 lists Google and personal Microsoft; nyx-accounts `afdc148:docs/PROVIDERS.md:3-25`.
- **Reproduce / verify:** See NYX-APP-MAIL-001.
- **Evidence:** `nyx-calendar/README.md:9-10`, `nyx-system/crates/nyx-catalog/catalog.toml:286-291`
- **Affected versions:** 54113d6511
- **User impact:** Google Calendar users can't sync.
- **Recommended correction:** As NYX-APP-MAIL-001.
- **Effort:** L
- **Dependencies:** NYX-APP-MAIL-001
- **Verification criteria:** A Google calendar syncs without a client ID.

### NYX-APP-CALENDAR-002: Action manifest's D-Bus activation may not work for per-user installs

- **Component:** nyx-packages `lib/default.nix` (`installActions`), `modules/nixos/default.nix`
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** `nyx calendar …`, Glimpse and the Assistant start Calendar through `share/dbus-1/services/io.github.design_nexus.nyx.Calendar.service`. The module registers it with `services.dbus.packages` only for system installs; Welcome installs into the Nix profile, and no NyxOS code points the session bus at profile service folders.
- **Expected:** Actions work whether or not Calendar is running, for any install scope.
- **Actual:** `lib/default.nix:147-152`; `modules/nixos/default.nix:145, 249-256`; no `dbus-1` handling in nyx-system or nyxos modules.
- **Reproduce / verify:** Install Calendar from Welcome, keep it closed, run `nyx calendar search lunch` (runtime).
- **Evidence:** as above
- **Affected versions:** nyx-packages d69e87e
- **User impact:** Assistant/CLI calendar actions may fail until the app is opened; also Passwords (`activation: dbus`).
- **Recommended correction:** Confirm whether the session bus reads `~/.nix-profile/share/dbus-1/services`; if not, add those folders in NyxOS's session bus config.
- **Effort:** S
- **Dependencies:** NYX-PKG per-user install review
- **Verification criteria:** The action starts Calendar via D-Bus from a per-user install.

### NYX-APP-CALENDAR-003: README on `main` says the branch is not merge-ready

- **Component:** nyx-calendar `README.md`, `docs/PLAN.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README.md:1-5 calls this a "development branch … not merge-ready" and points to an EDS migration tool NyxOS doesn't ship; line 9 says "for Omarchy". PLAN lists per-event time zones and moving events as not done (docs/PLAN.md:34-35).
- **Expected:** README reflects the released state and NyxOS.
- **Actual:** as cited.
- **Reproduce / verify:** `sed -n 1,10p nyx-calendar/README.md`
- **Evidence:** `nyx-calendar/README.md:1-9`, `docs/PLAN.md:34-35`
- **Affected versions:** 54113d6511
- **User impact:** Signals unfinished software; mentions unavailable tools.
- **Recommended correction:** Drop the banner; document the native store and the NyxOS install.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** README describes the shipped app.
