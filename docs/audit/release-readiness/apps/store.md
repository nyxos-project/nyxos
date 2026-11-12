# Nyx Store scorecard

- **Repository:** design-nexus/nyx-store at `fc2bdca66f` (pinned in nyx-packages: yes, 0 behind origin/main)
- **Release tier:** base (`nyx.store.enable`; the module turns on `services.flatpak` and a portal)
- **Purpose:** install and remove software from the NyxOS catalog, nixpkgs and Flathub; run updates and rollback
- **Stack:** Rust/GTK4; on NixOS it shells out to `nyx-system` (System Manager CLI), `nix profile` and `flatpak`; still links libalpm
- **Binaries / services:** `nyx-store` (the pacman helper `nyx-store-helper` is deleted in `postInstall`), desktop entry and icon (`nyx-packages/pkgs/nyx-store.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Catalog, nixpkgs and Flathub install/remove, update and rollback implemented on NixOS; no actions manifest |
| UX | 2 | Plan review before every change, consent notes, Ctrl+F/B/R/Esc; Omarchy wording in entry and some views |
| Accessibility | 2 | 3 icon buttons, 8 tooltips, 1 accessible label; small surface |
| Reliability | 2 | Errors carry the tool's last stderr line; multi-stage applies can stop half done without saying so |
| Integration | 2 | System Manager, Nix profile, Flathub; trust of profile apps through the module; no D-Bus or actions |
| Packaging | 2 | Helper removed, but libalpm (`nyx.pacman_7_1`) still linked for code NyxOS never runs |
| Maintainability | 2 | 18 tests; README describes only the Omarchy/pacman Store |

## Functionality

- NixOS detection: `apps/store/src/nix.rs:94-96` (`/etc/NIXOS`). Repositories page and AUR search are swapped out there (`window.rs:356,502-503`).
- **Install path.** `nix.rs:490-543`: catalog items go to the System Manager (for everyone), the user's Nix profile or Flathub, per item; nixpkgs packages go to the profile, except unfree ones, which go to the system with their licence accepted (`:518-534`). Apply runs `nyx-system apply -` with JSON on stdin, then Flatpak, then `nix profile` (`nix.rs:694-716`). Updates run `nyx-system update --yes --json` and report each failed part (`:651-692`); rollback runs `nyx-system rollback` (`:695-697`).
- Removal refuses base-tier catalog items (`nix.rs:550`).
- **Error reporting.** Each step forwards stdout/stderr lines as status and fails with the last stderr line (`nix.rs:614-646`); the window shows it through `operation_error` (`window.rs:1747-1753`). A failure after the System Manager step (Flathub, Nix profile) returns only that step's error, with the system change already switched to (NYX-APP-STORE-002).
- Persistence: prefs through `nyx_core::prefs_store!` (`prefs.rs:28`); catalog cache passed to `nix::load` (`nix.rs:232`).

## UX and accessibility (static)

- Keyboard: Ctrl+F search, Ctrl+B sidebar, Ctrl+R refresh, Esc (`window.rs:387-395`).
- The plan is shown and confirmed before anything runs (`nix.rs:719-727`); unfree licences listed as notes (`:529-531`).
- Omarchy wording visible on NyxOS: desktop entry `Comment=Discover and manage apps for Omarchy`, `Keywords=…Arch;AUR;Omarchy;` (`apps/store/data/io.github.design_nexus.nyx.Store.desktop:4,9`); sources text is NyxOS-aware (`window.rs:689`).
- No hard-coded colours found.

## Reliability

- 13 `unwrap()` outside tests: piped child handles (`nix.rs:626,634,661,668`, `transaction.rs:298-307`), the UI singleton (`window.rs:89`), `gdk::Display::default()` (`window.rs:2122`). None on network data.
- Offline: Flathub appstream refresh and `nyx-system update --dry-run` fail with the command's message (`nix.rs:121-127`).

## Integration and packaging

- No Omarchy command runs on NyxOS: the remaining Omarchy references are pacman-path code (`repositories.rs`, `transaction.rs`, `blackarch.rs`) reached only when `nix::active()` is false.
- Profile apps' user units and trust come from nyx-packages' `nyx-profile-units` generator and `nyx-trust-apps` (`modules/nixos/default.nix:87-127,485-495`).
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`; two nyx-system revisions in `Cargo.lock` (`8514a6d`, `f68ecc8`; main `6f0c47c`).

## Maintenance

- 18 tests (`search.rs` 5, `nix.rs` 4, others 1-2). No test exercises `apply` or partial failure.
- README is Omarchy-only ("A native software store for Omarchy"; pacman sources, BlackArch) and doesn't describe the NyxOS sources.

## Runtime results

- Smoke test (Store): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 453 / 501 ms (two warm runs), RSS 210 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- Offline, the header shows the raw Flathub resolver error (NYX-UX-002). 4 of 60 buttons unnamed (NYX-A11Y-003).

## Findings

### NYX-APP-STORE-001: Store's launcher entry and README describe the Omarchy/Arch store

- **Component:** nyx-store `apps/store/data/io.github.design_nexus.nyx.Store.desktop`, `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** On NyxOS the launcher says "Discover and manage apps for Omarchy" and searching "AUR" or "Arch" finds the Store; the README documents only pacman, AUR and BlackArch.
- **Expected:** NyxOS wording for the NyxOS catalog, nixpkgs and Flathub (nyx-packages `pkgs/nyx-store.nix:1-3`).
- **Actual:** desktop entry lines 4 and 9; README lines 1-5.
- **Reproduce / verify:** Read the files; search the launcher for "Store".
- **Evidence:** source references above.
- **Affected versions:** `fc2bdca66f`
- **User impact:** Confusing description of a base app.
- **Recommended correction:** Platform-neutral Comment and Keywords, and a NyxOS section in the README.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The installed desktop entry has no Omarchy/Arch wording.

### NYX-APP-STORE-002: A failed Flathub or Nix profile step after a system change doesn't say the system part was applied

- **Component:** nyx-store `apps/store/src/nix.rs:694-716`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** A catalog selection can need a system change, Flathub installs and Nix profile installs. They run in sequence and stop at the first error, whose message is all the user sees.
- **Expected:** The result says what was applied and what wasn't (as `update()` does at `nix.rs:678-683`).
- **Actual:** `apply()` returns `Err` from `nyx_catalog::flatpak` or `nix_profile` after `nyx-system apply` succeeded.
- **Reproduce / verify:** Install a catalog preset needing a system service and a Flathub app with the network down after the rebuild (static; confirm at runtime).
- **Evidence:** `nix.rs:702-711`.
- **Affected versions:** `fc2bdca66f`
- **User impact:** Unclear state after a partial install; a retry recomputes the plan, so nothing is lost.
- **Recommended correction:** Report per-stage outcomes like `update()`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A forced Flathub failure shows "System changes applied; Flathub failed: …".
