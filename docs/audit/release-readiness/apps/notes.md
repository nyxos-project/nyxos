# Nyx Notes scorecard

- **Repository:** design-nexus/nyx-notes at `7f96c37f89` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user)
- **Purpose:** Markdown workspace that opens plain folders and Obsidian vaults
- **Stack:** Rust/GTK4 + GtkSourceView 5; eight crates (vault, markdown, editor, ai, sync, plugins/WASM, glimpse, app); nyx-ai-client `8adb415`, nyx-cloud `072cb06`, nyx-core `4f05fb8` and `eabed78`
- **Binaries / services:** `nyx-notes`, `nyx-notes-glimpse` (plugin in `share/nyx-notes/glimpse`); action manifest `nyx-notes` (`nyx-packages/pkgs/nyx-notes.nix`); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Phases 1-5 implemented (editing, links, search, history, canvas, sync, extensions) |
| UX | 2 | Large keyboard map, recovery prompts; many features behind the File menu |
| Accessibility | 2 | 2 icon-only buttons, 16 tooltips, 0 explicit labels |
| Reliability | 3 | Version-checked saves, recovery drafts, journals for moves; 29 non-test `unwrap()` mostly invariants |
| Integration | 3 | Actions manifest, Glimpse plugin, AI Core client, Share, Capture |
| Packaging | 3 | GtkSourceView input, plugin and manifest installed |
| Maintainability | 2 | 34 Rust tests plus GTK checks; two nyx-core revisions; stale pins in PLAN.md |

## Functionality

Source/live/reading modes, wikilinks and backlinks, FTS5 search, templates, daily notes,
attachments, history snapshots, graph, collections, canvas, writing projects, optional AI,
WebDAV sync, WASM extensions (README "Available now"). Persistence: notes stay in the vault;
history, drafts and journals in `$XDG_STATE_HOME/nyx-notes`; search in `$XDG_CACHE_HOME`.

**Obsidian vault safety:** saves compare the loaded BLAKE3 digest and GIO etag, then
`replace_contents` with the etag (`crates/notes-vault/src/lib.rs:149-197`); conflicts stop
autosave. `.obsidian` is protected (`lib.rs:151-155`), symlinked notes are read-only
(`lib.rs:163-167`), copies use `persist_noclobber` (`lib.rs:200-212`), moves use journals
with fsync (`workspace.rs:328-332`). Close waits for pending saves and asks about
unsaved work (`crates/notes-app/src/window.rs:1008-1021, 2224-2260, 2387-2393`).

## UX and accessibility (static)

Ctrl+O/N/S, F2, F4, F11, Ctrl+Shift+F and more; F1 help. No `update_property` labels; tooltips
on icon buttons. No hard-coded colours.

## Reliability

`expect()`s only on spawning worker threads (`notes-app/src/worker.rs:19-152`). `unwrap()`s
on parents of vault paths and non-empty iterators (e.g. `canvas_ui.rs:1085-1089`, `notes-sync/src/lib.rs:362-374`).

## Integration and packaging

Desktop entry (`text/markdown`), icon. Manifest with `"activation": "running"`
(`notes-app/src/integrations_ui.rs:41`). Glimpse plugin must be enabled in Glimpse (README);
per-user linking gap as NYX-APP-MAIL-002. AI through `nyx-ai-client` (AI Core). No Omarchy
calls; theme default only.

## Maintenance

34 tests; `tools/check-gtk.py` GTK checks. CI: check + release. Pins: nyx-core `4f05fb8` plus
`eabed78` (via `crates/notes-sync/Cargo.toml:15`), nyx-ai `8adb415` (nyx-ai `main` is `d325462`).

## Runtime results

- Smoke test (Notes): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 573 / 26 ms (two warm runs), RSS 143 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- First run is a separate vault dialog with flat buttons and larger text than the suite (ux-accessibility.md); starts on a full disk.

## Findings

### NYX-APP-NOTES-001: Notes builds two nyx-core revisions and an older AI Core client

- **Component:** nyx-notes `Cargo.lock`, `crates/notes-sync/Cargo.toml`, `crates/notes-ai/Cargo.toml`
- **Category:** architecture
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** `nyx-sync` comes from nyx-core `eabed78` while the rest uses `4f05fb8`; `nyx-ai-client` is pinned at `8adb415` while AI Core ships `d325462`. Protocol changes in AI Core may not reach Notes.
- **Expected:** One nyx-core revision per app; AI client matching the shipped `nyx-aid`.
- **Actual:** `crates/notes-sync/Cargo.toml:15`; `crates/notes-ai/Cargo.toml:15`; `evidence/shared-crate-pins.txt`.
- **Reproduce / verify:** `rg -o 'nyx-(core|ai)\.git\?rev=\w{7}' nyx-notes/Cargo.lock | sort -u`
- **Evidence:** as above
- **Affected versions:** 7f96c37f89
- **User impact:** AI features may break silently after AI Core changes; larger build.
- **Recommended correction:** Re-pin nyx-sync to the app's nyx-core and nyx-ai-client to the shipped AI Core.
- **Effort:** S
- **Dependencies:** NYX-PKG-002 (shared pin drift)
- **Verification criteria:** One nyx-core and the current nyx-ai revision in Cargo.lock; AI writing works on NyxOS.

### NYX-APP-NOTES-002: PLAN.md and README carry stale pins and Arch instructions

- **Component:** nyx-notes `PLAN.md`, `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** PLAN.md:22 says nyx-core `7cd0be5` and nyx-design `609c1d2`; README's build section names Arch packages and a PKGBUILD, and "automatic Omarchy theme following".
- **Expected:** Current pins and NyxOS install.
- **Actual:** as cited.
- **Reproduce / verify:** `rg -n 'pinned to|Arch|Omarchy' nyx-notes/PLAN.md nyx-notes/README.md`
- **Evidence:** `nyx-notes/PLAN.md:22`
- **Affected versions:** 7f96c37f89
- **User impact:** Maintainer confusion.
- **Recommended correction:** Update or drop pin details.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Docs match Cargo.lock.
