# Nyx Capture scorecard

- **Repository:** design-nexus/nyx-capture at `06b4d57a90` (pinned in nyx-packages: yes, 0 behind origin/main; checkout has an untracked `mockups/`)
- **Release tier:** base (`nyx.capture.enable`)
- **Purpose:** screenshots, annotation, OCR, QR, screen recording and webcam overlay, with a searchable history
- **Stack:** Rust/GTK4 with gtk4-layer-shell overlays; ONNX Runtime (RapidOCR) and Tesseract; grim, slurp, wf-recorder, ffmpeg, mpv, PipeWire portal recorder; Glimpse plugin
- **Binaries / services:** `nyx-capture`, the Glimpse plugin in `share/nyx-capture/glimpse` (`glimpsePlugin = true`), desktop entry with region/window/fullscreen actions, icon (`nyx-packages/pkgs/nyx-capture.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Screenshots, annotation, OCR, recording implemented; scrolling capture hidden on NyxOS; webcam overlay depends on Omarchy window rules |
| UX | 2 | Capture bar, recording bar that leaves the recorded area, history; Omarchy references in a settings row |
| Accessibility | 2 | 32 tooltips for 17 icon-button sites, no explicit accessible labels |
| Reliability | 2 | Few `unwrap`/`expect` on runtime data; recorder stop escalates INT then KILL and checks the file |
| Integration | 2 | Glimpse plugin, Nyx Bar recording indicator, Share; no `share/nyx/actions` manifest (Assistant tools only while open) |
| Packaging | 2 | Tesseract limited to 12 languages, ORT linked to nixpkgs; only wf-recorder of the four recorders is shipped |
| Maintainability | 2 | 117 tests; README written for Omarchy |

## Functionality

- Screenshots go through grim (wlr-screencopy) on Hyprland, the XDG screenshot portal only when grim is missing (`apps/capture/src/settings_page.rs:115-121`). Window and monitor hints for slurp come from Hyprland (`crates/nyx-capture-core/src/capture/grim.rs:85`).
- **Portal usage.** Recording uses gpu-screen-recorder, wf-recorder, wl-screenrec or GStreamer with the ScreenCast portal (`crates/nyx-capture-core/src/record.rs:1`, `settings_page.rs:277-282`); `record_use_portal` is off by default (`prefs.rs:87`). On NyxOS only wf-recorder is on PATH (`pkgs/nyx-capture.nix:43-47`), plus the portal path when `xdg-desktop-portal-hyprland` is present.
- **Recording indicator.** Capture draws a red frame just outside the recorded area and a recording bar (time, sound, mic, pause, discard, stop) that shrinks to a pill for full-screen recordings (`apps/capture/src/recording.rs:1-4,23-30`). It writes `$XDG_RUNTIME_DIR/nyx-capture/recording.json` (`record.rs:755`), which Nyx Bar's `nyx.recording` plugin reads every second to show a red dot, the time and a stop button (`nyx-bar/plugins/recording/src/main.rs:1-4`).
- Scrolling capture is hidden on NyxOS because it runs Omarchy's `omasnap` (`pkgs/nyx-capture.nix:1-2`).
- Webcam overlay: mpv with Omarchy's `WebcamOverlay` class, relying on Omarchy's Hyprland rules to float and pin it (`crates/nyx-capture-core/src/webcam.rs:1-2`); nyxos, nyx-hyprland and nyx-shell have no such rule (repository search). See NYX-APP-CAPTURE-001.
- Assistant screenshot sending is refused until Capture's settings allow it (`apps/capture/src/control.rs`, `capture.send_screenshot`).
- Persistence: `capture.sqlite` and `captures/` in the data folder, thumbnails in the cache (`apps/capture/src/paths.rs:7-21`).

## UX and accessibility (static)

- Desktop actions: capture a region, window or screen and copy (`apps/capture/data/io.github.design_nexus.nyx.Capture.desktop:16-28`).
- 37 hard-coded colours, mostly annotation palettes and backdrops (`annot/backdrop.rs`, `editor.rs`), which are content colours, not theme.
- The webcam row says "mpv picture-in-picture using Omarchy WebcamOverlay window rules." (`settings_page.rs:329`).

## Reliability

- `unwrap`/`expect` outside tests are invariants (list-item downcasts `grid.rs:131-146`, regex literals `redact.rs:82-87`); `select/mod.rs:59-62` is guarded by an empty-list check at `:56`.
- Stopping a recording sends SIGINT, waits, then SIGKILL, and fails clearly if the file is missing (`record.rs:354-387`); it won't signal a recycled PID (`record.rs:367`).

## Integration and packaging

- Glimpse plugin `apps/capture-glimpse/plugin.toml`; Share via nyx-share `3923640` (main `148dc74`); nyx-glimpse `6f9f732` (main `deecabf`).
- No action manifest: Capture exposes `nyx_core::control` tools to the Assistant only while it runs (`control.rs:1-25`), so `nyx capture …` and Glimpse actions can't start it.
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`.

## Maintenance

- 117 tests (inventory); `.github/workflows/check.yml`. README (189 lines) and the crate doc (`apps/capture/src/main.rs:1`, "for Omarchy") don't describe NyxOS.

## Runtime results

- Smoke test (Capture): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-CAPTURE-001: Webcam overlay relies on Omarchy's window rules, which NyxOS doesn't have

- **Component:** nyx-capture `crates/nyx-capture-core/src/webcam.rs:1-2`, `apps/capture/src/settings_page.rs:326-333`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The webcam picture-in-picture opens mpv with the `WebcamOverlay` class and expects Omarchy's Hyprland rules to float, size and pin it. NyxOS's Hyprland config has no such rule.
- **Expected:** The overlay floats in a corner on NyxOS, or the row is hidden.
- **Actual:** No `WebcamOverlay` rule in nyxos, nyx-hyprland or nyx-shell; the switch is offered whenever a webcam and mpv exist (`settings_page.rs:326`).
- **Reproduce / verify:** On NyxOS, turn on Webcam overlay and record (static; confirm at runtime).
- **Evidence:** `rg WebcamOverlay nyxos nyx-hyprland nyx-shell` finds nothing.
- **Affected versions:** `06b4d57a90`
- **User impact:** The webcam window probably tiles over the workspace and is recorded as a normal window.
- **Recommended correction:** Add the rule to NyxOS's Hyprland defaults, or have Capture set it at runtime (`hyprctl eval` window rule), as it already queries Hyprland.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The overlay floats and pins on the NyxOS VM.

### NYX-APP-CAPTURE-002: No action manifest; Capture's commands aren't reachable from `nyx`, Glimpse or the Assistant unless it is open

- **Component:** nyx-capture `apps/capture/src/control.rs`; nyx-packages `pkgs/nyx-capture.nix`
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** approved, not implemented
- **Description:** Settings and Files publish `share/nyx/actions` manifests (nyx-actions contract, `nyx-packages/lib/default.nix:133-154`); Capture offers its tools through the older live control channel only.
- **Expected:** Base apps follow the shared action registry (H05).
- **Actual:** no `nyx_actions` use; no `actions` in the package.
- **Reproduce / verify:** `ls /run/current-system/sw/share/nyx/actions` on NyxOS.
- **Evidence:** as above.
- **Affected versions:** `06b4d57a90`
- **User impact:** "Take a screenshot" from the Assistant needs Capture running.
- **Recommended correction:** Describe the existing tools with nyx-actions and D-Bus activation.
- **Effort:** M
- **Dependencies:** nyx-core nyx-actions
- **Verification criteria:** `nyx capture region` works with Capture closed.
