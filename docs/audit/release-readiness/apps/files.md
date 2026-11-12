# Nyx Files scorecard

- **Repository:** design-nexus/nyx-files at `4a2d8bfd4e` (pinned in nyx-packages: yes). The checkout moved to `c1e7ccad` (Jobs list, 25 files) during this audit; it is not pinned yet. Citations are at `c1e7ccad` for files that commit didn't change.
- **Release tier:** base (`nyx.files.enable`)
- **Purpose:** file manager (a Strata fork, GPL-3.0-or-later) with previews, archives, trash, providers and the FileManager1 D-Bus service
- **Stack:** Rust/GTK4, GtkSourceView, Poppler, GStreamer; bubblewrap preview sandbox; D-Bus name `org.freedesktop.FileManager1`
- **Binaries / services:** `nyx-files` and its RAR helper; `share/dbus-1/services/io.github.design_nexus.nyx.Files.FileManager1.service`; action manifest (`actions = [ "nyx-files" ]`); desktop entry, icon (`nyx-packages/pkgs/nyx-files.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Copy, move, merge, trash, restore, archives, previews, providers all implemented; no stubs found |
| UX | 3 | Documented keyboard model (`docs/keyboard-navigation.md`, `docs/keyboard-shortcuts.md`), translated entry |
| Accessibility | 2 | 27 explicit accessible labels and 50 tooltips for 25 icon-button sites; few hard-coded colours (14) |
| Reliability | 2 | Careful copy engine (staging, manifests, merge-aside); 83 tests skipped in the package, repository CI runs none |
| Integration | 3 | FileManager1 activation, actions manifest, Share provider; Omarchy integration gated on detecting Omarchy |
| Packaging | 3 | Trusted helper path embedded at build, runtime tools wrapped, tests run in the Nix build |
| Maintainability | 2 | 2,594 tests and 22 design docs; 275k Rust lines; README has no NyxOS section |

## Functionality

- Operations live in `src/adapters/local_operations/` (copy engine with staging and manifests `copy_engine/stage.rs`, `copy_engine/manifest.rs`; deletion `deletion.rs`; leftovers `leftovers.rs`). Only one TODO-like marker in non-test code; no `todo!`/`unimplemented!`.
- **Data-loss risks (static).** A merge that overwrites files without Trash moves each original aside into a hidden folder inside the target and deletes it only after the merge is on disk; originals whose names stay free go back first (`adapters/local_operations/merge_aside.rs:1-6`). Trash covers home and per-mount trash roots (`adapters/trash.rs:19-33`), with restore in `adapters/trash_restore.rs` and its own test notes in `docs/trash-restore-testing.md`. I found no unguarded overwrite path in this reading; the risk that remains is test coverage (below).
- **Skipped tests.** `nyx-packages/pkgs/nyx-files-skipped-tests.txt` lists 83 tests the Nix sandbox can't run (portal setup, udiskie, bubblewrap, FUSE, media). Nine of them cover file safety: `restore_safety::restore_copies_keep_the_metadata_the_destination_takes`, `restore_safety::restore_directory_copy_preserves_permissions_times_and_xattrs`, `deletion::a_folder_only_leftovers_keep_goes_once_they_do_within_the_mount_s_wait`, and six copy-metadata tests (xattrs, ACLs, setgid, special bits).
- Persistence: `~/.config/nyx-files`, `~/.local/state/nyx-files` (`src/storage.rs:152,156`), navigation history in the state folder (`services/navigation_history.rs:233`).

## UX and accessibility (static)

- Keyboard navigation and shortcuts are documented in depth; a shortcut reference is in the app (`ui/shortcut_reference.rs`).
- Path bar crumbs, tabs and menus come from nyx-ui helpers that set `Property::Label` (nyx-design `crates/nyx-ui/src/pathbar.rs:160-161`, `tabs.rs:176-177`).
- On NyxOS a missing-codec preview says "On Arch or Omarchy, install the required GStreamer plugins" (`ui/preview.rs:3817`); the package provides the plugins, so this should be rare.

## Reliability

- 1 `unwrap()` and 110 `expect()` outside tests by rough count; the `expect`s are invariants (poisoned locks `portal.rs`, fixed wire fields `media.rs`, `rar_extraction.rs`, list-model downcasts). 11 `panic!` sites are in `test_support/` and one invariant in `ui/virtual_preview.rs:1202`.
- Previews run in a bubblewrap sandbox with binaries from `STRATA_TRUSTED_COMMAND_PATH` (`pkgs/nyx-files.nix:45-53`).

## Integration and packaging

- D-Bus activation file `data/io.github.design_nexus.nyx.Files.FileManager1.service` (`Exec=/usr/bin/nyx-files --gapplication-service`, rewritten to the store path by `installServices`, `nyx-packages/lib/default.nix:118-129`).
- Omarchy leftovers: shortcut and portal setup (`portal_setup/omarchy.rs`) and the udiskie integration (`portal_setup/udiskie.rs:415`) run only when `omarchy_is_present()` finds `omarchy version` or `/usr/share/omarchy/version` (`portal_setup/omarchy.rs:152-170`). Settings search still lists "Follow Omarchy" and "Omarchy variant" (`ui/settings/search.rs:262-270`).
- Pins: nyx-core `4f05fb8` (main `9187295`), nyx-design `cf39397` (main `e311c2f`), nyx-cloud `072cb06` (main `ba6385f`).

## Maintenance

- 2,594 Rust tests; the Nix build runs them with 83 skipped. The repository's workflow only builds (`.github/workflows/build.yml:16`, `cargo build --release --locked`).
- `docs/` has 22 design documents (architecture, filesystem compatibility, preview sandbox, trash restore). README (65 lines) doesn't mention NyxOS.

## Runtime results

- Smoke test (Files): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 797 / 746 ms (two warm runs), RSS 208 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- No data-loss defect reproduced at runtime; under a full disk Files starts and logs 'No space left on device' for its assets and open tabs (logs/disk-full.txt). With the accessibility bridge forced on, 26/26 visible buttons have names (logs/atspi-buttons.txt).

## Findings

### NYX-APP-FILES-001: File-safety tests are skipped in the package and the repository's CI runs no tests

- **Component:** nyx-packages `pkgs/nyx-files-skipped-tests.txt`; nyx-files `.github/workflows/build.yml`
- **Category:** CI
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Restore metadata preservation, deletion leftovers and copy-metadata tests (9 of 83 skipped) never run anywhere automated: the Nix sandbox skips them and GitHub only builds.
- **Expected:** Data-integrity paths of a base file manager are tested on every release.
- **Actual:** skipped list lines for `restore_safety::*`, `deletion::*`, `file_copy::*`, `folder_copy::*`, `copy::read_only_items_keep_their_xattrs`; `build.yml:16` runs only `cargo build`.
- **Reproduce / verify:** `rg 'restore_safety|deletion|copy' nyx-packages/pkgs/nyx-files-skipped-tests.txt`; read `build.yml`.
- **Evidence:** as above.
- **Affected versions:** `4a2d8bfd4e`, `c1e7ccad`
- **User impact:** A regression in restore or copy metadata could ship unnoticed.
- **Recommended correction:** Run the full test suite in GitHub CI (or in the dev VM before each pin bump) where xattrs, FUSE and bubblewrap work, and record the result.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** A CI log shows the nine tests passing for the pinned commit.

### NYX-APP-FILES-002: Omarchy-specific text reachable on NyxOS

- **Component:** nyx-files `src/ui/preview.rs:3817`, `src/ui/settings/search.rs:262-270`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The codec hint tells NyxOS users to install plugins "on Arch or Omarchy"; settings search offers "Follow Omarchy".
- **Expected:** NyxOS wording, or Omarchy rows hidden when Omarchy isn't present.
- **Actual:** see Component.
- **Reproduce / verify:** Search Files' settings for "omarchy" on NyxOS (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `4a2d8bfd4e`
- **User impact:** Minor confusion.
- **Recommended correction:** Gate on `omarchy_is_present()`; give the NyxOS hint.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No Omarchy strings in a NyxOS session.
