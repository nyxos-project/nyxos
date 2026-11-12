# Nyx Archive scorecard

- **Repository:** design-nexus/nyx-archive at `3e6072d7f3` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (preselected; installed per user)
- **Purpose:** browse, extract, create and edit archives through 7-Zip
- **Stack:** Rust/GTK4 front end driving `7zz` as a subprocess; nyx-core `4f05fb8`, nyx-design `cf39397`
- **Binaries / services:** `nyx-archive` (`nyx-packages/pkgs/nyx-archive.nix`, `runtimeInputs = [ _7zz ]`); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Browse, extract (all/selection), create (7z/zip/tar.gz/tar.xz), add, delete, test, edit-in-place |
| UX | 2 | Progress card with cancel and details; overwrite prompt only when needed |
| Accessibility | 2 | 5 icon-only buttons, 8 tooltips; no explicit accessible labels |
| Reliability | 2 | 0 non-test `unwrap()`, 10 `expect()` on invariants (piped stdio, row widgets); temp `.part` files for creation |
| Integration | 2 | Desktop entry with 14 archive MIME types and a Create action; no actions manifest or Glimpse |
| Packaging | 3 | 7-Zip on the wrapper PATH |
| Maintainability | 2 | 20 tests; README describes Omarchy |

## Functionality

7-Zip command plans in `apps/archive/src/sevenzip/job.rs:156-206` (extract `x -y -ao* -o<dest> -- archive paths`,
test, delete, add, update) and create (`job.rs:212-260`, temp `.part` name then rename,
`job.rs:151-154`). Files opened from an archive use a working copy in the cache and are
offered back on refocus (`views/browse.rs:937-1000`). Read-only formats are marked.
Passwords: kept in memory while the archive is open, passed to 7-Zip as `-p…`
(`job.rs:120-122, 256`), disclosed in README.md:32.

**Zip slip:** the app does no path check of its own; safety on extract rests on 7-Zip's
handling of `..`, absolute paths and symlinks (NYX-APP-ARCHIVE-002).

## UX and accessibility (static)

Breadcrumbs, sortable columns, search, context menu, drag out. Overwrite: Ask maps to
`-aos` after the app's own prompt (`job.rs:31-33`). No hard-coded colours.

## Reliability

Cancelled or failed jobs remove temp output (`Plan.cleanup`, `job.rs:134-145`). In-place
edits (add/delete/update) rely on 7-Zip's own temp-and-replace.

## Integration and packaging

`apps/archive/data/io.github.design_nexus.nyx.Archive.desktop`: archive MIME types, `Actions=Create`,
`DBusActivatable=false`; icon present. Control interface (`control.rs`) but no action
manifest installed. No Omarchy calls beyond the `ThemeMode::Omarchy` default (follow system).

## Maintenance

20 tests, including real 7-Zip round trips (`job.rs:481-575`). CI: check + release.
README.md:3 "for Omarchy"; install section uses curl/pacman.

## Runtime results

- Smoke test (Archive): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Crafted zip (`../`, absolute path, symlink escape) extracted with the shipped 7-Zip 26.04 and the app's switches: nothing escaped the destination (logs/archive-zipslip.txt); ARCHIVE-002 not reproduced.

## Findings

### NYX-APP-ARCHIVE-001: Archive passwords are visible to other users in the process list

- **Component:** nyx-archive `apps/archive/src/sevenzip/job.rs`
- **Category:** security
- **Severity:** P2
- **Status of feature:** verified
- **Description:** Passwords go to 7-Zip as a `-p<password>` argument, readable in `/proc/<pid>/cmdline` by any local user while a job runs.
- **Expected:** Secrets aren't passed on command lines (7-Zip reads the password from stdin when `-p` has no value).
- **Actual:** `job.rs:120-122` (`format!("-p{p}")`), `job.rs:256`; README.md:32 acknowledges it.
- **Reproduce / verify:** Extract a password-protected 7z; `ps -eo args | rg 7zz` from another account (static; confirm at runtime).
- **Evidence:** `nyx-archive/apps/archive/src/sevenzip/job.rs:120-122,256`, `README.md:32`
- **Affected versions:** 3e6072d7f3
- **User impact:** On multi-user machines, archive passwords leak to other accounts.
- **Recommended correction:** Pass `-p` without a value and write the password to 7-Zip's stdin.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No password in `ps` output during extract and create.

### NYX-APP-ARCHIVE-002: Extraction path safety rests entirely on 7-Zip

- **Component:** nyx-archive `apps/archive/src/sevenzip/job.rs`; nixpkgs `_7zz`
- **Category:** security
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Extract runs `7zz x -y -ao… -o<dest>` with no app-side check for `..`, absolute paths or symlinks that point outside the destination. Recent 7-Zip releases fixed symlink-based traversal bugs, so safety depends on the packaged 7-Zip version.
- **Expected:** Zip-slip protection verified for the shipped 7-Zip, ideally with defence in depth (reject entries whose resolved path leaves `dest`).
- **Actual:** `job.rs:160-167`; the listing is parsed (`sevenzip/parse.rs`) but not checked before extraction.
- **Reproduce / verify:** Build zips/tars with `../evil`, `/tmp/evil` and a symlink-then-file pair; extract with Nyx Archive on NyxOS; check nothing lands outside the folder (runtime).
- **Evidence:** `nyx-archive/apps/archive/src/sevenzip/job.rs:160-167`
- **Affected versions:** 3e6072d7f3
- **User impact:** A malicious archive could write outside the chosen folder if the 7-Zip in nixpkgs is vulnerable.
- **Recommended correction:** Check the parsed listing for unsafe paths and links before extracting; record the minimum 7-Zip version.
- **Effort:** S
- **Dependencies:** nixpkgs `_7zz` version
- **Verification criteria:** Crafted archives are refused or contained.
- **Runtime result:** not reproduced: the shipped 7-Zip 26.04 with the app's switches kept `../`, absolute and symlink entries inside the destination (evidence/logs/archive-zipslip.txt). Defence in depth remains advisable.

### NYX-APP-ARCHIVE-003: README describes Omarchy and a pacman install

- **Component:** nyx-archive `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README.md:3-6 targets Omarchy; install is curl/pacman.
- **Expected:** NyxOS install and behaviour documented.
- **Actual:** README.md:3, Install section.
- **Reproduce / verify:** `rg -n Omarchy nyx-archive/README.md`
- **Evidence:** `nyx-archive/README.md:3`
- **Affected versions:** 3e6072d7f3
- **User impact:** Misleading docs on NyxOS.
- **Recommended correction:** Add NyxOS instructions.
- **Effort:** S
- **Dependencies:** NYX-DOC findings
- **Verification criteria:** README covers NyxOS.
