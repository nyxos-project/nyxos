# Nyx Maps scorecard

- **Repository:** design-nexus/nyx-maps at `ef6fe24cfe` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** store (`catalog.toml:443-448`; per-user install)
- **Purpose:** lightweight native maps: search, directions, saved places, current location
- **Stack:** Rust/GTK4 + libshumate 1.7 (5.6k lines), SQLite, zbus (GeoClue), nyx-share-client
- **Binaries / services:** `nyx-maps` (also `--api`); no services (`nyx-packages/pkgs/nyx-maps.nix`). `nyx.maps.enable` turns on GeoClue (`modules/nixos/default.nix:383-385`); per-user installs don't.

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Search, three styles, directions, saved places, GeoClue implemented; routing on a demo server |
| UX | 2 | Shortcuts (Ctrl+F/B/R, F1, Esc), labelled header buttons; 35 hard-coded colours in the vector style |
| Accessibility | 2 | Header buttons get labels via `widgets::bar_button` (`ui/window.rs:108`); 9 tooltips, no accessible properties |
| Reliability | 2 | 9 unwrap/expect; depends on free community services with usage limits |
| Integration | 2 | `geo:`/`nyx-maps:` handler, Share, `--api`; no action manifest packaged; GeoClue missing for per-user installs |
| Packaging | 2 | Clean; skips a network test; GeoClue tied to the system option |
| Maintainability | 2 | 12 tests; only `release.yml`; README Arch/Omarchy |

## Functionality

- **Providers:** vector tiles from OpenFreeMap, OSM raster, OpenTopoMap, Esri imagery (`src/providers/tiles.rs:79-127`); geocoding Photon and Nominatim with a proper User-Agent (`geocoding.rs:131,193,248,288`); routing public OSRM demo (`routing.rs:214`) or Geoapify with a user key (`routing.rs:152`).
- **Location privacy:** "Find my location" is user-initiated (`ui/window.rs:573`); GeoClue first, then silent IP lookup to ipwho.is and ipapi.co (`location/geoclue.rs:162-200`).
- **Persistence:** SQLite for favourites, Home/Work, recents (`src/storage/sqlite.rs`).
- No stubs found.

## UX and accessibility (static)

README shortcut table matches the window. Vector style colours are map palette (light/dark), acceptable.

## Reliability

No daemons. Network failures show in search/directions. The OSRM demo and OSM tile servers have usage policies that rule out production clients at scale (NYX-APP-MAPS-001).

## Integration and packaging

Desktop entry with `MimeType=x-scheme-handler/geo;x-scheme-handler/nyx-maps;` and icon (`data/`). README promises Assistant access over `--api`/D-Bus, but nyx-packages installs no action manifest for Maps. No Omarchy calls in source (README only).

## Maintenance

12 tests; no `check.yml`. Pins nyx-core `4f05fb8`, nyx-design `cf39397`, nyx-share `3923640`.

## Runtime results

- Smoke test (Maps): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-MAPS-001: Directions depend on the public OSRM demo server

- **Component:** nyx-maps `src/providers/routing.rs:146-214`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Without a Geoapify key, routes come from `router.project-osrm.org`, a demo instance whose policy limits use and offers no availability; raster styles also use `tile.openstreetmap.org` under the OSM tile policy.
- **Expected:** A shipped OS uses a provider it is allowed to depend on, or states the limitation.
- **Actual:** Demo server is the default.
- **Reproduce / verify:** Request a route without a key; inspect requests. Static; confirm at runtime.
- **Evidence:** as above; `src/providers/tiles.rs:100`
- **Affected versions:** `ef6fe24cfe`
- **User impact:** Directions may be throttled or stop working.
- **Recommended correction:** Choose a sanctioned routing provider (or a Nyx-run one) and surface the key setting.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** Default routing uses a provider whose terms allow it.

### NYX-APP-MAPS-002: Per-user installs have no GeoClue, so "my location" falls back to third-party IP lookup

- **Component:** `nyx-packages/modules/nixos/default.nix:383-385`; nyx-maps `src/location/geoclue.rs:162-200`
- **Category:** privacy
- **Severity:** P2
- **Status of feature:** partial
- **Description:** GeoClue is enabled only by `nyx.maps.enable`; the Store installs Maps into the user's profile, so GeoClue is usually absent and Maps silently queries ipwho.is, then ipapi.co.
- **Expected:** Location through the desktop service, or a visible notice before contacting a third party.
- **Actual:** No notice; nothing else in nyxos enables `services.geoclue2` (only Maps/Pulse options).
- **Reproduce / verify:** Install Maps from the Store on a fresh VM; press Find my location; watch network. Static; confirm at runtime.
- **Evidence:** as above; `nyx-system/crates/nyx-catalog/catalog.toml:11-15` (scope)
- **Affected versions:** `ef6fe24cfe`, nyx-packages `d69e87e`
- **User impact:** City-level location from the IP, sent to third parties without the user knowing.
- **Recommended correction:** Enable GeoClue for the desktop (or via `services` in the catalog item); tell the user before IP fallback.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Store-installed Maps locates through GeoClue on a fresh install.

### NYX-APP-MAPS-003: No CI checks, thin tests, Arch-only README

- **Component:** nyx-maps `.github/workflows/release.yml`, `README.md`
- **Category:** CI
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Only a release workflow; 12 tests; README installs with pacman and "follows Omarchy theme".
- **Expected:** `check.yml` like peers; NyxOS docs.
- **Actual:** As cited.
- **Reproduce / verify:** `ls .github/workflows`.
- **Evidence:** as above
- **Affected versions:** `ef6fe24cfe`
- **User impact:** Regressions undetected.
- **Recommended correction:** Add `check.yml`; update README.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** CI runs tests on push.
