# Nyx Torrents scorecard

- **Repository:** design-nexus/nyx-torrents at `ab13d7b780` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("Download torrents.")
- **Purpose:** BitTorrent client on libtorrent 2.x with magnets, categories, scheduling, search plugins and VPN interface binding
- **Stack:** Rust/GTK4, C++ shim over libtorrent-rasterbar via cxx (`build.rs`), qBittorrent nova3-format Python search plugins, legacy nyx-core control
- **Binaries / services:** `nyx-torrents` (`nyx-packages/pkgs/nyx-torrents.nix`: `libtorrent-rasterbar`, `boost`, `openssl`; runtime `python3`, `curl`, `xdg-utils`, `libnotify`; no `actions`); option `nyx.torrents.enable` (`modules/nixos/default.nix:36`); no firewall configuration

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Torrents, magnets, queue, categories/tags, limits and schedule, seeding limits, completion actions, search, VPN binding; no stubs |
| UX | 2 | Clear sections and shortcuts; no first-run explanation of ports/UPnP; plugin install has no trust warning |
| Accessibility | 2 | 21 tooltips on 11 icon sites; 0 explicit accessible labels |
| Reliability | 3 | 0 unwraps, 8 expects outside tests; fast-resume and DHT state kept |
| Integration | 2 | `.torrent`/magnet MIME and desktop actions; no action manifest; no firewall integration |
| Packaging | 3 | Pinned; python3 and curl on PATH |
| Maintainability | 2 | 17 tests (lowest in this group); check.yml CI; README Omarchy-oriented |

## Functionality

- Network defaults (`apps/torrents/src/prefs.rs:137-164,186-195`): random listening port picked on first run and kept; UPnP and NAT-PMP on; DHT, LSD on; listens on `0.0.0.0:<port>,[::]:<port>` or `<interface>:<port>` when bound to a VPN (`engine/settings.rs:61-79`).
- Firewall: NyxOS enables the firewall (`nyxos/modules/nixos/network.nix:6`); nothing opens the torrent port, so unsolicited inbound peers are dropped locally even when UPnP maps the router.
- Search: plugins are user-installed Python scripts run with `python3` (`search.rs:74-77,207,288`); install from file or URL via `curl` to the temp dir, accepted if the text contains `def search` (`sections/search.rs:239-276`, `search.rs:130-141`); import from qBittorrent.
- Legal neutrality: no plugins or sites are bundled (only `runner.py`, `helpers.py`, `novaprinter.py` under `apps/torrents/search/`); examples use Ubuntu; README points to the qBittorrent plugin wiki. Neutral.
- Persistence: `~/.config/torrents/settings.toml`, `categories.toml`; session in `~/.local/share/torrents/` (README).

## UX and accessibility (static)

- Keys: Ctrl+O, Ctrl+U, Ctrl+F, F1, Space, Delete, Ctrl+C, Ctrl+Q (README).
- "Keep running when closed" off by default; closing quits.
- Colours: `graph.rs` two literals for the speed graph.

## Reliability

- Engine runs in a background thread over a channel; resume data saved on quit (`engine/mod.rs:3`).

## Integration and packaging

- Desktop entry `apps/torrents/data/io.github.design_nexus.nyx.Torrents.desktop`: `MimeType=application/x-bittorrent;x-scheme-handler/magnet;`, `Actions=search;speed;`.
- Control: legacy `control::serve` (`main.rs:53`), no manifest.
- Omarchy: gated theme default; `sections/search.rs:385` suggests `sudo pacman -S python`, unreachable on NyxOS because python3 is on the wrapper PATH; `build.rs:7` message mentions pacman (build-time only).

## Maintenance

- Tests: 17; CI `check.yml`, `release.yml`.
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`.
- Docs: README "A BitTorrent client for Omarchy" (`README.md:3`).

## Runtime results

- Smoke test (Torrents): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-TORRENTS-001: Search plugins run arbitrary Python from any URL without a warning

- **Component:** nyx-torrents `apps/torrents/src/sections/search.rs:239-276`, `src/search.rs:130-141,207,288`
- **Category:** security
- **Severity:** P2
- **Status of feature:** verified
- **Description:** "Install from a link" downloads a `.py` file with curl to `std::env::temp_dir()/<name from URL>` and installs it if it contains `def search`; every search then runs it as the user with full access to their files. The dialog says only "A link to a plugin's .py file". This matches qBittorrent's model but NyxOS offers the app in Welcome.
- **Expected:** A clear warning that plugins are programs with full access; ideally sandboxing (bubblewrap with network only) and HTTPS-only links.
- **Actual:** as cited; temp path is predictable in shared `/tmp`.
- **Reproduce / verify:** Search → Install from a link (static; confirm wording at runtime).
- **Evidence:** as cited
- **Affected versions:** `ab13d7b780`
- **User impact:** A malicious plugin compromises the user account.
- **Recommended correction:** Add the warning and require HTTPS; download into a private temp dir; consider running plugins under bubblewrap.
- **Effort:** S (warning) / M (sandbox)
- **Dependencies:** NYX-SEC
- **Verification criteria:** Warning shown; plugin process can't read `~/.ssh` in a test.

### NYX-APP-TORRENTS-002: Listening port blocked by the NyxOS firewall; UPnP on by default

- **Component:** nyx-torrents `apps/torrents/src/prefs.rs:137-138,186-195`; nyxos `modules/nixos/network.nix:6`; nyx-packages `modules/nixos/default.nix` (no `torrents` firewall rule)
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The random port isn't opened in the host firewall, so inbound peers are dropped (outgoing connections still download). Meanwhile UPnP/NAT-PMP open the port on the router without asking.
- **Expected:** Either open the chosen port (e.g. a firewall override through the System Manager when the user agrees) or explain reduced connectivity; UPnP choice surfaced on first run.
- **Actual:** no firewall handling anywhere in the app or module.
- **Reproduce / verify:** On NyxOS, check incoming connections in the peers list / a port test (static; confirm at runtime).
- **Evidence:** as cited
- **Affected versions:** `ab13d7b780`
- **User impact:** Slower torrents and poor seeding; router ports opened silently.
- **Recommended correction:** Offer "Allow incoming connections" that adds the port via NyxOS firewall overrides (`nyxos/modules/nixos/overrides.nix:186-189`); show the UPnP state in settings on first run.
- **Effort:** M
- **Dependencies:** NYX-SET (firewall overrides)
- **Verification criteria:** Incoming peers appear after allowing; setting is visible.

### NYX-APP-TORRENTS-003: No action manifest; docs and hints are Omarchy/Arch-oriented

- **Component:** nyx-torrents `apps/torrents/src/main.rs:1,53`, `README.md:3`, `sections/search.rs:385`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Legacy control API means no installed manifest (Assistant/Glimpse reach it only while running); README and source say "for Omarchy"; a pacman hint remains in UI text (unreachable on NyxOS).
- **Expected:** API 2 manifest; NyxOS-first docs.
- **Actual:** as cited.
- **Reproduce / verify:** `rg -n -i "omarchy|pacman" README.md apps`
- **Evidence:** as cited
- **Affected versions:** `ab13d7b780`
- **User impact:** Minor.
- **Recommended correction:** Port to `serve_with`; update docs and the hint.
- **Effort:** S
- **Dependencies:** NYX-APP-MEDIA-PLAYER-001
- **Verification criteria:** Manifest installed; no Omarchy/pacman text.
