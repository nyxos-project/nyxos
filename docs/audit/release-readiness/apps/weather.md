# Nyx Weather scorecard

- **Repository:** design-nexus/nyx-weather at `1bdbad59e0` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** store (`catalog.toml:435-440`; per-user install)
- **Purpose:** forecasts, hourly graphs, radar, air quality and severe-weather alerts
- **Stack:** Rust/GTK4 (11k lines), SQLite cache; `nyx-weather-core` providers
- **Binaries / services:** `nyx-weather` (also `--json`, `--waybar`, `--refresh`); action manifest via `actions = [ "nyx-weather" ]` (`nyx-packages/pkgs/nyx-weather.nix`). The Omarchy bar widget (`apps/weather/plugin/BarWidget.qml`) isn't installed.

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Forecast, hourly, daily, radar, air quality, astronomy, NOAA alerts implemented; no stubs |
| UX | 3 | Cached forecast shown at once, stale fallback, labelled icon buttons |
| Accessibility | 2 | Icon buttons have tooltips (`sections/settings.rs:209`, `radar.rs:566`); 1 accessible property; 8 hard-coded colours |
| Reliability | 3 | 0 unwrap/expect in non-test code; SQLite cache with stale fallback |
| Integration | 2 | Actions manifest (nyx, Glimpse, Assistant); float preference writes an Omarchy Lua file NyxOS ignores |
| Packaging | 3 | Simple buildApp, desktop entry, icon |
| Maintainability | 2 | 29 tests, CI `check.yml`; Omarchy/Waybar wording and code paths |

## Functionality

- **Providers:** Open-Meteo forecast, air quality and geocoding (`crates/nyx-weather-core/src/open_meteo.rs:26-28`), NOAA alerts for the US (`noaa.rs:21`), RainViewer and Iowa Mesonet radar with OSM base tiles (`radar.rs:19,129,342,433`). No API key needed; an optional Open-Meteo commercial key is sent as `apikey` (`open_meteo.rs:133-134`).
- **Location privacy:** no automatic location; places come from geocoding searches the user types and are stored locally. Only the saved coordinates go to the providers.
- **Persistence:** prefs file and SQLite cache under XDG dirs (`apps/weather/src/paths.rs`).
- **Offline:** shows the cached forecast and marks it stale (`window.rs:581-603,896-897`).

## UX and accessibility (static)

Sections for overview, hourly, daily, radar, air quality, astronomy, settings. Icon-only buttons spot-checked carry tooltips. Hard-coded colours: 8 (charts/CSS).

## Reliability

No daemons. Notifications for alerts (`notify.rs`). Network errors fall back to cache.

## Integration and packaging

Desktop entry and icon (`apps/weather/data/…Weather.desktop`, `crates/nyx-icons/apps/…Weather.svg`); action manifest installed by `installActions`. Omarchy leftovers on NyxOS: the "float window" preference writes `~/.config/hypr/nyx.lua` in Omarchy's `o.window(...)` syntax and runs `hyprctl reload` (`apps/weather/src/prefs.rs:148-176,255-264`); NyxOS's Hyprland config never loads `nyx.lua` (`nyxos/modules/home/hyprland.nix:259-338`). Default is off (`prefs.rs:84`), so nothing runs unless toggled. `--waybar` output remains (`waybar.rs`).

## Maintenance

29 tests; CI `check.yml`, `release.yml`. Pins nyx-core `4f05fb8`, nyx-design `cf39397`. README describes Omarchy and Waybar.

## Runtime results

- Smoke test (Weather): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 712 / 688 ms (two warm runs), RSS 150 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- Offline it keeps showing cached data with no visible offline note (shots/offline-weather.png).

## Findings

### NYX-APP-WEATHER-001: Floating-window preference writes an Omarchy rule and reloads Hyprland on NyxOS

- **Component:** nyx-weather `apps/weather/src/prefs.rs:148-264`
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Toggling "float window" writes `~/.config/hypr/nyx.lua` (Omarchy's Lua framework) and runs `hyprctl reload`; NyxOS doesn't source that file, so the setting has no lasting effect, and the reload re-reads the whole compositor config.
- **Expected:** Window rules through NyxOS's mechanism (Shell Core / nyx-window-controls) or the option hidden.
- **Actual:** As cited; `nyxos/modules/home/hyprland.nix` has no `nyx.lua` include.
- **Reproduce / verify:** Toggle the option on NyxOS, reopen Weather. Static; confirm at runtime.
- **Evidence:** as above
- **Affected versions:** `1bdbad59e0`
- **User impact:** A setting that appears to do nothing; an unnecessary compositor reload.
- **Recommended correction:** Hide on NyxOS or write a rule NyxOS loads.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Toggle persists across restarts on NyxOS without `hyprctl reload`.

### NYX-APP-WEATHER-002: Omarchy and Waybar wording in README and entry point

- **Component:** nyx-weather `README.md`, `apps/weather/src/main.rs:1,28-29`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Documentation and help text describe Omarchy and a Waybar module.
- **Expected:** NyxOS wording; bar summary via `--json` for Nyx Bar.
- **Actual:** As cited.
- **Reproduce / verify:** `nyx-weather --help`.
- **Evidence:** as above
- **Affected versions:** `1bdbad59e0`
- **User impact:** Minor confusion.
- **Recommended correction:** Rewrite for NyxOS; keep Waybar as an Arch note.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Help text mentions no Omarchy-only paths.
