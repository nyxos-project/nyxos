# Nyx Media Player scorecard

- **Repository:** design-nexus/nyx-media-player at `af518c0448` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("Play videos and music files.")
- **Purpose:** local movie/TV library and video player with resume, subtitles, playlists and an equalizer
- **Stack:** Rust/GTK4, libmpv through nyx-design's `nyx-playback` (EGL), SQLite library, zbus MPRIS server, legacy nyx-core control (`control::serve_async`)
- **Binaries / services:** `nyx-media-player` (`nyx-packages/pkgs/nyx-media-player.nix`: `mpv-unwrapped`, `libGL`; runtime `ffmpeg`, `yt-dlp`, `libnotify`, `xdg-utils`; no `actions`); option `nyx.media-player.enable` (`modules/nixos/default.nix:25`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Library (NFO, optional TMDB), resume, Up next, subtitles, chapters, picture/sound controls, web URLs via yt-dlp, playlists; no stubs |
| UX | 3 | Documented keys, scrub previews, drag-and-drop, Continue watching |
| Accessibility | 2 | 25 tooltips on 11 icon sites; 2 explicit accessible labels |
| Reliability | 3 | 0 unwraps and 14 GTK-invariant expects outside tests; ffmpeg/yt-dlp presence checked (`window.rs:811-816`) |
| Integration | 2 | MPRIS and video MIME types; no installed action manifest |
| Packaging | 3 | Pinned; ffmpeg and yt-dlp on the wrapper PATH |
| Maintainability | 2 | 42 tests, check.yml CI; README is Omarchy-oriented |

## Functionality

- Implemented: scan with incremental rescans (`library/scan.rs:322-373`; "todo" there is a variable), TMDB enrichment with the user's own key (`library/tmdb.rs:20-27,246-300`), resume and watched marks, subtitles, chapters, M3U import/export, equalizer, screenshot (Ctrl+S), screen inhibit while playing (README).
- Persistence: settings TOML (including `tmdb_key`), SQLite library in the data dir, cached art.
- Offline: local playback offline; TMDB and yt-dlp need the network and fail with messages (`tmdb.rs:41-42`).

## UX and accessibility (static)

- Keyboard: ←/→, 0–9, Page Up/Down, Ctrl+F, Ctrl+L, Ctrl+S (README "What it does").
- Icon buttons mostly carry tooltips; menu rows and popover buttons use label children.
- No hard-coded colours found in Rust/CSS.

## Reliability

- No daemon; single-instance GApplication; mpv in-process via libmpv.
- yt-dlp from nixpkgs is pinned with the system; site breakage follows nixpkgs update cadence.

## Integration and packaging

- Desktop entry `apps/media-player/data/io.github.design_nexus.nyx.MediaPlayer.desktop` with 19 video MIME types, no audio types.
- MPRIS: `apps/media-player/src/mpris.rs`.
- Control: `nyx_core::control::serve_async(app, control::tools(), control::handle)` (`main.rs:108`), the older API that only answers while the app runs; no `--describe-actions`, so nyx-packages installs no manifest.
- Omarchy: gated `ThemeMode::Omarchy` default (`prefs.rs:88`); README/Cargo wording only.

## Maintenance

- Tests: 42; CI `check.yml`, `release.yml`.
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`.
- Docs: README detailed but "A video player for Omarchy" (`README.md:3`).

## Runtime results

- Smoke test (Media Player): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-MEDIA-PLAYER-001: No action manifest; nyx CLI, Glimpse and Assistant can't reach it when closed

- **Component:** nyx-media-player `apps/media-player/src/main.rs:108`; `nyx-packages/pkgs/nyx-media-player.nix`
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** partial
- **Description:** The app uses nyx-core's legacy `control::serve_async` (Describe/Call while running) rather than the API 2 action description with `describe_if_asked`, so no `share/nyx/actions/*.json` or D-Bus activation file is installed.
- **Expected:** Shared action registry (H05): each app's manifest installed so `nyx <app>`, Glimpse and the Assistant can discover and start it.
- **Actual:** No `describe_if_asked` in the repo; package has no `actions` attribute.
- **Reproduce / verify:** `ls /run/current-system/sw/share/nyx/actions/ | grep MediaPlayer` (expect none)
- **Evidence:** `nyx-core/crates/nyx-core/src/control.rs:100-135`
- **Affected versions:** `af518c0448`
- **User impact:** "Play X in Media Player" via Assistant works only while the window is open.
- **Recommended correction:** Port to `serve_with` + `describe_if_asked` as Music did; add `actions = [ "nyx-media-player" ]`.
- **Effort:** S
- **Dependencies:** same gap in Theater, Torrents, Fonts, Pulse
- **Verification criteria:** Manifest present; `nyx media-player status` starts the app headless.

### NYX-APP-MEDIA-PLAYER-002: Catalog says "music files" but only video types are registered; no default video handler on NyxOS

- **Component:** `nyx-system/crates/nyx-catalog/catalog.toml` (nyx-media-player), `apps/media-player/data/io.github.design_nexus.nyx.MediaPlayer.desktop:11`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The catalog summary promises music files; the desktop entry lists only `video/*`. Nyx Theater also registers video MIME types, and nyxos sets no `mimeapps` defaults, so which app opens a video is undefined when both are installed.
- **Expected:** Accurate summary; a defined default video player.
- **Actual:** No `video/mp4` default anywhere under `nyxos/modules` or `nyxos/defaults`.
- **Reproduce / verify:** `xdg-mime query default video/mp4` with Media Player and Theater installed.
- **Evidence:** Theater desktop entry `MimeType=video/mp4;…`
- **Affected versions:** `af518c0448`
- **User impact:** Double-clicking a video may open Theater, which is a server browser.
- **Recommended correction:** Fix the summary; drop MIME types from Theater or set NyxOS defaults to Media Player.
- **Effort:** S
- **Dependencies:** NYX-APP-THEATER-003
- **Verification criteria:** `xdg-mime query default video/mp4` returns Media Player.

### NYX-APP-MEDIA-PLAYER-003: TMDB API key kept in plain settings

- **Component:** nyx-media-player `apps/media-player/src/library/tmdb.rs:26`, `prefs.rs`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The user's TMDB key sits in `settings.toml`, while Theater keeps its tokens in the Secret Service. The key is low-value but personal.
- **Expected:** Consistent secret storage (Secret Service via nyx-core credentials helper).
- **Actual:** `tmdb.rs:26` reads `p.tmdb_key` from prefs.
- **Reproduce / verify:** `grep tmdb_key ~/.config/nyx-media-player/settings.toml`
- **Evidence:** as above
- **Affected versions:** `af518c0448`
- **User impact:** Key exposed through backups or shared configs.
- **Recommended correction:** Move it to `secret-tool` as Theater does.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** settings.toml has no key after migration.

### NYX-APP-MEDIA-PLAYER-004: Documentation describes an Omarchy app

- **Component:** `README.md:3-5`, `apps/media-player/Cargo.toml:4`, `src/main.rs:1`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** "A video player for Omarchy … takes its colors from your Omarchy theme"; install covers only curl.
- **Expected:** NyxOS-first docs.
- **Actual:** as cited.
- **Reproduce / verify:** `rg -n -i omarchy README.md apps`
- **Evidence:** as cited
- **Affected versions:** `af518c0448`
- **User impact:** Confusing docs.
- **Recommended correction:** Rewrite intro/install.
- **Effort:** S
- **Dependencies:** NYX-APP-MUSIC-001
- **Verification criteria:** No Omarchy-first wording.
