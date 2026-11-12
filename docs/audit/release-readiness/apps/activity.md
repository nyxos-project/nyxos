# Nyx Activity scorecard

- **Repository:** design-nexus/nyx-activity at `a1e46d258d` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** base (`nyx.activity.enable`; Super+Ctrl+Escape in nyxos `modules/home/hyprland.nix:232-233`)
- **Purpose:** task manager: processes, live performance graphs, startup items and services
- **Stack:** Rust/GTK4; sampler thread; `systemctl`, `systemd-analyze`, `pkexec`, `nvidia-smi` from the system; hwdata for GPU names
- **Binaries / services:** `nyx-activity`, desktop entry with Processes/Performance/Startup actions, icon (`nyx-packages/pkgs/nyx-activity.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Processes with end/kill, graphs, startup items (written for NyxOS's Hyprland hook), user and system services |
| UX | 2 | Kill confirmation on by default, command palette, keyboard shortcuts; an empty "Omarchy" startup list on NyxOS |
| Accessibility | 2 | 62 tooltips for 19 icon-button sites; no explicit accessible labels |
| Reliability | 3 | No `unwrap()` outside tests; 8 `expect()` on invariants; `kill` skips PID ≤ 1 and handles EPERM/ESRCH |
| Integration | 2 | NyxOS's Hyprland config loads `activity.lua`; no action manifest or Glimpse provider |
| Packaging | 3 | Small wrapper, hwdata on `XDG_DATA_DIRS`, pkexec left as the setuid wrapper |
| Maintainability | 2 | 52 tests, CI `check.yml`; README and crate doc say "for Omarchy" |

## Functionality

- Process signals: `apps/activity/src/actions.rs:48-80` signals each PID, skips PID ≤ 1, retries EPERM ones through one `pkexec kill` and reports "belongs to another user" on refusal.
- Startup items: generated `~/.config/hypr/activity.lua` uses Omarchy's helper when loaded, else `hl.on("hyprland.start", … uwsm app -- …)` (`startup.rs:104-121`); NyxOS's generated `hyprland.lua` `dofile`s it (nyxos `modules/home/hyprland.nix:315-318`). XDG autostart entries in `~/.config/autostart` (`paths.rs:35`).
- Services: `systemctl [--user] list-units/list-unit-files/list-timers -o json` (`startup.rs:392-487`), actions in `sections/services.rs:223`.
- Persistence: `state.json` in nyx-core's app folder (`paths.rs:9`).
- No TODO/`unimplemented!` markers.

## UX and accessibility (static)

- Keys: Esc, Ctrl+F, Ctrl+K palette, Ctrl+B, F1, Ctrl+Q/W (`window.rs:206-246`).
- End task and Kill need a second click while `confirm_kill` is on (default `prefs.rs:84`, `sections/processes.rs:1136`).
- Startup page always shows an "Omarchy" list and "N Omarchy · M yours" (`sections/startup.rs:219-220,391`), empty on NyxOS because `/usr/share/omarchy/default/hypr/autostart.lua` doesn't exist (`paths.rs:29-31`).
- No hard-coded colours outside the theme palette module.

## Reliability

- `expect` sites: sampler start (`sampler/mod.rs:147`), list-item downcasts (`sections/processes.rs:395-418`), map lookups by known id (`startup.rs:237`).
- Offline-independent; the sampler is in-process (no daemon).

## Integration and packaging

- Omarchy references that run on NyxOS: only the read of Omarchy's autostart file above, which fails quietly.
- Pins: nyx-core `4f05fb8` (main `9187295`), nyx-design `cf39397` (main `e311c2f`).

## Maintenance

- 52 tests; `.github/workflows/check.yml`, `release.yml`. README (112 lines) and `main.rs:1` ("a task manager for Omarchy") don't describe NyxOS.

## Runtime results

- Smoke test (Activity): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 581 / 510 ms (two warm runs), RSS 131 MB 4 s after start (logs/perf-app-startup.txt, dev VM).

## Findings

### NYX-APP-ACTIVITY-001: Startup page shows an empty Omarchy section and count on NyxOS

- **Component:** nyx-activity `apps/activity/src/sections/startup.rs:219-220,391-395`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The "With Hyprland" tile reads "0 Omarchy · N yours" and a folded "Omarchy" list ("the bar, notifications, drive mounting") appears empty.
- **Expected:** Omarchy rows only where Omarchy's autostart exists.
- **Actual:** shown unconditionally; data from `startup::omarchy_entries()` (`startup.rs:75-77`).
- **Reproduce / verify:** Open Activity › Startup on NyxOS (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `a1e46d258d`
- **User impact:** Cosmetic; mentions another distribution.
- **Recommended correction:** Hide the list and the count when `omarchy_entries()` is empty and the file is absent.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No "Omarchy" text on the NyxOS Startup page.
