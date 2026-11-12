# Nyx Photos scorecard

- **Repository:** design-nexus/nyx-photos at `5a254f1d7f` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (preselected; installed per user)
- **Purpose:** photo library with timeline, albums, editor and a single-image viewer
- **Stack:** Rust/GTK4; nyx-core `4f05fb8`, nyx-design `cf39397`, nyx-share `3923640`; ffmpeg/ffmpegthumbnailer for video
- **Binaries / services:** `nyx-photos`, `nyx-viewer` (`nyx-packages/pkgs/nyx-photos.nix`, runtime ffmpeg, ffmpegthumbnailer, xdg-utils); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Library, search, albums, editor, trash with undo; "Set as background" missing on NyxOS |
| UX | 2 | Keyboard-first, narrow-window layout; background action silently absent |
| Accessibility | 2 | 21 icon-only buttons with tooltips, 1 explicit label (shared `nyx-ui` helper) |
| Reliability | 3 | 8 non-test `unwrap()` on invariants; edits save atomically, copy by default, originals backed up |
| Integration | 2 | Two desktop entries with image MIME types, Share; no actions manifest or Glimpse |
| Packaging | 3 | Video tools on the wrapper PATH; package comment documents the hidden action |
| Maintainability | 2 | 60 tests; README describes Omarchy and its background command |

## Functionality

Timeline, library folders with watching, search grammar, albums, favorites, duplicates,
trash with undo (`apps/gallery/src/library.rs:419-450`), rename refuses existing names
(`library.rs:225-240`), export, slideshow, editor (crop, adjust, markup). Edits save as a
copy by default with originals backed up (`prefs.rs:56-58`; `edit/save.rs:34-56, 78`), via
`atomic_write`. Library cache, favorites, rotations and albums persist with `atomic_write`
(`library.rs:64, 312-320`). Saved edits are re-encoded by the `image` crate with no EXIF
copy (NYX-APP-PHOTOS-002).

## UX and accessibility (static)

Shortcuts for every action (README table), date scrubber, narrow layout. Icon buttons come
from `nyx_ui::widgets::icon_button`, which sets only a tooltip (nyx-design `cf39397`
`crates/nyx-ui/src/widgets.rs:242-249`); see NYX-APP-OFFICE-002 for the shared gap. Rust
colour literals (12) are editor markup swatches.

## Reliability

No daemon. Thumbnails in the cache. `unwrap()`s are list-item downcasts and fixed swatch
parsing (`grid.rs:326-345`, `editor.rs:684, 1219`).

## Integration and packaging

`io.github.design_nexus.nyx.Photos.desktop` and `…PhotoViewer.desktop` (image MIME types),
icons in `crates/nyx-icons/apps/`. Share through nyx-share. Control interface present but
no action manifest installed. Omarchy leftover: `BACKGROUND_COMMAND = "omarchy-theme-bg-set"`
(`actions.rs:11`), gated by `cmd::present` so it is hidden, not broken, on NyxOS.

## Maintenance

60 tests. CI: check + release. README.md:3, 18, 77 describe the Omarchy theme and background.

## Runtime results

- Smoke test (Photos): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Smoke test (Photo Viewer): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 761 / 666 ms (two warm runs), RSS 161 MB 4 s after start (logs/perf-app-startup.txt, dev VM).

## Findings

### NYX-APP-PHOTOS-001: "Set as background" is Omarchy-only and hidden on NyxOS

- **Component:** nyx-photos `apps/gallery/src/actions.rs`, `lightbox.rs`, `window.rs`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** approved, not implemented
- **Description:** The action runs `omarchy-theme-bg-set`; on NyxOS the command is absent, so the button and menu items are hidden. NyxOS's wallpaper is chosen through `~/.local/state/nyx/wallpaper` and the theme service.
- **Expected:** Setting a photo as wallpaper works on NyxOS (README.md:13, 18, 20, 77 advertise it).
- **Actual:** `actions.rs:11, 88-99`; hidden at `lightbox.rs:133-134`, `window.rs:1628, 2134`; `nyx-packages/pkgs/nyx-photos.nix:1-2` notes it; NyxOS wallpaper state `nyx-packages/modules/nixos/default.nix:452-458`.
- **Reproduce / verify:** Open a photo in the viewer on NyxOS; no wallpaper button or W shortcut effect (static; confirm at runtime).
- **Evidence:** as above
- **Affected versions:** 5a254f1d7f
- **User impact:** A common gallery action is missing with no explanation.
- **Recommended correction:** Set the wallpaper through nyx-themed's D-Bus API (or `nyx-theme`) when present; keep the Omarchy path as fallback.
- **Effort:** S
- **Dependencies:** Theme Engine wallpaper API (NYX-THEME)
- **Verification criteria:** "Set as background" changes the NyxOS wallpaper and survives re-login.

### NYX-APP-PHOTOS-002: Saved edits drop EXIF (date taken, GPS, camera)

- **Component:** nyx-photos `apps/gallery/src/edit/save.rs`, `edit/pipeline.rs`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Edits are decoded and re-encoded by the `image` crate; nothing copies EXIF into the output, so the edited photo loses its capture date and moves on the timeline. With "Replace original" and backups off, the metadata is gone.
- **Expected:** Edits keep metadata (or say they don't), with orientation reset.
- **Actual:** `edit/save.rs:34-56` writes encoder bytes via `atomic_write`; no EXIF handling (only orientation is read, `pipeline.rs:36`).
- **Reproduce / verify:** Crop a camera JPEG, save; `exiftool` the result (static; confirm at runtime).
- **Evidence:** `nyx-photos/apps/gallery/src/edit/save.rs:34-56`
- **Affected versions:** 5a254f1d7f
- **User impact:** Edited photos lose their date and location.
- **Recommended correction:** Copy the EXIF block (e.g. `little_exif`/`img-parts`), resetting Orientation.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Edited copy keeps DateTimeOriginal, GPS and camera tags.

### NYX-APP-PHOTOS-003: README describes Omarchy

- **Component:** nyx-photos `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README.md:3, 18, 77 describe the Omarchy theme and background; install is curl/pacman.
- **Expected:** NyxOS behaviour documented.
- **Actual:** as cited.
- **Reproduce / verify:** `rg -n Omarchy nyx-photos/README.md`
- **Evidence:** `nyx-photos/README.md:3,18,77`
- **Affected versions:** 5a254f1d7f
- **User impact:** Docs promise a feature NyxOS hides.
- **Recommended correction:** Update with NyxOS wording once PHOTOS-001 lands.
- **Effort:** S
- **Dependencies:** NYX-APP-PHOTOS-001
- **Verification criteria:** README matches NyxOS behaviour.
