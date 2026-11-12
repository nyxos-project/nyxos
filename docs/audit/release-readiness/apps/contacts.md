# Nyx Contacts scorecard

- **Repository:** design-nexus/nyx-contacts at `f6af1500a4` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user)
- **Purpose:** local address book with lists, birthdays, duplicates, vCard/CSV, and read-only online books
- **Stack:** Rust/GTK4, rusqlite store; online books through nyx-core `nyx-pim` and nyx-accounts `afdc148` (native, no EDS)
- **Binaries / services:** `nyx-contacts` (`nyx-packages/pkgs/nyx-contacts.nix`, `buildInputs = nyx.pimInputs`); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Local book complete (edit, lists, merge, import/export); online books read-only and gated by account onboarding |
| UX | 2 | Shortcuts, command palette, Undo on delete/merge, discard prompt in the editor |
| Accessibility | 2 | 2 icon-only buttons, 5 tooltips, 1 explicit label |
| Reliability | 3 | Saves in one SQLite transaction; 5 non-test `unwrap()` all guarded; exports via `atomic_write` |
| Integration | 2 | vCard MIME, Assistant tools; no action manifest installed |
| Packaging | 3 | Simple recipe; no EDS needed |
| Maintainability | 2 | 12 tests for 4k lines; README still says EDS |

## Functionality

Contacts with photos, lists, favorites, birthdays, duplicate merge with Undo, vCard 2.1/3.0/4.0
and CSV import (UTF-8/16, Windows-1252) and export with formula-injection quoting (README.md:30-40).
Store: `~/.local/share/nyx-contacts/contacts.db`; `Store::save` writes changed rows in one
transaction (`apps/contacts/src/model.rs:300-329`). Online books: `nyx_pim` address books
(`ui.rs:38-44`, fields still named `eds_*`), read-only (`ui.rs:1177, 1438`).
**EDS:** not used; Cargo depends on `nyx-pim` and `nyx-accounts-service` (`apps/contacts/Cargo.toml:22, 24`).

## UX and accessibility (static)

Ctrl+N/S/F/B, Ctrl+Shift+P palette, F1. Editor asks "Discard unsaved changes?" on close
(`editor.rs:385-394`). No hard-coded colours.

## Reliability

vCard unfolding `unwrap()`s are guarded by `!lines.is_empty()`/prior push (`formats.rs:100-114`).
Corrupt rows fail the load with the database kept unchanged (`model.rs:280-281`).

## Integration and packaging

`io.github.design_nexus.nyx.Contacts.desktop` (`text/vcard;text/x-vcard`, `%U`), icon present.
Assistant tools `contacts.find/birthdays/lists/add/update/add_to_list` (`control.rs:28-30`);
the package installs no action manifest (Calendar, Notes and Passwords do). No Glimpse
provider. Omarchy: theme default only (`prefs.rs:18`).

## Maintenance

12 tests. CI: check + release. Pins: nyx-accounts `afdc148`, common nyx-core/nyx-design.

## Runtime results

- Smoke test (Contacts): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-CONTACTS-001: Online address books depend on developer-grade account setup

- **Component:** nyx-accounts `afdc148`; nyx-contacts online books
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Google and Microsoft books need a user-registered OAuth client (NYX-APP-MAIL-001); CardDAV with app passwords works. Online books are read-only.
- **Expected:** Google contacts appear after a normal sign-in.
- **Actual:** nyx-accounts `afdc148:docs/PROVIDERS.md:3-25`; read-only toasts `ui.rs:1177, 1438`.
- **Reproduce / verify:** See NYX-APP-MAIL-001.
- **Evidence:** as above
- **Affected versions:** f6af1500a4
- **User impact:** Google contacts unavailable to most users.
- **Recommended correction:** As NYX-APP-MAIL-001.
- **Effort:** L
- **Dependencies:** NYX-APP-MAIL-001
- **Verification criteria:** Google contacts listed without a client ID.

### NYX-APP-CONTACTS-002: README says online books come through Evolution Data Server

- **Component:** nyx-contacts `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README.md:29-30 says "through Evolution Data Server"; the code uses native nyx-pim and nyx-accounts, and NyxOS ships no EDS.
- **Expected:** Docs describe the native path.
- **Actual:** README.md:29-30 vs `apps/contacts/Cargo.toml:22, 24`.
- **Reproduce / verify:** `rg -n Evolution nyx-contacts/README.md`
- **Evidence:** as above
- **Affected versions:** f6af1500a4
- **User impact:** Users may install EDS needlessly or expect GNOME accounts to work.
- **Recommended correction:** Update the bullet; rename `eds_*` fields.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No EDS mention outside migration notes.

### NYX-APP-CONTACTS-003: Assistant tools without an installed action manifest

- **Component:** nyx-packages `pkgs/nyx-contacts.nix`; nyx-contacts `control.rs`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Contacts implements control tools, but nyx-packages installs no manifest for it, so `nyx contacts …` and manifest-based discovery may not see them.
- **Expected:** Same treatment as Calendar, Notes, Passwords (`actions = [ … ]`).
- **Actual:** `pkgs/nyx-contacts.nix` has no `actions`; `control.rs:28-30`.
- **Reproduce / verify:** `ls /run/current-system/sw/share/nyx/actions` or the profile's `share/nyx/actions` (runtime).
- **Evidence:** as above
- **Affected versions:** f6af1500a4; nyx-packages d69e87e
- **User impact:** Assistant may not find contacts actions.
- **Recommended correction:** Add `--describe-actions` support and `actions = [ "nyx-contacts" ]`.
- **Effort:** S
- **Dependencies:** NYX-AI action registry review
- **Verification criteria:** Manifest installed; `nyx contacts find` works.
