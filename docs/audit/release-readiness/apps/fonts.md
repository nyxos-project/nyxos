# Nyx Fonts scorecard

- **Repository:** design-nexus/nyx-fonts at `1571ea382d` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** not offered (packaged with `nyx.fonts.enable`, no catalog entry; `release-inventory.md` "Not offered to users")
- **Purpose:** browse, preview and install Google Fonts and Nerd Fonts per user; list system fonts
- **Stack:** Rust/GTK4, HTTP to fonts.google.com and GitHub, `tar`/`xz` for Nerd Font archives, fontconfig (`fc-list`, `fc-cache`), legacy nyx-core control
- **Binaries / services:** `nyx-fonts` (`nyx-packages/pkgs/nyx-fonts.nix`: runtime `fontconfig`, `gnutar`, `xz`; no `actions`); option `nyx.fonts.enable` (`modules/nixos/default.nix:15`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Catalog browse/filter/sort, live preview from cached single files, install/update/remove, system font list; no stubs |
| UX | 3 | Ctrl+K global search, Ctrl+F filter, F1 help; offline browsing from a daily cache |
| Accessibility | 2 | 13 tooltips, 2 explicit labels; one unnamed button flagged (`window.rs:88`) |
| Reliability | 3 | 0 unwraps, 2 expects outside tests; staged installs in a hidden folder (`install.rs:296`) |
| Integration | 2 | No action manifest; not reachable from Welcome/Store |
| Packaging | 3 | Pinned; fontconfig/tar/xz on PATH |
| Maintainability | 2 | 11 tests, check.yml CI; README Omarchy-first |

## Functionality

- Installation location: per user, `~/.local/share/fonts/nyx-fonts/<google|nerd|local>/<family>` (`apps/fonts/src/installed.rs:94-115`, `window.rs:704-731`), no root; `fc-cache -f` after changes (`install.rs:395`); records in `~/.local/state/nyx-fonts/installed.toml` (README). Older `nixe-fonts`/`nexus-fonts` folders are migrated (`installed.rs:124-141`). NixOS fontconfig includes the XDG fonts dir by default (static; confirm at runtime).
- Sources: Google Fonts `https://fonts.google.com/metadata/fonts` and `/download/list?family=` (`catalog/google.rs:10,113`), the web app's internal endpoints; Nerd Fonts from GitHub releases (`catalog/nerd.rs:8-10,83`). Licenses saved next to fonts (README).
- Archive extraction via GNU `tar` (`install.rs:335-351`), which strips absolute paths and `..` members by default.

## UX and accessibility (static)

- Keys: Ctrl+F, Ctrl+K, Esc, Ctrl+1–4, Alt+←, Ctrl+B, Ctrl+,, F1, Ctrl+Q (README).
- No hard-coded colours.

## Reliability

- Lists cached and refreshed daily; offline browsing works (README).
- Failed downloads leave nothing behind (`install.rs:296`).

## Integration and packaging

- Desktop entry `apps/fonts/data/io.github.design_nexus.nyx.Fonts.desktop` (Utility); icon in `crates/nyx-icons`.
- Control: legacy `control::serve` (`main.rs:70`), no manifest.
- Omarchy: gated theme default (`prefs.rs:38`), comment in `theme.rs:7`.

## Maintenance

- Tests: 11; CI `check.yml`, `release.yml`.
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`.
- Docs: README "A font manager for Omarchy" (`README.md:3`).

## Runtime results

- Smoke test (Fonts): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-FONTS-001: Packaged but not offered anywhere

- **Component:** `nyx-system/crates/nyx-catalog/catalog.toml` (no `nyx-fonts` item); `nyx-packages/modules/nixos/default.nix:15`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Fonts is built and has a NixOS option, but neither Welcome nor the Store lists it, so users can't find or install it.
- **Expected:** A catalog decision: Store tier, or drop the option until it's offered.
- **Actual:** no catalog entry (`release-inventory.md`, "Not offered to users").
- **Reproduce / verify:** `rg -n nyx-fonts nyx-system/crates/nyx-catalog/catalog.toml` (none)
- **Evidence:** as cited
- **Affected versions:** `1571ea382d`
- **User impact:** A finished app is invisible.
- **Recommended correction:** Add a Store-tier item (`nyx = ["fonts"]`).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Fonts appears in the Store.

### NYX-APP-FONTS-002: Google Fonts catalog relies on undocumented endpoints

- **Component:** nyx-fonts `apps/fonts/src/catalog/google.rs:10,105-113`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The catalog and downloads use fonts.google.com's internal JSON (with its `)]}'` prefix), not the public Developer API; a site change breaks browsing and installs. The daily cache softens it.
- **Expected:** Public API or a documented fallback (e.g. the google/fonts GitHub repository).
- **Actual:** as cited.
- **Reproduce / verify:** read the file
- **Evidence:** as cited
- **Affected versions:** `1571ea382d`
- **User impact:** Google Fonts may stop working until an update.
- **Recommended correction:** Add a fallback source; surface a clear error.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** With the metadata endpoint blocked, the app shows an error and the fallback works.

### NYX-APP-FONTS-003: No action manifest; README Omarchy-first

- **Component:** nyx-fonts `apps/fonts/src/main.rs:70`, `README.md:3-6`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Legacy control API (no installed manifest); README introduces it as an Omarchy app with curl install only.
- **Expected:** API 2 manifest; NyxOS docs.
- **Actual:** as cited.
- **Reproduce / verify:** `rg -n -i omarchy README.md`
- **Evidence:** as cited
- **Affected versions:** `1571ea382d`
- **User impact:** Minor.
- **Recommended correction:** Port to `serve_with`; update README.
- **Effort:** S
- **Dependencies:** NYX-APP-MEDIA-PLAYER-001
- **Verification criteria:** Manifest installed; README updated.
