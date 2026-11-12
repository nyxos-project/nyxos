# Nyx Notepad scorecard

- **Repository:** design-nexus/nyx-notepad at `a5c720a2b4` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (preselected; `standaloneApps = "per-user"` puts it in the person's Nix profile)
- **Purpose:** tabbed plain-text editor
- **Stack:** Rust/GTK4 (`nyx-ui`/`nyx-theme` at nyx-design `cf39397`, `nyx-core` at `4f05fb8`); no daemon, no D-Bus name of its own
- **Binaries / services:** `nyx-notepad` (`nyx-packages/pkgs/nyx-notepad.nix`, plain `buildApp`); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Tabs, find/replace, session restore, file watching all implemented; no stubs found |
| UX | 2 | F1 shortcut sheet, toasts with Undo; closing a dirty tab drops it without asking (by design) |
| Accessibility | 2 | 3 icon-only buttons, all with tooltips; no explicit accessible labels (shared `nyx-ui` pattern) |
| Reliability | 3 | 0 `unwrap()`/`expect()` in non-test code; atomic saves; unsaved text kept in scratch files |
| Integration | 2 | Desktop entry, icon, `text/plain` MIME; Assistant control tools but no action manifest installed |
| Packaging | 3 | Minimal recipe; desktop entry and icon installed by `buildApp` |
| Maintainability | 2 | 9 tests for 2.9k lines; README still describes Omarchy and a pacman install |

## Functionality

- Implemented: tabs, open/save/save-as (`apps/notepad/src/doc.rs:500-570`), find and replace,
  formatting settings, recent files, drag-and-drop, external-change reload
  (`doc.rs:605-631`), control tools for the Assistant (`control.rs`).
- Persistence: settings `~/.config/nyx-notepad/settings.toml`; session and unsaved text in
  `~/.local/share/nyx-notepad/` (`session.rs:1-3`), written ~1 s after a change and on
  close/shutdown (`window.rs:109-112`, `main.rs:87-89`). Closing the window never prompts:
  unsaved text comes back next launch (documented, README.md:10).
- Saves use `nyx_core::cmd::atomic_write` (temp file, fsync, rename, keeps permissions;
  nyx-core `4f05fb8` `crates/nyx-core/src/cmd.rs:132-156`).
- Gap: non-UTF-8 files open lossily and save the replacement characters (NYX-APP-NOTEPAD-001).

## UX and accessibility (static)

Keyboard-first (Ctrl+F/H, Ctrl+Shift+T, Ctrl+±, F1 help). Empty state is an Untitled tab.
Tooltips on the File menu, tab close buttons and tab names (`window.rs:258-261, 374-388`);
no `update_property(Label)` calls. No hard-coded colours in Rust or CSS.

## Reliability

No panics on runtime data found. Files over 24 MiB and binaries are refused with a reason
(`doc.rs:13, 216-237`). A crash loses at most ~1 s of typing (debounced session save,
`session.rs:94-103`).

## Integration and packaging

`io.github.design_nexus.nyx.Notepad.desktop` (`MimeType=text/plain`, `DBusActivatable=false`),
scalable icon. No Glimpse provider, no Share. Control interface exists, but the package
installs no action manifest (`pkgs/nyx-notepad.nix` has no `actions`). Omarchy references
are only the `ThemeMode::Omarchy` default (`prefs.rs:44`), which in nyx-theme means "follow
the system theme", and the curl `install.sh` (not used by Nix).

## Maintenance

9 tests (inventory). CI: `check.yml`, `release.yml`. Pins: nyx-core `4f05fb8`, nyx-design
`cf39397` (the common app pins). README.md:3 and the Install section describe Omarchy and pacman.

## Runtime results

- Smoke test (Notepad): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 567 / 512 ms (two warm runs), RSS 133 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- 8/8 buttons named; starts on a full disk (logs/disk-full.txt).

## Findings

### NYX-APP-NOTEPAD-001: Saving a non-UTF-8 file replaces its non-ASCII bytes for good

- **Component:** nyx-notepad `apps/notepad/src/doc.rs`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** A Latin-1/Windows-1252 file is decoded with `from_utf8_lossy`; a toast warns once, then any save writes U+FFFD in place of the original bytes.
- **Expected:** Save refuses, asks, or keeps the original encoding when the text was decoded lossily.
- **Actual:** `doc.rs:231-234` decodes lossily; `doc.rs:357-361` only toasts; `write()` at `doc.rs:500-503` encodes the buffer with no lossy check.
- **Reproduce / verify:** `printf 'caf\xe9\n' > /tmp/x.txt; nyx-notepad /tmp/x.txt`, type a character, Ctrl+S, `xxd /tmp/x.txt` (static; confirm at runtime).
- **Evidence:** `nyx-notepad/apps/notepad/src/doc.rs:231-234,357-361,500-503`
- **Affected versions:** a5c720a2b4
- **User impact:** Accented characters in legacy files are irrecoverably corrupted by an ordinary save.
- **Recommended correction:** Remember `lossy` per tab; on save, ask before writing, or offer re-encoding with `encoding_rs`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Saving a lossy-decoded file prompts and, if cancelled, leaves the bytes unchanged.

### NYX-APP-NOTEPAD-002: A closed tab's unsaved text is lost if the app quits before Undo

- **Component:** nyx-notepad `apps/notepad/src/doc.rs`, `session.rs`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Closing a dirty tab deletes its scratch file at once; the Undo copy lives only in memory.
- **Expected:** "Nothing to lose" (README.md:10) holds across restarts, or closing a dirty tab asks.
- **Actual:** `close()` calls `session::forget` (`doc.rs:448`, `session.rs:140-143`); `CLOSED` is a thread-local (`doc.rs:60`).
- **Reproduce / verify:** Type in a tab, Ctrl+W, quit, relaunch, Ctrl+Shift+T (static; confirm at runtime).
- **Evidence:** `nyx-notepad/apps/notepad/src/doc.rs:428-466`
- **Affected versions:** a5c720a2b4
- **User impact:** Edits dismissed by mistake can't be recovered after quitting.
- **Recommended correction:** Keep the last few closed tabs' text in the scratch folder until they age out.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Ctrl+Shift+T restores a closed dirty tab after a restart.

### NYX-APP-NOTEPAD-003: README describes Omarchy and a pacman install

- **Component:** nyx-notepad `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** The README targets Omarchy (README.md:3, theme bullet) and documents a curl/pacman install, not NyxOS's Welcome/Store install.
- **Expected:** NyxOS install and theme behaviour documented (see docs-review.md).
- **Actual:** README.md:3, Install section.
- **Reproduce / verify:** `rg -n Omarchy nyx-notepad/README.md`
- **Evidence:** `nyx-notepad/README.md:3`
- **Affected versions:** a5c720a2b4
- **User impact:** Confusing instructions for NyxOS users.
- **Recommended correction:** Add a NyxOS section; keep Omarchy as secondary.
- **Effort:** S
- **Dependencies:** NYX-DOC findings
- **Verification criteria:** README names NyxOS install and theme behaviour.
