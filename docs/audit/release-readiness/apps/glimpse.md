# Nyx Glimpse scorecard (app and backend)

The Quickshell panel's architecture is covered by the shell report; this card covers the
Rust side: search, providers, index, plugins and services.

- **Repository:** design-nexus/nyx-glimpse at `deecabf729` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** base (`nyx.glimpse.enable`)
- **Purpose:** launcher and local universal search over apps, files, settings, actions, passwords and plugins; meaning-based search through Nyx AI Core
- **Stack:** Rust/GTK4 (GTK panel and settings) plus `nyx-glimpse-backend` serving the Quickshell panel; SQLite FTS index; bubblewrap plugin sandbox; nyx-actions manifests; nyx-ai-client (EmbeddingGemma 2 in AI Core)
- **Binaries / services:** `nyx-glimpse`, `nyx-glimpse-backend`, `nyx-glimpsed`, `nyx-glimpse-settings`; user units `nyx-glimpse-backend.service` (autostart `graphical-session.target`) and `nyx-glimpsed.service` (generated in `postInstall`, not autostarted); panel in `share/nyx-shell/components/nyx-glimpse` (`nyx-packages/pkgs/nyx-glimpse.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Apps, files, commands, actions, calculator/currency, passwords, clips, PIM, plugins, semantic search implemented |
| UX | 2 | Panel and GTK fallback; file search opt-in by folder; Omarchy menu provider and CLI verb remain |
| Accessibility | n/v | Backend has no UI of its own; the GTK fallback has 10 tooltips for 2 icon-button sites; panel covered elsewhere |
| Reliability | 2 | Backend restarts on failure; ~19 mutex `lock().unwrap()`s in `backend.rs` and one `unwrap()` on search-hit JSON |
| Integration | 3 | Reads `share/nyx/actions`, AI Core, Nyx Passwords, packaged units preferred over generated ones |
| Packaging | 2 | Index unit generated in the package; integration tests excluded because they include an old monorepo file |
| Maintainability | 2 | 78 tests (lib and bins; 3 skipped in the sandbox); docs on providers and performance |

## Functionality

- Providers registered in `apps/glimpse/src/backend.rs:425` and `ui.rs:399`; action manifests through `nyx_actions` (`commands.rs`, `providers.rs`).
- **Files.** The index has no folders until the user adds some (`config.rs:56-58`) and skips hidden, generated and secret-looking names (`config.rs:250-263`); `nyx-glimpsed` runs only after `nyx-glimpse service enable`, which uses the packaged unit when present instead of writing one with a store path (`integration.rs:117-137`).
- **Semantic search** through AI Core (`aicore.rs:1-4`); Glimpse keeps its own index and ranking (`semantic.rs`).
- **Passwords.** A query starting with `pw`/`password` goes only to the vault, never to other providers, plugins or semantic search (`passwords.rs:1-3`).
- **Plugins** run under bubblewrap with `/nix/store` and `/run/current-system` bound on NixOS (`plugins.rs:356-363`), install from a catalog at a pinned revision, and need permission approval to enable (`cli.rs:18`).
- Omarchy's menu is searchable data only when Omarchy's files exist (`omarchy.rs:1,41-47`); empty on NyxOS. The CLI still lists `omarchy-actions` (`cli.rs:18`).

## UX and accessibility (static)

- `--toggle` goes to the Quickshell panel while the backend runs, to the GTK panel otherwise (`pkgs/nyx-glimpse.nix:42-44`).
- No hard-coded colours in Rust.

## Reliability

- 56 `unwrap()` outside tests by rough count: 14 in `examples/benchmark-providers.rs`, 19 in `backend.rs` (mostly `Mutex::lock().unwrap()`, `backend.rs:790-1246`), 9 in `aicore.rs`. `semantic.rs:264` unwraps `hit["path"].as_str()` on a search hit (NYX-APP-GLIMPSE-001).
- `nyx-glimpse-backend.service`: `Restart=on-failure`, `RestartSec=2`, `UMask=0077`, `ConditionEnvironment=WAYLAND_DISPLAY` (`apps/glimpse/data/nyx-glimpse-backend.service`). Index unit `Restart=on-failure`, `Nice=10` (`pkgs/nyx-glimpse.nix:51-66`).
- nyx-packages removes the old `~/.local/share/nyx-glimpse/runtime` link at sign-in (`modules/nixos/default.nix:416-421`).

## Integration and packaging

- Pins: nyx-core `4f05fb8` (main `9187295`), nyx-design `cf39397`, nyx-ai `9633690` (main `d325462`), nyx-passwords `271eac9` (main `7a090fa`).
- Glimpse plugin providers of other apps come from `share/nyx-<app>/glimpse` linked into the system profile (`modules/nixos/default.nix:285-288`).

## Maintenance

- Package tests: `-p nyx-glimpse --lib --bins`; three tests skipped because the index ignores `/build` (`pkgs/nyx-glimpse.nix:21-35`); `tests/core.rs` isn't run because it includes a file from the old monorepo's Settings.
- Docs: `docs/PROVIDERS.md`, `PERFORMANCE.md`, `GLIMPSE_AUDIT.md`; README 255 lines (7 Omarchy mentions, 1 NyxOS).

## Runtime results

- Smoke test (Glimpse): dock launch **overlay**, Glimpse/GIO launch **overlay** (evidence/smoke-dock, smoke-glimpse).
- Opens as an overlay from the dock and via GIO; Escape closes it. Can't open while Shell Core is down; the first toggle 2 s after Shell Core returns does nothing (logs/shell-core-loss.txt). Opens on a hot-plugged monitor when focused.

## Findings

### NYX-APP-GLIMPSE-001: A search hit without a path panics the search

- **Component:** nyx-glimpse `apps/glimpse/src/semantic.rs:264`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Fusing semantic hits calls `hit["path"].as_str().unwrap()`; a hit without a string `path` panics the thread doing the search (the backend restarts on failure, the GTK panel would close).
- **Expected:** Malformed hits are skipped.
- **Actual:** see Component.
- **Reproduce / verify:** Unit test feeding a hit with no `path` (static).
- **Evidence:** as above.
- **Affected versions:** `deecabf729`
- **User impact:** Unlikely; a crash and restart of search if it happens.
- **Recommended correction:** `filter_map` hits with a path.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The test passes without a panic.

### NYX-APP-GLIMPSE-002: Integration tests are excluded from the package build

- **Component:** nyx-glimpse `apps/glimpse/tests/core.rs`; nyx-packages `pkgs/nyx-glimpse.nix:28-35`
- **Category:** CI
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `tests/core.rs` still includes a file from the old monorepo's Settings, so the package runs only library and binary tests.
- **Expected:** All of Glimpse's tests run where it's built.
- **Actual:** `cargoTestFlags = [ "-p" "nyx-glimpse" "--lib" "--bins" ]`.
- **Reproduce / verify:** Read the package comment.
- **Evidence:** as above.
- **Affected versions:** `deecabf729`
- **User impact:** None directly; less coverage.
- **Recommended correction:** Vendor or drop the included file and run `cargo test -p nyx-glimpse`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The package runs `tests/core.rs`.
