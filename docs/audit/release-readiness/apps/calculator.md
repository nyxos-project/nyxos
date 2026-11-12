# Nyx Calculator scorecard

- **Repository:** design-nexus/nyx-calculator at `9912a37234` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (preselected; installed per user)
- **Purpose:** calculator with standard, scientific, programmer, converter, sheets and graphing modes
- **Stack:** Rust/GTK4, workspace crates `calculator-core`, `-graph`, `-storage` (rusqlite), `calculator-app`; nyx-core `4f05fb8`, nyx-design `cf39397`
- **Binaries / services:** `nyx-calculator` (`nyx-packages/pkgs/nyx-calculator.nix`); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Six modes implemented in separate crates; no stubs found |
| UX | 2 | Alt+1..6 modes, 46 key-handling sites; graph canvas hard-coded dark |
| Accessibility | 2 | 2 icon-only buttons, 12 tooltips; no explicit accessible labels |
| Reliability | 3 | Non-test `unwrap()`s are `Mutex::lock()` in storage only; no runtime-data panics found |
| Integration | 2 | Desktop entry and icon; no control interface, actions or Glimpse provider |
| Packaging | 2 | Recipe fine, but no LICENSE file in the repository while meta says MIT |
| Maintainability | 2 | 43 tests; only a release workflow (no check CI); README describes Omarchy |

## Functionality

Standard/scientific (exact decimals), programmer (radix, bit grid), unit converter, Numi-style
sheets with variables and Markdown export, graphing with derivatives/integrals/extrema
(`crates/calculator-graph/src/calculus.rs`). History and sheets persist in SQLite
(`crates/calculator-storage/src/lib.rs:32-49`, `calculator.db` in the data dir). "Currencies"
in sheets are symbols only; there are no exchange rates (`crates/calculator-core/src/natural.rs:12`).

## UX and accessibility (static)

Keyboard driven (`crates/calculator-app/src/keys.rs`). The graph view paints a fixed dark
background and white grid (`views/graph_view.rs:405-475`), so a light theme gets a dark
graph (NYX-APP-CALCULATOR-002). Other colours come from the theme.

## Reliability

19 non-test `unwrap()`: 13 are `self.conn.lock().unwrap()` (`calculator-storage/src/lib.rs:56-222`),
which only fail on a poisoned mutex; the rest are in test helpers inside `calculus.rs`.
No daemon.

## Integration and packaging

`data/io.github.design_nexus.nyx.Calculator.desktop` (`Exec=nyx-calculator %F`, no
MimeType), icon `data/icons/…Calculator.svg`. No Assistant control interface, no action
manifest, no Glimpse provider. No Omarchy calls; `ThemeMode::Omarchy` default
(`crates/calculator-app/src/prefs.rs:23`) means "follow the system theme".

## Maintenance

43 tests. CI: `release.yml` only; tests run in the nyx-packages build (`buildWorkspace`,
`checkType = "debug"`). No LICENSE file (`Cargo.toml:12` says MIT). README.md:3 says "for Omarchy".

## Runtime results

- Smoke test (Calculator): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 576 / 511 ms (two warm runs), RSS 131 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- Repaints live on a theme change (logs/theme-switch.txt); 32/32 buttons named; starts on a full disk.

## Findings

### NYX-APP-CALCULATOR-001: No LICENSE file although the package is declared MIT

- **Component:** nyx-calculator repository root; `nyx-packages/lib/default.nix`
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** verified
- **Description:** The repository has no license text; Cargo and the Nix meta (default MIT) declare MIT.
- **Expected:** Every distributed app carries its license text (MIT requires the notice to accompany copies).
- **Actual:** No `LICENSE*` in the checkout (inventory `has_license: false`); `Cargo.toml:12` `license = "MIT"`; `nyx-packages/lib/default.nix:188-190` defaults meta to MIT.
- **Reproduce / verify:** `git -C nyx-calculator ls-files | rg -i licen`
- **Evidence:** `nyx-calculator/Cargo.toml:12`, `evidence/inventory.json`
- **Affected versions:** 9912a37234
- **User impact:** Distribution without a license notice; legal ambiguity for redistributors.
- **Recommended correction:** Add the MIT LICENSE used by the other Nyx apps.
- **Effort:** S
- **Dependencies:** NYX-PKG licensing review
- **Verification criteria:** `LICENSE` present and installed or referenced by the package.

### NYX-APP-CALCULATOR-002: Graph view ignores the theme (always dark)

- **Component:** nyx-calculator `crates/calculator-app/src/views/graph_view.rs`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The graph canvas draws a fixed dark background with white grid and labels.
- **Expected:** Colours from the Nyx theme palette, as the rest of the window.
- **Actual:** `graph_view.rs:405` `set_source_rgb(0.09, 0.09, 0.13)`; white grid/labels at 413-475.
- **Reproduce / verify:** Switch to a light theme, open Graph (Alt+6) (static; confirm at runtime).
- **Evidence:** `nyx-calculator/crates/calculator-app/src/views/graph_view.rs:405-475`
- **Affected versions:** 9912a37234
- **User impact:** A dark rectangle inside a light window.
- **Recommended correction:** Read background/foreground from the theme tokens.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Graph follows light and dark themes.

### NYX-APP-CALCULATOR-003: No check CI; README describes Omarchy

- **Component:** nyx-calculator `.github/workflows`, `README.md`
- **Category:** CI
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Only `release.yml` exists; pushes aren't tested in the repository. README.md:3 targets Omarchy.
- **Expected:** `check.yml` like the other apps; NyxOS documented.
- **Actual:** inventory `workflows: ["release.yml"]`; README.md:3.
- **Reproduce / verify:** `ls nyx-calculator/.github/workflows`
- **Evidence:** `evidence/inventory.json`, `nyx-calculator/README.md:3`
- **Affected versions:** 9912a37234
- **User impact:** Regressions found only when nyx-packages builds.
- **Recommended correction:** Copy the suite's `check.yml`; add a NyxOS section to the README.
- **Effort:** S
- **Dependencies:** NYX-CI findings
- **Verification criteria:** Push runs fmt, clippy and tests.
