# Nyx Office scorecard

- **Repository:** design-nexus/nyx-office at `98becf42b3` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user)
- **Purpose:** Write (documents), Sheets (spreadsheets) and Present (slides) in one binary
- **Stack:** Rust/GTK4 + GtkSourceView 5, libspelling; own readers/writers for docx/xlsx/pptx/odt/ods/odp, Markdown, CSV; qpdf at runtime
- **Binaries / services:** `nyx-office` plus wrapper scripts `nyx-write`, `nyx-sheets`, `nyx-present` (`nyx-packages/pkgs/nyx-office.nix` postInstall); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Very broad feature set; Office-format round trip rewrites from the internal model |
| UX | 2 | Home screen, Inspector, save prompt, recovery; autosave off by default |
| Accessibility | 2 | 32 icon-only buttons with tooltips only, 0 explicit labels |
| Reliability | 2 | Atomic saves, recovery copies; silent loss of unmodelled content on in-place Office saves |
| Integration | 2 | Three desktop entries with Office/ODF MIME types; control tools but no action manifest; no Glimpse |
| Packaging | 3 | Wrappers, GtkSourceView/libspelling/qpdf inputs present |
| Maintainability | 2 | 129 tests; 43k lines with 87-109 KB modules; README describes Omarchy |

## Functionality

Write: styles, lists, tables, pictures, charts, footnotes, comments, track changes, TOC,
columns, spelling. Sheets: 1,048,576 rows, 170+ functions, spills, charts, pivots as
summaries, conditional formats. Present: layouts, shapes, transitions, presenter view
(README.md:15-161). Native formats `.nwrite/.nsheets/.npresent` keep everything; Word,
Excel, PowerPoint and ODF "open and save in place" (README.md:165-171).

Saving: `atomic_write` for every format (`write/mod.rs:1924-1957`, `present/mod.rs:1951-1961`).
Unsaved-changes guard on close/open ("Save changes to …?", `doc.rs:283-330`); recovery
snapshots every few seconds (README.md:178; `doc.rs:62-66, 165`); autosave opt-in
(README.md:180; `doc.rs:235-239`). On save, a toast lists what the target format can't hold
(`doc.rs:549-570`), but only for features of Office's own model: content Office didn't
import is not reported (NYX-APP-OFFICE-001).

## UX and accessibility (static)

Extensive shortcuts (README table). Icon buttons come from `nyx_ui::widgets::icon_button`,
tooltip only (nyx-design `cf39397` `crates/nyx-ui/src/widgets.rs:242-249`). Colour literals
(202 in Rust, 37 in CSS) are document, chart and page colours (the page keeps paper colours
by design, `style.css:478-513`), not window chrome.

## Reliability

`expect()`s on invariants (`present/mod.rs:263`, `sheets/model.rs:1618`, layout pages). Files
with >1,048,576 rows are truncated with a note (`sheets/xlsx.rs:134-142`).

## Integration and packaging

`io.github.design_nexus.nyx.Write/Sheets/Present.desktop` with docx/odt/md/txt, xlsx/ods/csv,
pptx/odp MIME types; icons present. Control interface (`write/control.rs` etc.), no action
manifest. Omarchy: theme default only (`prefs.rs:38`).

## Maintenance

129 tests. CI: check + release. Very large modules (`write/mod.rs` 109 KB, `write/docx.rs` 90 KB).
README.md:3 "for Omarchy".

## Runtime results

- Smoke test (Write): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Smoke test (Sheets): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Smoke test (Present): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- The .docx/.xlsx/.pptx round trip (OFFICE-001) needs the GUI save path and wasn't exercised: OFFICE-001 stays static and must be tested before release.

## Findings

### NYX-APP-OFFICE-001: Saving a Word/Excel/PowerPoint file in place silently drops what Office didn't import

- **Component:** nyx-office `apps/office/src/write/docx.rs`, `present/pptx.rs`, `sheets/xlsx.rs`, `doc.rs`
- **Category:** reliability
- **Severity:** P1
- **Status of feature:** implemented, not verified
- **Description:** Opening a .docx/.pptx/.xlsx builds Office's own model; Ctrl+S rewrites the whole file from that model. Anything the reader doesn't model (for example content controls, text boxes, SmartArt, embedded objects, per-section headers, custom XML) is gone after one save, with no warning. The only warnings cover features of Office's model that the target format can't hold, plus xlsx truncation and dropped conditional formats.
- **Expected:** "Open and save in place" (README.md:165-171) without silent loss: either preserve unknown parts, or warn on open/save and default to "Save as" when the import was lossy.
- **Actual:** `docx::read` returns `(Document, media)` with no loss report (`write/docx.rs:1244`); `docx::write` emits only modelled parts (`docx.rs:450-471`); the save toast uses only the writer's `lost` list (`doc.rs:549-570`); xlsx reports truncation/dropped rules only (`sheets/xlsx.rs:134-142`).
- **Reproduce / verify:** Open a Word file with a text box and a content control, type one character, Ctrl+S, reopen in LibreOffice/Word and compare (static; confirm at runtime; if confirmed with common business documents, treat as P0 data loss).
- **Evidence:** as above
- **Affected versions:** 98becf42b3
- **User impact:** People editing documents from work or school lose content after a routine save.
- **Recommended correction:** Track unsupported elements during import; warn on open and before the first in-place save, offering "Save a copy"; longer term, carry unknown XML through.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** A fidelity corpus (docx/xlsx/pptx/odt) round-trips without silent loss; lossy imports warn.

### NYX-APP-OFFICE-002: Icon-only buttons have tooltips but no accessible names

- **Component:** nyx-design `cf39397` `crates/nyx-ui/src/widgets.rs`; used by nyx-office, nyx-photos, nyx-pdf and others
- **Category:** accessibility
- **Severity:** P3 (was P2 statically; lowered after the runtime survey)
- **Status of feature:** implemented, not verified
- **Description:** `nyx_ui::widgets::icon_button` sets only a tooltip. GTK 4 maps tooltips to the accessible description; whether screen readers get a name depends on GTK's fallback. Office has 32 such buttons and no `update_property(Label)` calls.
- **Expected:** Every icon-only control has an accessible label (WCAG 4.1.2), as `nyx-ui`'s sidebar, tabs and menu buttons already do (`sidebar.rs:73`, `tabs.rs:177`, `menu.rs:178`).
- **Actual:** `widgets.rs:242-249`; nyx-office has 0 explicit labels.
- **Reproduce / verify:** Run Orca or Accerciser over Write's toolbar (runtime).
- **Evidence:** as above
- **Affected versions:** nyx-design cf39397; nyx-office 98becf42b3
- **User impact:** Screen-reader users may hear "button" with no name.
- **Recommended correction:** In `icon_button`, also `update_property(&[Property::Label(tooltip)])`; re-pin apps.
- **Effort:** S
- **Dependencies:** NYX-A11Y findings; NYX-PKG-002 (re-pinning)
- **Verification criteria:** Accerciser shows names for all toolbar buttons.
- **Runtime result:** with the accessibility bridge forced on, GTK4 exposed tooltip text as the accessible name: 0 unnamed buttons in Notepad, Files, Calculator, Mail and Settings (evidence/logs/atspi-buttons.txt). Office itself wasn't surveyed; the remaining risk is icon buttons without tooltips.

### NYX-APP-OFFICE-003: README describes Omarchy

- **Component:** nyx-office `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README.md:3 "for Omarchy", curl install.
- **Expected:** NyxOS documented.
- **Actual:** README.md:3.
- **Reproduce / verify:** `rg -n Omarchy nyx-office/README.md`
- **Evidence:** `nyx-office/README.md:3`
- **Affected versions:** 98becf42b3
- **User impact:** Minor confusion.
- **Recommended correction:** Add NyxOS section.
- **Effort:** S
- **Dependencies:** NYX-DOC findings
- **Verification criteria:** README covers NyxOS.
