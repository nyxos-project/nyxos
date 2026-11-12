# Hyprland integration: patch inventory and maintenance risk

Handoff 10, section 8. Static review only: code, patches and git history, with read-only
git commands in `~/Projects/Hyprland` and its worktrees. Nothing was built or run, and
the VM was not touched. Raw command output is in
[evidence/logs/hyprland-patches-static.txt](evidence/logs/hyprland-patches-static.txt).

Revisions reviewed: nyx-hyprland `71afdcb`, nyx-packages `d69e87e`, nyxos `97f1573`,
Hyprland fork branch `nyx/0.57.2-fullscreen-spaces` at `0a31fa622` (upstream tag
`v0.57.2` = `11cbc6c57`), upstream `main` at `70ec30e71` (2026-11-11).

## Summary

- **What NyxOS ships:** Hyprland at upstream tag `v0.57.2` from Hyprland's own flake,
  with submodules, plus **13 patches** (`nyx-hyprland/patches/0.57.2`). Together they
  add **2,834 lines and remove 75**. Hyprtester files make up 418 of the added lines and
  are filtered out of the Nix build.
- **Where the code goes:** most of it is in 9 new files (2,294 lines). The rest (+512 −47)
  is hooks in 25 existing upstream files.
- **The five features:**
  1. touchpad workspace-swipe wrap-around (`gestures:workspace_swipe_wrap`);
  2. experimental virtual monitors (`hl.virtual_monitor`, 8 patches);
  3. a fullscreen app getting its own workspace (`misc:fullscreen_own_workspace`);
  4. top layers sliding with the workspace while swiping to a fullscreen app;
  5. tests.
  Window decorations (`nyx-decor`) are a Hyprland **plugin** in the same repository, not
  a patch.
- **Integrity: good.**
  - All 13 patches in the 0.57.2 series match the fork branch
    `nyx/0.57.2-fullscreen-spaces` commit for commit (`git patch-id --stable`).
  - The 0.57.1 and 0.56.2 series also match their branches.
  - The `arch/*.patch` files are links to the 0.57.2 series.
  - nyx-packages pins nyx-hyprland `71afdcb`, its `main`, and nyxos pins nyx-packages
    `d69e87e`, also current.
  - Nothing exists on the fork that isn't in the series, and nothing in the series is
    missing from the fork.
  - One caveat: the branch named `nyx/0.57.2` has only patches 0001 to 0010. Patches
    0011 to 0013 exist only on the worktree branch, and the docs still name `nyx/0.57.2`.
- **Nix build: clean.**
  - `pkgs/hyprland.nix` concatenates the series with hyprtester paths filtered out and
    appends it to `patches`.
  - It has no `postPatch` hacks. It only sets `GIT_TAG` and overrides
    `wayland-protocols` to 1.49.
  - CI builds `checks.hyprland`, so CI proves the series applies and compiles. Nothing
    runs its tests.
- **Reproducibility: good.**
  - The tag is locked to a revision with `submodules=1`.
  - `nixpkgs` follows through nyx-packages to nyxos's `nixos-26.05`, the same revision
    `ac588ef` in both locks, so the VM builds the derivation CI builds.
  - The version is declared twice: the flake URL's tag and a hard-coded series folder
    (NYX-HYPR-006).
- **Upstream drift today: low.** Replaying the 0.57.2 series onto upstream `main`
  (67 commits past the tag, 10 of them in files the series touches) merges with no
  textual conflict. Porting the 0.56.2 series to 0.57.2 conflicted in 9 files, so a
  minor release can cost far more than a patch release.
- **Main risks:**
  - Patch 0012 (fullscreen workspaces) is **on by default on every install** but hasn't
    run on 0.57.2.
  - Fullscreen workspaces are invisible to the Dock and Bar models.
  - Virtual monitors are reachable from Settings with an unexplained confirm-timeout
    hang.
  - No automated test of any patch runs anywhere.
- **Dead weight:** `patches/0.55.4` and `patches/0.57.1` are dead. `patches/0.56.2` is
  used only by the laptop's Arch package (`hyprland-nyx 0.56.2-1`). NyxOS doesn't use it,
  and `update.sh` can fall back to these older series without saying so (NYX-HYPR-007).

## Patch inventory (0.57.2 series, what NyxOS builds)

The sizes come from `git apply --numstat`. "Rebase risk" weighs how hot the touched
upstream files are and how far the hooks reach. "Tests" means what exists. **CI runs
none of them** (NYX-HYPR-004).

| # | File | What it changes (files, +/−) | User-visible feature | Nyx dependents | Documented | Rebase risk | Upstream equivalent / upstreamable | Tests |
|---|---|---|---|---|---|---|---|---|
| 0001 | `0001-gestures-add-workspace_swipe_wrap.patch` | `managers/input/UnifiedWorkspaceSwipeGesture.cpp`, `config/values/ConfigValues.cpp`, hyprtester `gestures.cpp` (3 files, +44 −5) | Touchpad swipe past the last workspace wraps to the first (`gestures:workspace_swipe_wrap`) | `nyxos/defaults/hyprland.toml:99` (on), `nyxos/modules/home/hyprland.nix:92-94`, `nyx-settings/.../backend/gestures.rs:146-151` (Loop around); all feature-detect with `hl.get_config(...) ~= nil` | Good commit message | **Low to medium**: small, but the swipe gesture file is also patched by 0005, 0012 and 0013 | None upstream: `workspace_swipe_forever`, `workspace_swipe_use_r` and `animations:workspace_wraparound` exist, but no swipe wrap. **Strong upstream PR candidate** (off by default, has a test) | hyprtester `gestures.cpp` (fixed for 0.57 text by 0011) |
| 0002 | `0002-output-add-virtual-region-partitioning.patch` | New `output/VirtualRegions.{cpp,hpp}`, new gtest `tests/helpers/VirtualRegions.cpp` (3 files, +219 −0) | None alone; region geometry for virtual monitors | Through 0003 | Good | **Low**: new files only | Only together with 0003 | gtest `VirtualRegions.*`; not built in Nix (`withTests` is false) |
| 0003 | `0003-output-add-virtual-monitors.patch` | New `output/VirtualMonitorManager.{cpp,hpp}` (~1,100 lines); hooks in `Compositor.cpp`, `output/Monitor.{cpp,hpp}`, `config/lua/ConfigManager.cpp`, `LuaBindingsConfigRules.cpp`, `MonitorRuleManager.cpp`, `ConfigValues.cpp`, `desktop/view/LayerSurface.cpp`, `managers/ProtocolManager.cpp`, `state/MonitorLayoutController.cpp`, `state/MonitorState.cpp` (13 files, +1260 −11) | `hl.virtual_monitor`: one output split into 1 to 3 monitors; off unless `experimental:virtual_monitors`, and `HYPRLAND_NO_VIRTUAL_MONITORS` kills it | nyx-core `nyx-desktop/src/virtual_monitors.rs` and `event.rs:58,138`; nyx-settings `sections/virtual_monitors.rs` and `bin/nyx-display.rs`; `nyx display virtual` (nyxos `pkgs/nyx-cli`); `nyxos/modules/home/hyprland.nix:302-309`; per-region Bar, Dock, widgets and Shell Core (`RegionState`) | Good commit message; `docs/virtual-monitors.md` covers the design | **High**: core monitor lifecycle, layout arrange, wl_output globals, layer placement. It reuses the mirror code paths (`isHiddenFromLayout`) | None upstream. Could be proposed upstream as experimental, but it's large. The `isHiddenFromLayout()` abstraction alone is a neutral refactor upstream could take | hyprtester `virtual_monitors.cpp` (0008); manual VM run on 2026-11-10 |
| 0004 | `0004-render-composite-virtual-regions-on-their-host.patch` | `render/Renderer.{cpp,hpp}` (`renderVirtualRegions`, `damageMirrorsWith`), `render/scene/MonitorScene.cpp`, `output/MonitorResources.cpp`, `output/OutputCommitCoordinator.cpp` (5 files, +33 −5) | Regions drawn side by side on the physical output | Through 0003 | Good | **High**: render path and commit coordinator; `Renderer.cpp` has 5 upstream commits since the tag | Part of 0003 | Covered only by hyprtester geometry checks |
| 0005 | `0005-workspaces-per-region-workspace-selector-and-pointer.patch` | `state/workspace/Resolver.cpp` (`v~N`), `config/shared/actions/ConfigActions.cpp`, swipe gesture (3 files, +16 −1) | `v~N` selector; `virtual_monitors:workspace_target = pointer` | nyx-desktop `virtual_monitors.rs:338-343` (generated Super+1…0 binds) | Good | **Medium**: Resolver and actions change upstream regularly | Part of 0003 | hyprtester (`v~N`, `m±1` in regions) |
| 0006 | `0006-virtual-monitors-add-merge-restore-physical-fullscre.patch` | `config/lua/bindings/LuaBindingsDispatchers.cpp` (1 file, +97 −0) | `hl.dsp.virtual_monitor.{merge,restore,toggle_merge,fullscreen,confirm,disable_all}`, `hl.dsp.window.fullscreen({mode="physical"})` | nyx-desktop `virtual_monitors.rs:613-628`; Settings; `nyx display virtual disable --all` | Good | **Low to medium**: registration lists conflict easily, but trivially | Could become plugin dispatchers (`addDispatcherV2`) if 0003 were a plugin; it isn't | hyprtester |
| 0007 | `0007-ipc-expose-virtual-monitors.patch` | `ipc/s1/Commands.cpp`, `config/lua/objects/LuaMonitor.cpp` (2 files, +89 −2) | `hyprctl monitors` gains a `virtual` field; `hyprctl virtualmonitors`; socket2 `virtualmonitor`/`virtualmonitorv2`; Lua `is_virtual`, `virtual_host`, …; `output remove` refuses regions | nyx-desktop (`j/virtualmonitors`, `virtualmonitorv2`); nyx-settings `role()` reads `virtual.role` | Good | **Low to medium**: `Commands.cpp` has 2 upstream commits since the tag | Additive IPC: the JSON field and events are new and existing fields are unchanged | hyprtester |
| 0008 | `0008-hyprtester-add-virtual-monitor-tests.patch` | New hyprtester `virtual_monitors.cpp` (1 file, +226 −0) | None | None | **Subject only, no body** | Low (filtered out of the Nix build) | n/a | Is the test. `docs/testing.md:65-70`: only the first three tests passed; `virtualMonitorsRejectsBadLayouts` hung |
| 0009 | `0009-virtual-monitors-workspaces-0-leaves-numbering-to-th.patch` | `VirtualMonitorManager.{cpp,hpp}` (2 files, +19 −3) | `workspaces = 0` for configs that number workspaces themselves (Omarchy); merge remembers each workspace's region | nyx-desktop generated Lua (Omarchy path) | Good | Low: own files | n/a | None specific |
| 0010 | `0010-virtual-monitors-fixes-from-the-first-run-on-a-NyxOS.patch` | `VirtualMonitorManager.{cpp,hpp}`, `LuaBindingsDispatchers.cpp`, `config/shared/workspace/WorkspaceRuleManager.{cpp,hpp}` (adds `remove()`) (5 files, +157 −15) | Merge and restore correctness, focus and pointer restore, no rule leak | As 0003 | Very good (bulleted rationale) | **Low to medium**: `WorkspaceRuleManager::remove` is a new upstream-file API | `remove()` is upstreamable on its own | Manual VM run (split, `v~N`, merge, restore, physical fullscreen, `disable_all`) |
| 0011 | `0011-hyprtester-workspace_swipe_wrap-checks-the-0.57-acti.patch` | hyprtester `gestures.cpp` (1 file, +4 −4) | None | None | Good | Low | n/a (folding it into 0001 would make one clean commit) | Is the test |
| 0012 | `0012-fullscreen-misc-fullscreen_own_workspace.patch` | New `managers/fullscreen/FullscreenSpaces.{cpp,hpp}` (443 lines); hooks in `Compositor.cpp`, `ConfigValues.cpp`, `output/Monitor.cpp` (`changeWorkspace` slide direction), `state/workspace/Resolver.cpp` (`m±1` order), swipe gesture; new hyprtester `fullscreenSpaces.cpp` (8 files, +633 −16) | A truly fullscreen window moves to a named workspace `fullscreen-<origin>-<n>` right after its origin; it goes back when fullscreen ends or the window closes. `fullscreen-in-place` tag opts out | **On by default:** `nyxos/modules/home/hyprland.nix:105-108` | Good commit message; no doc in `docs/` | **High**: fullscreen and workspace code changed heavily in 0.57 (the 0.56.2 to 0.57.2 port of this area conflicted in `FullscreenHandler.cpp`, `Monitor.cpp`, `Compositor.cpp`, the swipe gesture and `MiscFunctions.cpp`) | None upstream. Partly plugin-able: the move-on-fullscreen part can be event-driven, but the `m±1` order and slide direction need core hooks | hyprtester `fullscreenSpaces.cpp` (149 lines), never run on 0.57.2 (nyx-hyprland `337758d`, `71afdcb`) |
| 0013 | `0013-layers-top-layers-slide-with-the-workspace-when-it-m.patch` | `render/Renderer.cpp` (`renderLayer`, new `topLayerSlideOffset`), swipe gesture (2 files, +37 −13) | Bars slide out with the workspace when swiping to a fullscreen app instead of covering it | Visual only, for every top-layer client (Nyx Bar, Dock) | Good | **High**: `renderLayer` is the render hot path | No upstream equivalent; arguably an upstream bug fix and upstreamable on its own (applies without 0012) | None |

### Other series folders

| Folder | Patches (+/−) | Used by | Verdict |
|---|---|---|---|
| `patches/0.55.4` | 1: swipe wrap (+8 −4) | Nothing. It was nixpkgs' Hyprland 0.55.4 era (`docs/audit.md:13-15`) | Dead; delete |
| `patches/0.56.2` | 4: swipe wrap; a backport of upstream `815e3a822` (top layers stay below fullscreen, in upstream since v0.57.0); fullscreen own workspace; layer slide (+604 −39) | **The laptop's** `hyprland-nyx 0.56.2-1` (built 2026-11-11 18:49, contains `misc:fullscreen_own_workspace`). Not NyxOS | Live for the laptop only; delete when the laptop moves to 0.57.2 |
| `patches/0.57.1` | 8: identical patch IDs to 0.57.2's 0001 to 0008 (+1984 −24) | Nothing | Dead; delete |

## Maintenance-risk analysis

**Footprint.** The 0.57.2 series touches 25 existing upstream files (+512 −47) and adds 9
files (+2,294). New files rarely conflict. The cost sits in the hooks:

- **High churn:**
  - `render/Renderer.cpp` (0004 and 0013; 5 upstream commits since the tag);
  - `output/Monitor.cpp` (0003 and 0012; 3);
  - `config/values/ConfigValues.cpp` (0001, 0003 and 0012; 5: option-list neighbours,
    trivial conflicts);
  - `managers/input/UnifiedWorkspaceSwipeGesture.cpp` (0001, 0005, 0012 and 0013: four
    patches stacked on one file).
- **Core lifecycle:** `Compositor.cpp` (manager init), `state/MonitorLayoutController.cpp`,
  `state/MonitorState.cpp`, `managers/ProtocolManager.cpp`, `desktop/view/LayerSurface.cpp`.
  These are small hooks, but they sit where a mirror was previously the only special case.
- **Workspace resolution:** `state/workspace/Resolver.cpp` (0005 and 0012) and
  `config/shared/actions/ConfigActions.cpp`.

**What a release costs, by the evidence so far:**

- **Patch release (0.57.1 to 0.57.2):** the 0.57.1 series applied to 0.57.2 as is.
  `update.sh` handled it, and only a hyprtester string changed (0011). Expect hours.
  Most of that time is the runtime re-check, not the rebase.
- **Minor release (0.56 to 0.57):** the 0.56.2 fullscreen and layer series conflicted in
  9 files when replayed onto 0.57.2 (`merge-tree`, evidence log), partly because 0.57
  moved to Lua config and reorganised fullscreen handling. Virtual monitors were written
  directly on 0.57.1. Expect days for 0.58: rebasing the hot hooks, then the manual
  virtual-monitor checklist and fullscreen checks, which nothing automates today.
- **Today:** the series replays onto upstream `main` (`70ec30e`) with no textual conflict.
  That says nothing about semantic breakage; only runtime tests would catch that.

**How to reduce it (without replacing Hyprland):**

1. **Upstream 0001 (swipe wrap).** It's small, off by default, consistent with upstream's
   existing `m±1` wrap, and already has a hyprtester case. That removes one of the four
   patches on the swipe-gesture file.
2. **Upstream 0013 as a bug fix.** Bars covering a fullscreen app and then fading out
   happens on stock Hyprland too, whenever you swipe to a workspace with a fullscreen
   window. Upstream may prefer a different mechanism; either way the render-path patch
   goes away.
3. **Upstream the neutral refactors under virtual monitors.** These are
   `CMonitor::isHiddenFromLayout()` (one predicate where `isMirror()` was checked) and
   `CWorkspaceRuleManager::remove()`. With those upstream, 0003 and 0004 shrink to
   `VirtualMonitorManager` plus a few calls. Open an upstream discussion on virtual
   monitors as an experimental feature, since it reuses mirror and headless machinery
   upstream already has.
4. **Move what can go to the plugin API.** nyx-decor already shows the plugin path works
   and is pinned to the exact build (`nyx-packages/pkgs/nyx-decor.nix`).
   - 0012's "move the window on fullscreen, move it back on leave or close" can be
     event-driven in a plugin, with plugin dispatchers.
   - Its `m±1` ordering and slide direction need a small upstream hook, such as a
     workspace-order provider. Ask for that hook instead of carrying `Resolver.cpp` and
     `Monitor::changeWorkspace` edits.
   - Function hooks (`createFunctionHook`) are possible but no cheaper to maintain than
     patches.
5. **Process:**
   - Push the `nyx/*` fork branches to a project fork; today they exist only in the
     laptop's checkout (no remote but upstream).
   - Keep one canonical branch per version, and rename it so `nyx/0.57.2` is the full
     13-patch series.
   - Add a CI job that builds `hyprland-with-tests` and runs the gtests, plus hyprtester
     in a headless VM. `docs/testing.md:3-13` explains why hyprtester must not run in a
     desktop session; CI is the safe place for it.

**Other risks noted (no separate finding):**

- `LayerSurface::create` (fork `src/desktop/view/LayerSurface.cpp:55`) dereferences
  `m_virtual.regions.front().lock()` without a null check. It is only reachable for a
  layer surface created on a split host whose first region has gone away "on its own"
  (`VirtualMonitorManager.cpp:109`) before the deferred reconcile runs. That needs a
  client holding the host's old `wl_output`, so the likelihood is low. A null check is
  cheap.
- `CFullscreenSpaces::compare` builds a full navigation order on every resolution
  involving a fullscreen workspace (`FullscreenSpaces.cpp:145`). That's negligible at
  normal workspace counts.
- The Nix build applies the series as one concatenated patch, so a failure reports
  against "nyx-hyprland-series.patch" rather than the numbered patch
  (`nyx-packages/pkgs/hyprland.nix:28-32`).
- `?? subprojects/hyprland-protocols/` in the fork checkout is an untracked submodule
  directory and harmless.

## Findings

### NYX-HYPR-001: Fullscreen-own-workspace is on by default but unverified on 0.57.2

- **Component:** nyx-hyprland `patches/0.57.2/0012-…`, `0013-…`; nyxos `modules/home/hyprland.nix`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Every NyxOS install turns on `misc:fullscreen_own_workspace`. With it
  on, every truly fullscreen window (games, video players, browsers, XWayland apps) moves
  to a new named workspace and comes back afterwards. The 0.57.2 port (0012) and the
  layer slide (0013) have been compiled but not run.
- **Expected:** Section 8 asks for compatibility with the selected Hyprland version, plus
  input behaviour, workspace state consistency and no compositor crashes. A default-on
  change to core window behaviour should be verified on the shipped version.
- **Actual:**
  - `nyxos/modules/home/hyprland.nix:105-108` enables it whenever the option exists.
  - nyx-hyprland commit `337758d` says "0.57.2 still needs a full build and hyprtester run
    in the NyxOS VM".
  - `71afdcb` says 0013 "compiles … not run in the VM yet". nyx-packages `fd95802` later
    built it in the VM; nothing records a runtime check.
  - The laptop runs the 0.56.2 version, not 0.57.2.
  - The behaviour reaches into the Resolver, the slide animation and the swipe gesture
    (fork `src/managers/fullscreen/FullscreenSpaces.cpp:230,270`).
- **Reproduce / verify:** static; confirm at runtime (see the checks below).
- **Evidence:** `nyxos/modules/home/hyprland.nix:105-108`; nyx-hyprland `git log 337758d 71afdcb`; `evidence/logs/hyprland-patches-static.txt`
- **Affected versions:** nyx-hyprland `71afdcb`, nyxos `97f1573`
- **User impact:** If it misbehaves on 0.57, fullscreen breaks on every install. The
  likely failure modes are lost windows, a wrong workspace after leaving fullscreen,
  games that toggle fullscreen at start landing elsewhere, and a fullscreen dialog
  separated from its parent.
- **Recommended correction:**
  1. Run hyprtester `fullscreenSpaces` and `gestures` in the VM or CI.
  2. Do the manual check: F11 in a browser, mpv, an XWayland game, a fullscreen app
     opening a dialog, closing while fullscreen, and swiping across a fullscreen
     workspace with wrap on.
  3. Until that passes, gate the default behind a NyxOS option that is off.
- **Effort:** S
- **Dependencies:** NYX-HYPR-002, NYX-HYPR-004
- **Verification criteria:** hyprtester `fullscreenSpaces` passes on the 0.57.2 build, and
  the manual matrix is recorded in nyx-hyprland `docs/testing.md`.

### NYX-HYPR-002: Fullscreen workspaces are invisible to the Dock and Bar models

- **Component:** nyx-core `crates/nyx-desktop/src/model.rs`; nyx-dock; nyx-bar; nyx-shell-core
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Patch 0012 moves a fullscreen window to a named workspace
  `fullscreen-<origin>-<n>`. nyx-desktop only counts numbered workspaces 1 to 10 (or a
  virtual monitor's own) as the user's. A fullscreen window therefore sits on a
  non-user workspace.
- **Expected:** Patched compositor features and the shell's desktop model agree. Section 8
  "Workspace state inconsistencies" and section 5 (shell) call for that.
- **Actual:**
  - `Desktop::workspace_number` falls back to `user_number(id, name)`
    (`nyx-core/crates/nyx-desktop/src/model.rs:26-32,584-601`), which returns `None` for
    a named workspace.
  - The Dock counts only windows on user or special workspaces
    (`nyx-dock/crates/nyx-dock-core/src/items.rs:33-35`), so a fullscreen app drops out
    of the running-apps count.
  - The Bar lists only workspaces with a number (`nyx-bar/apps/bar/src/bar.rs:375`), so
    no workspace is shown active while one is fullscreen.
  - Shell Core marks such a workspace `user: false`
    (`nyx-shell/crates/nyx-shell-core/src/state.rs:58-59`).
  - Nothing in the Nyx repos recognises the `fullscreen-` prefix (grep).
- **Reproduce / verify:** static; confirm at runtime. Fullscreen an app on workspace 2,
  swipe back to 2, and check the Dock's running indicator and the Bar's active workspace.
- **Evidence:** as above; fork `src/managers/fullscreen/FullscreenSpaces.cpp:270`
- **Affected versions:** nyx-core `9187295`, nyx-dock `0cd8173`, nyx-bar `4a84c75`, nyx-hyprland `71afdcb`
- **User impact:** A fullscreen app looks closed in the Dock. Workspace indicators lose the
  current position. Per-workspace window lists may omit it.
- **Recommended correction:** Teach nyx-desktop that `fullscreen-<origin>-<n>` belongs to
  `<origin>`: its number is the origin's, and it counts as the user's. The compositor
  could also expose it, for example with a `fullscreenOrigin` field in
  `hyprctl workspaces -j`.
- **Effort:** S
- **Dependencies:** NYX-HYPR-001
- **Verification criteria:** a unit test in nyx-desktop for a named fullscreen workspace;
  at runtime, the Dock and Bar show the app and its workspace while it is fullscreen.

### NYX-HYPR-003: Virtual monitors exposed in Settings despite an unexplained confirm-timeout hang

- **Component:** nyx-hyprland patches 0002 to 0010; nyx-settings `apps/settings/src/sections/virtual_monitors.rs`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Virtual monitors are off by default and labelled experimental in the
  compositor. Settings › Displays still shows the section on any NyxOS install, with no
  experimental label. Risky changes go through Hyprland's confirm-and-revert timer, which
  hung in the only test of a second revert cycle.
- **Expected:** Section 8 asks for virtual monitor functionality "where implemented", plus
  recovery for display changes. Experimental features shouldn't be presented as
  finished.
- **Actual:**
  - Settings shows the section whenever `virtualmonitors` answers
    (`virtual_monitors.rs:37-40`) and uses a confirm timeout for risky changes
    (`virtual_monitors.rs:174`).
  - `nyx-hyprland/docs/testing.md:68-70` records that `virtualMonitorsRejectsBadLayouts`
    "passed the first confirm-timeout revert, then hung on the second … unexplained".
  - The manual checklist is still unchecked: "None of these has been checked yet"
    (`docs/testing.md:97`).
  - The feature has never run on a real ultrawide (`docs/virtual-monitors.md:7-11`).
  - The known limitations include one frame of extra latency, no VRR, HDR or direct
    scanout while split, and no whole-screen capture (`docs/virtual-monitors.md:176-190`).
- **Reproduce / verify:** static; confirm at runtime. In the VM, apply a layout with
  `confirm = 5` twice without confirming, and check that both revert and the compositor
  stays responsive.
- **Evidence:** as above
- **Affected versions:** nyx-hyprland `71afdcb`, nyx-settings `7e76622`
- **User impact:** A user can split their screen from Settings. If the revert hangs, the
  display stays in an unconfirmed layout. The recovery paths are `nyx display virtual
  disable --all` from a TTY or SSH, or `HYPRLAND_NO_VIRTUAL_MONITORS=1`, neither of which
  is obvious.
- **Recommended correction:**
  1. Explain and fix the second-revert hang.
  2. Label the section Experimental in Settings, or hide it behind an option, until the
     checklist passes on real hardware.
  3. Document the recovery path in the user docs.
- **Effort:** M
- **Dependencies:** NYX-HYPR-004
- **Verification criteria:** `virtualMonitorsRejectsBadLayouts` passes repeatedly in CI,
  and the manual checklist in `docs/testing.md` is filled in.

### NYX-HYPR-004: No automated test of any compositor patch runs anywhere

- **Component:** nyx-packages `pkgs/hyprland.nix`, `.github/workflows/ci.yml`; nyx-hyprland
- **Category:** CI
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The series carries a gtest (0002) and three hyprtester suites (0001 and
  0011, 0008, 0012). CI only checks that the series applies and compiles.
- **Expected:** Section 8: patch isolation, workspace looping, virtual monitors and
  compatibility verified. A patched core component needs regression tests on each
  rebase.
- **Actual:**
  - `pkgs/hyprland.nix:26-31` strips `hyprtester/*` from the series.
  - Hyprland's flake builds with `withTests ? debug`, which is false
    (`nix/default.nix:55` at `v0.57.2`), so `tests/helpers/VirtualRegions.cpp` is never
    compiled.
  - CI runs `nix build` of `checks`, which only builds the packages
    (`ci.yml:43,86`; `flake.nix:319-323`).
  - nyx-hyprland has no CI. `docs/testing.md` records partial manual runs only.
- **Reproduce / verify:** `nix eval .#checks.x86_64-linux --apply builtins.attrNames` in
  nyx-packages lists no Hyprland test check.
- **Evidence:** as above
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** Indirect. Rebases onto new Hyprland releases ship without regression
  checks for workspace looping, fullscreen workspaces or virtual monitors.
- **Recommended correction:** Add a nyx-packages check that builds Hyprland with
  `withTests = true` and the full series (hyprtester included), and runs
  `hyprland_gtests`. Add a NixOS VM test that runs hyprtester's `gestures`,
  `fullscreenSpaces` and `virtual_monitors` suites headless.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** CI fails when a patch's test fails.

### NYX-HYPR-005: Patch-series documentation has drifted from the series

- **Component:** nyx-hyprland `docs/virtual-monitors.md`, repository root; nyx-packages `pkgs/hyprland.nix`; nyxos `modules/nixos/desktop.nix`; Hyprland fork branches
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:** The canonical description of the series is out of date. nyx-hyprland
  has no README.
- **Expected:** Section 8 risk "Undocumented patches": every patch is described where
  maintainers look.
- **Actual:**
  - `docs/virtual-monitors.md:140` says the series is branch `nyx/0.57.2`, but that branch
    has only 0001 to 0010. The full series is `nyx/0.57.2-fullscreen-spaces`.
  - The patch table there stops at 0010 (`:153`).
  - 0012 and 0013 are documented only in their commit messages.
  - `pkgs/hyprland.nix:1-4` lists only swipe wrap and virtual monitors.
  - `nyxos/modules/nixos/desktop.nix:34` says the package is "with workspace swipe
    wrap-around".
  - Patch 0008 has a subject and no body.
  - The `nyx/*` branches exist only in `~/Projects/Hyprland` (its only remote is upstream).
- **Reproduce / verify:** `git -C ~/Projects/Hyprland rev-list --count v0.57.2..nyx/0.57.2` gives 10; the series has 13
- **Evidence:** `evidence/logs/hyprland-patches-static.txt`
- **Affected versions:** nyx-hyprland `71afdcb`
- **User impact:** None directly. A maintainer rebasing from `nyx/0.57.2` would drop three
  patches, including one that is on by default.
- **Recommended correction:**
  - Add a README with the per-version patch table (this inventory).
  - Make `nyx/0.57.2` point at the full series.
  - Push the branches to a project fork.
  - Update the two Nix comments.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The README table matches `ls patches/<newest>`, and
  `nyx/<version>` equals the exported series by patch ID.

### NYX-HYPR-006: Hyprland version and patch series are declared separately, and Nix applies patches with fuzz

- **Component:** nyx-packages `flake.nix`, `pkgs/default.nix`, `pkgs/hyprland.nix`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Two places declare the Hyprland version, and nothing ties them together.
  Nix's default `patch` also allows fuzz, while `update.sh` deliberately refuses it.
- **Expected:** Section 8 asks for build reproducibility and compatibility with the
  selected Hyprland version. Changing the tag without changing the series should fail
  loudly.
- **Actual:**
  - `flake.nix:28` pins `ref=refs/tags/v0.57.2`.
  - `pkgs/default.nix:24` hard-codes `patches/0.57.2`.
  - `pkgs/hyprland.nix:42-43` appends the series with no `patchFlags`, so the default
    fuzz applies.
  - `update.sh:123-131` uses `patch -F0` ("guessed context is not" fine).
- **Reproduce / verify:** static
- **Evidence:** as above
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** None today. A future tag bump could apply the old series with fuzz and
  build a subtly wrong compositor.
- **Recommended correction:** Derive the folder from `hyprland.version`, or assert that the
  two match. Set `patchFlags = [ "-p1" "-F0" ]` on the override.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Bumping the tag alone fails evaluation or the patch phase.

### NYX-HYPR-007: Stale series folders, and update.sh can silently fall back to an older series

- **Component:** nyx-hyprland `patches/0.55.4`, `patches/0.57.1`, `patches/0.56.2`, `update.sh`, `arch/PKGBUILD`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** verified
- **Description:**
  - Two series folders are unused.
  - A third is used only by the laptop's Arch package, which ships a different
    compositor feature set from NyxOS.
  - `update.sh` picks the newest series that applies cleanly, so an old, smaller series
    can be chosen without warning.
- **Expected:** One maintained series per shipped version. A package update never drops
  patches silently.
- **Actual:**
  - `patches/0.57.1` equals 0.57.2's 0001 to 0008 by patch ID.
  - `patches/0.55.4` is used by nothing.
  - The laptop runs `hyprland-nyx 0.56.2-1`, built 2026-11-11 with the 0.56.2 series: no
    virtual monitors. That package reuses `pkgrel=1` from the 2026-11-04 build with
    different content.
  - `arch/PKGBUILD` is now 0.57.2, so the installed package can't be rebuilt from the
    repository.
  - `update.sh:134-142` tries series newest first and takes the first that applies. If
    0.57.2's fails on a future release but 0.55.4's applies, `hyprland-nyx` ships with
    swipe wrap only.
- **Reproduce / verify:** `pacman -Q hyprland-nyx`; read `update.sh:134-142`
- **Evidence:** `evidence/logs/hyprland-patches-static.txt`
- **Affected versions:** nyx-hyprland `71afdcb`
- **User impact:** Omarchy and laptop users only. The laptop and VM compare differently
  because their compositors differ, and a future update could drop features silently.
- **Recommended correction:**
  - Delete `0.55.4` and `0.57.1`.
  - Move the laptop to 0.57.2, then delete `0.56.2`.
  - Make `update.sh` try only the newest series (and rebase it), and bump `pkgrel` when
    the series changes.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `ls patches` shows one folder, and `update.sh` stops instead
  of choosing an older series.

### NYX-HYPR-008: Layer-slide render hook runs for every top layer on every frame

- **Component:** Hyprland fork `src/render/Renderer.cpp` (patch 0013)
- **Category:** performance
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The hook isn't gated by `misc:fullscreen_own_workspace`. It also forces
  layers to full opacity while sliding.
- **Expected:** Section 8 risk "Performance regressions". Patches that only matter with an
  option should cost nothing without it.
- **Actual:**
  - `renderLayer` calls `topLayerSlideOffset()` for every mapped top-layer surface that
    isn't above fullscreen, on every render (`Renderer.cpp:1047-1052`).
  - Each call walks every workspace and queries fullscreen modes (`:1016-1037`).
  - During a slide it sets `fadeAlpha = 1` (`:1077`), which overrides a layer's own fade,
    for example one that is closing.
- **Reproduce / verify:** static; confirm at runtime (frame time with Bar and Dock during
  swipes; a layer closing mid-swipe)
- **Evidence:** fork `nyx/0.57.2-fullscreen-spaces:src/render/Renderer.cpp:1016-1077`
- **Affected versions:** fork `0a31fa622`, nyx-hyprland `71afdcb`
- **User impact:** Probably negligible cost, given few layers and workspaces, but it's on
  the hot path. A possible flash of a closing bar during a swipe.
- **Recommended correction:** Compute the offset once per monitor per frame, return early
  when no fullscreen workspace is visible or animating, and keep the layer's own fade
  when it is unmapping.
- **Effort:** S
- **Dependencies:** NYX-HYPR-001
- **Verification criteria:** The offset is computed once per frame (trace or log), with
  no visual change in the swipe check.

### NYX-HYPR-009: The screen-sharing portal isn't the one the Hyprland flake pins

- **Component:** nyxos `modules/nixos/desktop.nix`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** NyxOS takes Hyprland from Hyprland's flake (at 0.57.2) but keeps
  nixpkgs' `xdg-desktop-portal-hyprland`.
- **Expected:** Section 8 asks for compatibility with the selected Hyprland version.
  Hyprland's own NixOS module pairs the compositor with its flake's portal
  (`nix/module.nix:128` at `v0.57.2`: `portalPackage = …xdg-desktop-portal-hyprland`).
- **Actual:**
  - `desktop.nix:31-36` sets only `programs.hyprland.package`.
  - The VM's journal shows `xdg-desktop-portal-hyprland-1.3.12` from nixpkgs
    (`evidence/logs/runtime-system-journal-errors.txt.gz`, duplicate-name warnings).
  - nyx-packages' lock has the flake's `xdph` at `85450448` but doesn't use it.
- **Reproduce / verify:** static; confirm at runtime: portal screen share of a window and
  of a screen (and of a virtual-monitor region) in the VM
- **Evidence:** as above
- **Affected versions:** nyxos `97f1573`
- **User impact:** Possibly none. If the protocols drift apart, screen sharing or the
  screenshot portal could break.
- **Recommended correction:** Export the flake's `xdg-desktop-portal-hyprland` from
  nyx-packages and set `programs.hyprland.portalPackage` to it, or record that 1.3.12 was
  verified with 0.57.2.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Screen share works in the VM with the chosen portal.

## Runtime checks for the VM (in order of value)

1. **Fullscreen workspaces (NYX-HYPR-001, 002).**
   - Fullscreen a browser (F11), mpv and an XWayland game from workspace 2.
   - Check that `hyprctl workspaces -j` shows `fullscreen-2-1`.
   - Leave fullscreen and close while fullscreen; the window must return to 2.
   - Swipe across it with wrap on.
   - Watch the Dock's running indicator and the Bar's active workspace, and check that
     the bars slide out (0013).
2. **Virtual monitor confirm and revert (NYX-HYPR-003).** Twice in a row, apply
   `hl.virtual_monitor({ output = …, count = 2, confirm = 5 })` without confirming. Both
   must revert and Hyprland must stay responsive. Then run `disable_all`.
3. **Workspace looping (0001) and screen share (NYX-HYPR-009).**
   - Swipe past workspace 10 to 1 and back. Try `m+1` from the keyboard on the last
     workspace.
   - Share a window and the screen through the portal.

## Runtime results (Phase D, dev VM)

- 0012 fullscreen own workspace: a fullscreened window moved to `fullscreen-1-1`
  (hyprctl reports `"id": null` for it), returned to workspace 1 when leaving
  fullscreen, and the named workspace disappeared when the window closed while
  fullscreen (logs/hyprland-fullscreen.txt). Behaviour with XWayland games, mpv and
  browsers, and the Dock/Bar view of these workspaces (NYX-HYPR-002), not exercised.
- Workspace wrap: focus `m+1` from 5 → 1 and `m-1` from 1 → 5.
- Version string: `Hyprland 0.57.2 built from branch unknown at commit 11cbc6c… dirty`
  (the patched tag build).
- Virtual monitors (NYX-HYPR-003) and screen sharing through the portal: not exercised.
