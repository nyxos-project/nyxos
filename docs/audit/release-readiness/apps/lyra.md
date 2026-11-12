# Nyx Lyra scorecard

- **Repository:** design-nexus/nyx-lyra at `c786ddc55d` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("YouTube Music, with your library and playlists.")
- **Purpose:** native GTK window over YouTube Music's own web player, running hidden in WebKitGTK 6
- **Stack:** Rust/GTK4, webkit6 0.6.1 (WebKitGTK 6.0), GStreamer, injected bridge script (`crates/nyx-lyra-core`), zbus MPRIS server `org.mpris.MediaPlayer2.lyra`, nyx-actions
- **Binaries / services:** `nyx-lyra` (`nyx-packages/pkgs/nyx-lyra.nix`: `cargoBuildFlags = -p nyx-lyra` so the `apps/probe` tool is not shipped; `webkitgtk_6_0`, `glib-networking`, GStreamer base/good/bad/libav; `actions = [ "nyx-lyra" ]`); option `nyx.lyra.enable` (`modules/nixos/default.nix:24`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Home/Explore/Search/library/artist/album/playlist/now playing work from YouTube Music data; no playlist editor or queue reordering (`docs/mockup-parity.md`); README says "In progress" |
| UX | 2 | Matches the mockups closely; Offline/"Reconnecting…" states exist; sign-in is Google's page in the window |
| Accessibility | 2 | 14 tooltips on 12 icon sites, 0 explicit accessible labels; rows carry text children |
| Reliability | 2 | No runtime unwraps (all 24 hits are in `parse/tests.rs`/test modules); depends on undocumented endpoints; heavy WebKit memory |
| Integration | 3 | MPRIS, actions manifest, D-Bus activation, Glimpse `lyra` panel, notifications |
| Packaging | 2 | Packaged and pinned; no CI workflow at all |
| Maintainability | 1 | 12 commits, 31 tests, no CI; good phase docs; app is two days old |

## Functionality

- Data comes from the signed-in page's own requests to `/youtubei/v1/search|browse|next` (`crates/nyx-lyra-core/src/youtube/mod.rs:1-4`: "These are not a public API"); playback is the hidden web player's.
- Writes it makes: create playlist, subscribe/unsubscribe through requests; likes and transport through the page's controls (`youtube/mod.rs:36-40`).
- Signed out, YouTube Music won't play (`docs/phase1-feasibility.md:39`); Lyra needs a Google account.
- Persistence: settings `~/.config/nyx-lyra/settings.toml`; metadata cache SQLite; web session (cookies, site data) in a persistent WebKit `NetworkSession` under the data dir, folder `0700`, cookies in `cookies.sqlite` (`apps/lyra/src/runtime/webkit.rs:49-57`).
- Left out: queue reordering, playlist editing, "keep playing when closed" (`docs/mockup-parity.md`).

## UX and accessibility (static)

- Navigation only to YouTube Music and Google sign-in hosts; other links open in the browser; popups and permission requests are denied (`webkit.rs:18-45`, `113-141`).
- beforeunload dialogs auto-confirmed because the page is never visible (`webkit.rs:130-138`).
- No explicit accessible labels; queue/track rows are buttons with label children (`ui/column.rs:222-300`), which is fine.
- No hard-coded colours in Rust or CSS.

## Reliability

- Crashed web process reloads after 2 s (`docs/phase1-feasibility.md:29`).
- Hidden-page throttling is turned off by WebKit feature IDs; if WebKit renames them, Lyra logs and playback may stall between songs (`webkit.rs:70-84`).
- Memory per its own measurements: 777 MB idle signed in, 1.9 GB and 56 processes after sign-in and navigation (`docs/phase1-feasibility.md:63,72`); page cache since disabled (`webkit.rs:67-68`).

## Integration and packaging

- Desktop entry `apps/lyra/data/io.github.design_nexus.nyx.Lyra.desktop` (no MIME, `DBusActivatable=false`); icon in `crates/nyx-icons`.
- WebKit publishes its own `org.mpris.MediaPlayer2.<id>.Sandboxed.instance-N`; the bridge hides page metadata so only Lyra's player shows (`docs/phase5-integration.md:48`).
- Omarchy: only `ThemeMode::Omarchy` default (gated) and unused `install.sh` code.

## Maintenance

- Tests: 31; no `.github/workflows` directory.
- Pins: nyx-core `9187295` (= origin/main), nyx-design `8b41fb1` (most apps use `cf39397`; origin/main `e311c2f`).
- Docs: README plus six phase documents, current as of 11 Nov 2026.

## Runtime results

- Smoke test (Lyra): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 798 / 771 ms (two warm runs), RSS 235 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- Content area is YouTube Music's own web page (shots via smoke-dock).

## Findings

### NYX-APP-LYRA-001: Built on YouTube Music's private web API and a hidden web player

- **Component:** nyx-lyra `crates/nyx-lyra-core/src/youtube/mod.rs:1-4`, `apps/lyra/src/runtime/webkit.rs`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** All browsing data comes from undocumented `youtubei/v1` endpoints, parsed from Google's internal JSON, and playback runs in a page the user never sees. Google can change either at any time, and driving the service through an invisible, scripted page is the kind of automated access YouTube's terms restrict. NyxOS offers this app in Welcome.
- **Expected:** Welcome-tier apps rely on supported interfaces, or are clearly labelled unofficial with a documented breakage policy (release decision).
- **Actual:** `youtube/mod.rs:1-4`; constants such as `FEmusic_home` (`mod.rs:16-26`); the bridge injected at document start (`webkit.rs:86-94`).
- **Reproduce / verify:** Static. At runtime, any YouTube Music front-end change shows up as parse errors on screen (the code never guesses).
- **Evidence:** `docs/phase2-core.md:17` ("unofficial (works through YouTube Music's own requests)")
- **Affected versions:** `c786ddc55d`
- **User impact:** Pages or playback can break without warning; there's a theoretical account-level risk.
- **Recommended correction:** Decide whether Lyra ships in Welcome or Store-only with an "unofficial" label; add a fixture-based CI check and a quick update path for parser fixes.
- **Effort:** S (decision) / M (CI fixtures)
- **Dependencies:** NYX-APP-LYRA-002
- **Verification criteria:** Catalog entry and app About show the unofficial status; CI runs the parser fixtures.

### NYX-APP-LYRA-002: No CI for a Welcome-tier app marked "In progress"

- **Component:** nyx-lyra repository root (no `.github/workflows`), `README.md:6`
- **Category:** CI
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Lyra has no workflows (every other app in this group has `check.yml`), 12 commits, and its README says "In progress".
- **Expected:** Same CI as the other apps (`check.yml`: build, tests, clippy) before it's offered in Welcome.
- **Actual:** `evidence/inventory.json` `"workflows": []` for nyx-lyra.
- **Reproduce / verify:** `ls nyx-lyra/.github` (missing)
- **Evidence:** inventory.json; `README.md:6`
- **Affected versions:** `c786ddc55d`
- **User impact:** Regressions reach users unnoticed.
- **Recommended correction:** Copy nyx-music's `check.yml`/`tools/ci.py`; drop "In progress" once it passes.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A green check run on main.

### NYX-APP-LYRA-003: High memory use from the embedded web player

- **Component:** nyx-lyra `apps/lyra/src/runtime/webkit.rs`
- **Category:** performance
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The project's own probe measured 777 MB idle signed in and 1.9 GB with 56 processes after sign-in and navigation. Page cache has been disabled since, but it hasn't been re-measured on NyxOS.
- **Expected:** A music app stays well under 1 GB in steady state.
- **Actual:** `docs/phase1-feasibility.md:63,72`; `webkit.rs:67-68`.
- **Reproduce / verify:** Phase D/F: measure PSS of `nyx-lyra` and its WebKit children after sign-in and 30 min playback.
- **Evidence:** as above (project measurements, not this audit's)
- **Affected versions:** `c786ddc55d`
- **User impact:** Noticeable RAM pressure on 8 GB machines.
- **Recommended correction:** Re-measure; limit process count (single web process, `WebsiteDataManager` cleanup after sign-in).
- **Effort:** M
- **Dependencies:** NYX-PERF
- **Verification criteria:** Steady-state memory recorded in Runtime results within the agreed budget.

### NYX-APP-LYRA-004: Google session cookies are stored unencrypted

- **Component:** nyx-lyra `apps/lyra/src/runtime/webkit.rs:49-57`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The YouTube/Google session lives in WebKit's `cookies.sqlite` and site data in a `0700` folder, unencrypted, as in any browser profile. This is documented (`docs/phase0-audit.md`, "Account and secrets"). Lyra itself stores no credentials and doesn't use Online Accounts.
- **Expected:** Documented to users; included in Backup exclusions or warnings if Backup copies `~/.local/share`.
- **Actual:** as described.
- **Reproduce / verify:** `ls -l ~/.local/share/nyx-lyra/web` after sign-in.
- **Evidence:** `webkit.rs:49-57`
- **Affected versions:** `c786ddc55d`
- **User impact:** Anyone with the user's files gets a signed-in Google web session.
- **Recommended correction:** Mention it in Settings → Account; consider excluding it from backups.
- **Effort:** S
- **Dependencies:** nyx-backup exclusions
- **Verification criteria:** User-visible note; backup policy decided.
