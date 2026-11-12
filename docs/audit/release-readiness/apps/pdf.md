# Nyx PDF scorecard

- **Repository:** design-nexus/nyx-pdf at `7784708062` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user)
- **Purpose:** PDF viewer and editor: annotate, fill forms, sign, edit text, rearrange pages
- **Stack:** Rust/GTK4, poppler-glib for rendering, lopdf for page operations; nyx-share `3923640`
- **Binaries / services:** `nyx-pdf` (`nyx-packages/pkgs/nyx-pdf.nix`, `buildInputs = [ poppler ]`); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Reading modes, search, markup, forms, signatures, text edit, page ops, combine |
| UX | 2 | Tabs, library, unsaved-changes prompt, recovery; "Edit text" leaves the old text extractable |
| Accessibility | 2 | 13 icon-only buttons, 29 tooltips, 0 explicit labels |
| Reliability | 2 | Edits stay in work copies until saved; save is copy+rename without fsync or permission keep |
| Integration | 2 | `application/pdf`, Share; control tools but no action manifest; no Glimpse |
| Packaging | 3 | poppler input; nothing else needed |
| Maintainability | 2 | 28 tests for 10.6k lines; README describes Omarchy |

## Functionality

Continuous/single/two-page/book views, links with back/forward, search, page colours,
presentation, print, library (README.md:8-34). Markup as standard annotations, forms,
signatures, text replacement, page reorder/rotate/delete/insert/extract, combine
(`apps/pdf/src/doc/ops.rs:120-153`). Edits build numbered generations in a work folder; undo
and redo move between them (`doc/mod.rs:406-412`); recovery is offered after a crash
(`window.rs:70`). Encrypted files are read-only.

**Saving edits:** `Doc::save` copies the current generation to a temp file beside the
target and renames it over (`doc/mod.rs:414-455`): atomic replacement, but no fsync, no
temp cleanup if rename fails, and the original file's permissions aren't kept
(NYX-APP-PDF-002). Close with unsaved changes asks (`window.rs:37, 209`).

## UX and accessibility (static)

Ctrl+F, Ctrl+Tab, F5, Ctrl+P and more. Icon buttons via `nyx_ui` (tooltip only, see
NYX-APP-OFFICE-002). Colour literals are paper white, signature ink and page tints by design.

## Reliability

`unwrap()`s on the render queue mutex (`doc/render.rs:134-151`) and in `testpdf.rs` (test
fixture builder). Files changed by other programs are reloaded or, with unsaved edits, asked about.

## Integration and packaging

`io.github.design_nexus.nyx.Pdf.desktop` (`application/pdf`, `%U`), icon present. Share
via nyx-share. Control interface, no action manifest. Omarchy: theme default only (`prefs.rs:52`).

## Maintenance

28 tests. CI: check + release. README.md:3 "for Omarchy".

## Runtime results

- Smoke test (PDF): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 595 / 595 ms (two warm runs), RSS 146 MB 4 s after start (logs/perf-app-startup.txt, dev VM).

## Findings

### NYX-APP-PDF-001: "Edit text" leaves the original words in the file

- **Component:** nyx-pdf `apps/pdf/src/viewer`, `doc/text.rs`
- **Category:** privacy
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Replacement text is drawn over a patch of page colour; the original text stays in the content stream (README.md:39-41). People may use it to hide a figure or name and share a file that still contains it.
- **Expected:** Either true redaction (remove the glyphs) or an in-app warning at the point of editing that the old text remains.
- **Actual:** README.md:39-41; overlay drawing in `doc/text.rs:43`; whether the UI warns was not verified.
- **Reproduce / verify:** Replace a word, save, `pdftotext` the file (static; confirm at runtime).
- **Evidence:** `nyx-pdf/README.md:39-41`
- **Affected versions:** 7784708062
- **User impact:** Sensitive text shared unintentionally.
- **Recommended correction:** Warn in the edit UI; add a real redaction tool that strips covered text.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** Users are told in-app; redaction removes text from `pdftotext` output.

### NYX-APP-PDF-002: Save isn't fsynced and resets file permissions

- **Component:** nyx-pdf `apps/pdf/src/doc/mod.rs`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `write_copy` uses `fs::copy` then `rename`, without `sync_all`, without restoring the original's mode, and leaves `.name.tmp-PID` behind if rename fails. A symlinked PDF is replaced by a regular file. The suite's `nyx_core::cmd::atomic_write` handles all of these.
- **Expected:** Same guarantees as `atomic_write` (nyx-core `4f05fb8` `crates/nyx-core/src/cmd.rs:132-156`).
- **Actual:** `doc/mod.rs:449-455`.
- **Reproduce / verify:** `chmod 600 a.pdf`, annotate, save, `stat a.pdf` (static; confirm at runtime).
- **Evidence:** `nyx-pdf/apps/pdf/src/doc/mod.rs:449-455`
- **Affected versions:** 7784708062
- **User impact:** Private PDFs may become world-readable per umask; small power-loss window.
- **Recommended correction:** Stream the generation through `atomic_write` (or copy, fsync, keep permissions, canonicalize).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Mode and symlink preserved; fsync before rename.

### NYX-APP-PDF-003: README describes Omarchy

- **Component:** nyx-pdf `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README.md:3 "for Omarchy"; install via curl/pacman.
- **Expected:** NyxOS documented.
- **Actual:** README.md:3.
- **Reproduce / verify:** `rg -n Omarchy nyx-pdf/README.md`
- **Evidence:** `nyx-pdf/README.md:3`
- **Affected versions:** 7784708062
- **User impact:** Minor.
- **Recommended correction:** Add NyxOS section.
- **Effort:** S
- **Dependencies:** NYX-DOC findings
- **Verification criteria:** README covers NyxOS.
