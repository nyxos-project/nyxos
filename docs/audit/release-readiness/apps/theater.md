# Nyx Theater scorecard

- **Repository:** design-nexus/nyx-theater at `e5377d0e51` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("Movies and shows from your media servers.")
- **Purpose:** browse and play Plex and Jellyfin libraries together, with resume and watch-state sync
- **Stack:** Rust/GTK4, libmpv via nyx-design `nyx-playback`, crates `nyx-plex`, `nyx-jellyfin`, `nyx-media-model`, `nyx-media-cache`; Secret Service through `secret-tool`; legacy nyx-core control
- **Binaries / services:** `nyx-theater` (`nyx-packages/pkgs/nyx-theater.nix`: `mpv-unwrapped`, `libGL`; runtime `libsecret`; no `actions`); option `nyx.theater.enable` (`modules/nixos/default.nix:26`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Plex PIN sign-in and server discovery, Jellyfin, merged catalog by TMDB/IMDb/TVDB ids, filters, Direct Play/transcode, resume, next-episode countdown |
| UX | 3 | Home/Discover/Movies/TV/Collections/Search; offline browsing of cached titles |
| Accessibility | 2 | 42 tooltips and 10 explicit accessible labels on 8 icon sites |
| Reliability | 3 | 36 non-test unwraps, nearly all `Mutex::lock()`; `playback.rs:183` unwrap is guarded by `is_some_and`; incremental sync, stream reopen on drop |
| Integration | 2 | No MPRIS; no action manifest; registers video MIME types |
| Packaging | 3 | Pinned; libsecret on PATH; keyring provided by Online Accounts (`modules/nixos/default.nix:681`) |
| Maintainability | 3 | 55 tests, check.yml CI, README current and not Omarchy-specific |

## Functionality

- Plex: web PIN login, account server discovery, local connection preference, rediscovery on address change (`apps/theater/src/plex.rs:198-204,779-796`); manual address + token (`plex.rs:570-636`).
- Jellyfin: address + account (`crates/nyx-jellyfin`).
- Tokens: kept in the Secret Service, never in settings or caches; Disconnect removes them (README "Connecting"; `settings.rs:109,139`). Optional TMDB/MDBList keys: prefs store only enabled flags (`prefs.rs:27-28`).
- Tokens travel as `X-Plex-Token` headers or query parameters (`crates/nyx-plex/src/lib.rs:37,496,548`; `nyx-jellyfin/src/lib.rs:450`), which is how both servers work; URL redaction is tested (`nyx-plex/src/lib.rs:1147-1154`).
- Offline: cached titles stay browsable when a server is down (README).

## UX and accessibility (static)

- Keyboard: Assistant/`--section`/`--toggle`; player keys from nyx-playback.
- Icon buttons mostly named (tooltips plus 10 `update_property` labels); `browse_ui.rs:183` menu button and `library.rs:190` details button flagged by the heuristic.
- Colours: `theme.rs:32` defines `theme_video #000000` (intentional video backdrop).

## Reliability

- Mutex-poisoning unwraps in `metadata.rs`, `catalog.rs`, `artwork.rs` would cascade only after another panic.
- `libc::mallopt(M_ARENA_MAX, 2)` to limit glibc arenas (`main.rs:43-46`).

## Integration and packaging

- Desktop entry `apps/theater/data/io.github.design_nexus.nyx.Theater.desktop`: `MimeType=video/mp4;…` and `Exec=nyx-theater %U`; local files play via `window::open_uri` (`main.rs:94-104`).
- No `org.mpris.MediaPlayer2` server in the repo.
- Control: `nyx_core::control::serve(app, control::tools(), control::handle)` (`main.rs:69`), legacy, no manifest.
- Omarchy: gated `ThemeMode::Omarchy` (`prefs.rs:44`), comment in `theme.rs:7`.

## Maintenance

- Tests: 55; CI `check.yml`, `release.yml`.
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`.

## Runtime results

- Smoke test (Theater): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-THEATER-001: No MPRIS player, so media keys and the bar can't control playback

- **Component:** nyx-theater `apps/theater/src` (no MPRIS module)
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** approved, not implemented
- **Description:** NyxOS binds media keys to `playerctl` (`nyxos/modules/home/hyprland.nix:207-210`), and the bar, Control Center and dock list MPRIS players. Theater plays video in-process with libmpv and publishes no MPRIS player, unlike Music, Lyra and Media Player.
- **Expected:** Every Nyx media app exposes `org.mpris.MediaPlayer2.*`.
- **Actual:** `rg -l MediaPlayer2 nyx-theater` finds nothing.
- **Reproduce / verify:** Play a title; `playerctl -l` doesn't list Theater (static; confirm at runtime).
- **Evidence:** compare `nyx-media-player/apps/media-player/src/mpris.rs`
- **Affected versions:** `e5377d0e51`
- **User impact:** Play/pause keys, headset buttons and the bar's media card don't work with Theater.
- **Recommended correction:** Port Media Player's `mpris.rs`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `playerctl -p theater play-pause` toggles playback.

### NYX-APP-THEATER-002: No action manifest (legacy control API)

- **Component:** nyx-theater `apps/theater/src/main.rs:69`; `nyx-packages/pkgs/nyx-theater.nix`
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Assistant tools are served only while the window runs; no manifest or D-Bus activation file is installed.
- **Expected:** API 2 actions with `describe_if_asked` and `actions = [ … ]` in the package (H05 registry).
- **Actual:** `control::serve` only.
- **Reproduce / verify:** No `io.github.design_nexus.nyx.Theater.json` under `share/nyx/actions`.
- **Evidence:** `nyx-core/crates/nyx-core/src/control.rs:100-135`
- **Affected versions:** `e5377d0e51`
- **User impact:** "Play … in Theater" fails when Theater is closed.
- **Recommended correction:** Port to `serve_with`.
- **Effort:** S
- **Dependencies:** NYX-APP-MEDIA-PLAYER-001
- **Verification criteria:** Manifest installed; headless start works.

### NYX-APP-THEATER-003: Registers local video MIME types, competing with Media Player

- **Component:** `apps/theater/data/io.github.design_nexus.nyx.Theater.desktop:9`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Theater claims eight video types although it's a media-server client; nyxos sets no default, so a double-clicked file may open in Theater.
- **Expected:** Media Player is the default local video player.
- **Actual:** as cited; no `mimeapps` defaults in nyxos.
- **Reproduce / verify:** `xdg-mime query default video/x-matroska` with both installed.
- **Evidence:** as cited
- **Affected versions:** `e5377d0e51`
- **User impact:** Unexpected app opens local videos.
- **Recommended correction:** Remove `MimeType` (keep `%U` for URIs) or set NyxOS defaults.
- **Effort:** S
- **Dependencies:** NYX-APP-MEDIA-PLAYER-002
- **Verification criteria:** Defaults resolve to Media Player.
