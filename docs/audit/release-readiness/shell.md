# Shell assessment: Shell Core and the Quickshell components

Handoff 10 §6 and §7, static review on 2026-11-12 (no builds, no VM). Revisions as in
[architecture.md](architecture.md). Status values follow handoff 10 §2; since nothing
was run here, nothing below is "verified". nyx-shell's own VM validation
(`docs/NYXOS.md:104-133`, 2026-11-07) predates the move of the Bar, Dock, Control Center
and Glimpse into `nyx-shell-qs`, so it doesn't cover the current arrangement.

## Shell Core

`nyx-shell-core` (8k lines of Rust, 107 tests per the inventory; `crates/nyx-shell-core/tests/`
runs a fake Hyprland and a burst test). One tokio task owns all state (`server.rs:120-147`).

| Responsibility (H10 §6) | Status | Evidence |
| --- | --- | --- |
| Session lifecycle | implemented, not verified | single instance by flock, stale socket replaced (`session.rs:24-45`); `READY=1` after first snapshot or 2 s, else `degraded` (`core.rs:255-260`); `Shutdown` to clients, socket removed (`core.rs:262-269`, `server.rs:129-148`) |
| Component registration | implemented, not verified; little used | manifests, state machine, duplicate refusal (`registry.rs:61-72`); only OSD, window menu and opt-in Aura register (NYX-ARCH-003) |
| Overlay coordination | implemented, not verified | declarative policies, groups, lock and fullscreen rules, pins (`overlay.rs`); `Panel1` bridge for GTK panels (`core.rs:233-240`); used by Glimpse, OSD, window menu only (NYX-ARCH-002) |
| Focus management | implemented, not verified | restore only if the window still exists, is shown, nothing else took focus, 500 ms debounce (`focus.rs`, `docs/ARCHITECTURE.md:152-164`) |
| Monitor, workspace, window state | implemented, not verified | `nyx-desktop` watcher, generation + deltas, resync on gap (`state.rs`, `proto/desktop.rs:9-138`); monitor layout changes through the `nyx-monitors` custom event (`nyxos/modules/home/hyprland.nix:270`) |
| Shortcut routing | implemented, not verified; unused by shipped keys | fixed table (`actions.rs:53-58`); owned file with conflict check (`apps/shellctl/src/shortcuts.rs`); NYX-ARCH-004 |
| Theme and configuration events | implemented, not verified | theme snapshot follower (`theme.rs`), layered `shell` domain with per-section fallback (`config.rs`), inotify (`server.rs:405-475`) |
| IPC versioning | implemented, not verified | `v` range checked per request (`server.rs:391-396`), `Hello` negotiates min/max (`core.rs:285-304`) |
| Component restart | systemd only | `Restart=on-failure`, `RestartSec=1`, 5 starts in 60 s (`data/nyx-shell-core.service:6-7,13-14`); registry reports, never restarts (`registry.rs:3-5`) |
| Peer authorization | implemented, not verified | uid check at accept (`server.rs:276-280`); capabilities by executable (`peer.rs:46-62`); same-user Quickshell gets UI rights by design (`docs/SECURITY.md:72-75`) |

## Quickshell components

Status per handoff 03 feature. "QML" means the code is in the shipped `share/nyx-shell/components`
folder; "GTK" means NyxOS still runs the GTK front end.

### Dock (QML on NyxOS: `nyx-packages/pkgs/nyx-dock.nix:26-30`)

| H03 §5 feature | Status | Evidence |
| --- | --- | --- |
| Floating bottom layout, 48 px default | implemented, not verified | `qml/Dock/DockWindow.qml:17-20,141-151`; `crates/nyx-dock-core/src/config.rs:190-192` |
| Magnification off by default | not implemented (no magnification exists) | no `magnif` in `nyx-dock-core`; the default holds trivially |
| Intelligent hide (overlap, fullscreen, interaction, popovers) | implemented, not verified | backend `crates/nyx-dock-core/src/hide.rs:1,62-83`; QML reports hover, holds and geometry (`DockWindow.qml:60-112`) |
| Per-monitor configuration by stable id | implemented, not verified | `apps/dock-backend/src/main.rs:183` (`config.for_monitor(stable_id…)`) |
| Window previews | implemented, not verified | `qml/Dock/PreviewPopup.qml`; thumbnails from the backend's capture (`MIGRATION.md:231`) |
| Right-click Quick Panels | implemented, not verified | `qml/Dock/CardPopup.qml`, `DockMenu.qml` |
| Folders and stacks (fan, grid, list, direct open) | implemented, not verified | `qml/Dock/FolderPopup.qml:4,14-18`, `FolderTile.qml` |
| Drag and drop (reorder, unpin, files onto apps) | implemented, not verified | `Drag`/`DropArea` in `AppTile.qml`, `DockBar.qml`, `FolderTile.qml`, `FolderPopup.qml:64` |
| Swipe following | partial | plugin not built on NyxOS; the dock hides after a swipe ends (`pkgs/nyx-dock.nix:4-5`; NYX-SHELL-007) |
| Shell Core window state, shared overlay policy | not implemented | backend watcher `main.rs:934`; raw `PanelWindow` (NYX-ARCH-001, -002) |
| Keyboard accessibility | not implemented | dock surface keyboard `None` except open popups (`DockWindow.qml:134,186`); tiles are `MouseArea`s (NYX-SHELL-005) |
| Multi-monitor | implemented, not verified | one `DockWindow` per backend monitor present in `Quickshell.screens` (`qml/Dock/Main.qml:24-25`) |

### Control Center (QML on NyxOS: `pkgs/nyx-control-center.nix:40-44`)

| H03 §6 feature | Status | Evidence |
| --- | --- | --- |
| Customizable, rearrangeable layout, edit mode | implemented, not verified | `qml/ControlCenter/Panel.qml:33` (`setEditing`), drag to page dots `Panel.qml:355-365`; layout file version 3 (`MIGRATION.md:254-255`) |
| Split-action controls | implemented, not verified | `Nyx.Ui` `SplitTile`; tiles in `qml/ControlCenter/tiles/` |
| Detail views with back navigation | implemented, not verified | `qml/ControlCenter/details/` (Wi-Fi, Bluetooth, VPN, Tailscale, Display, Battery, Sound, Devices, plugins) |
| Brightness via the system backend | implemented, not verified | backend `brightness` topic (`crates/nyx-providers/src/brightness.rs`); polled (NYX-SHELL-004) |
| Secondary page | partial | pages by swipe, scroll and dots (`Dashboard.qml:6,281`); no keyboard way to change page (`Panel.qml:336-354`, NYX-SHELL-005) |
| Floating/tiling workspace control | implemented, not verified | `tiles/ModeTile.qml`; workspace mode files loaded by `nyxos/modules/home/hyprland.nix:110-119` |
| Unavailable capabilities hidden | implemented, not verified | `env.have` / `env.omarchy` gates (`Ctx.qml:15`, `details/WifiDetail.qml:256-262`) |
| No conflict with other exclusive overlays | partial | exclusive with NC/Switcher via `Panel1`; not with Glimpse (NYX-SHELL-003) |
| Focus handling | implemented, not verified | Exclusive keyboard (`Main.qml:155`), Escape (`Panel.qml:55`), Tab through tiles (`TileFrame.qml:21-25`) |

### Notification Center (GTK on NyxOS: `pkgs/nyx-notification-center.nix:33-35,49-52`)

The QML version exists (`nyx-notification-center/qml/NotificationCenter`) but isn't shipped
(NYX-ARCH-007). Storage is `nyx-notifyd` in both.

| H03 §7 feature | Status | Evidence |
| --- | --- | --- |
| Inbox, Pinned, History views | implemented, not verified | GTK `apps/notification-center/src/panel.rs:3,23-41` |
| Search | implemented, not verified | `panel.rs:58` (`SearchEntry`) |
| Pins survive Clear All, retention and deletion | implemented, not verified | `crates/nyx-notify-store/src/lib.rs:7-8` |
| Retention | implemented, not verified | hourly prune `apps/notifyd/src/main.rs:98-117`; 7/30/90 days `lib.rs:9,120,147` |
| Privacy exclusions | implemented, not verified | excluded apps deleted from history, pins kept `lib.rs:457-458`; codes skipped `apps/notifyd/src/state.rs:106` |
| Notification actions | implemented, not verified | per `MIGRATION.md:285` (card actions, activation) |
| Pop-ups: no focus stealing | implemented, not verified | `popups.rs:174` (`KeyboardMode::None`) |
| Pop-ups: fullscreen behaviour | not implemented | no fullscreen check in `popups.rs`; `AUDIT.md:94` says they draw over fullscreen windows |
| Shell Core overlay integration | partial | `Panel1` bridge only |

### Desktop Widgets (packaged; enabled on no host, NYX-ARCH-006)

| H03 §9 feature | Status | Evidence |
| --- | --- | --- |
| Placement, per-monitor and per-workspace layouts | implemented, not verified | backend `layout`, QML `ScreenSurface.qml` (`MIGRATION.md:314-319`) |
| Edit mode, persistence | implemented, not verified | `qml/DesktopWidgets/Gallery.qml`, `WidgetTile.qml`; `toml_edit` file (`MIGRATION.md:311-312`) |
| Hide on lock, fullscreen, coverage | implemented, not verified | backend watcher `apps/desktop-widgets-backend/src/host.rs:133` (its own, NYX-ARCH-001) |
| Widget isolation | implemented, not verified | plugins in systemd scopes and bubblewrap (`pkgs/nyx-desktop-widgets.nix:32-38`) |
| Restart recovery | implemented, not verified | `BackendClient` reconnects with backoff (`qml/Nyx/Shell/BackendClient.qml:210-262`) |

### Task Switcher (GTK on NyxOS: `pkgs/nyx-switcher.nix:14-15`)

| H03 §8 feature | Status | Evidence |
| --- | --- | --- |
| Quick Switch with keyboard cycling | implemented, not verified | GTK `apps/switcher`; `nyx-switcher-send` socket path (`MIGRATION.md:299`) |
| Workspace Overview | implemented, not verified | `apps/switcher/src/overview.rs:50` |
| Previews | implemented, not verified | thumbnails via capture (`MIGRATION.md:305`) |
| Multi-monitor, workspace awareness | implemented, not verified | own watcher `apps/switcher/src/ui.rs:218` |
| Shares the Dock's window model | not implemented | separate watchers (NYX-ARCH-001; H03 §8.4) |
| Focus restoration | implemented, not verified | Hyprland returns focus on unmap (`docs/ARCHITECTURE.md:160-164`) |
| QML version | approved, not implemented on NyxOS | `qml/Switcher` exists, not installed (NYX-ARCH-007) |

### OSD (QML on NyxOS: `pkgs/nyx-shell.nix:41`)

| H03 §10 feature | Status | Evidence |
| --- | --- | --- |
| Volume, microphone, brightness, keyboard light | implemented, not verified | `qml/components/nyx-osd/Main.qml:66-90` |
| Passive, no focus, coalesced in place | implemented, not verified | `Main.qml:128-137` (`passive`, `keyboard: none`), one surface, timer restarted `:47-54,98-102` |
| Accurate, prompt state | partial | sound is event-driven; brightness polled every 2 s, so a brightness key shows up to 2 s late (NYX-SHELL-004) |
| Fullscreen policy | implemented, not verified | `fullscreenRule: "show"` (`Main.qml:133`) |
| Reduced motion | not implemented | fade uses `Style.fast` without a `reducedMotion` check (`Main.qml:146-151`) |
| Backend disconnection | implemented, not verified | baseline reset on reconnect (`Main.qml:91-96`) |
| Accessibility | not implemented | no `Accessible` role or live region (count 0) |

### Glimpse panel (QML on NyxOS: `pkgs/nyx-glimpse.nix:48-56,74`)

| H03 §12 / H10 §7 feature | Status | Evidence |
| --- | --- | --- |
| Shell Core overlay and focus | implemented, not verified | `OverlaySurface` transient, exclusive keyboard, `restoreFocus` (`quickshell/Glimpse/Main.qml:196-208`) |
| Activation (`nyx-glimpse --toggle`, Super+Space) | implemented, not verified | backend `panel` topic → `ShellCore.showOverlay` (`Main.qml:187-193`); bind `nyxos/modules/home/hyprland.nix:215` |
| Keyboard-first navigation | implemented, not verified | 18 `Keys.` handlers, 39 arrow/Tab handlers across `quickshell/Glimpse` |
| Accessibility | partial | 41 `Accessible.*` uses, 16 `Accessible.name` (the only shell component with any) |
| Overlay stacking with panels | partial | group `launcher`, not exclusive with `panels` (NYX-SHELL-003) |
| Service failure behaviour | partial | backend restart re-sends the query (`Main.qml:25-27`); Shell Core loss leaves it unable to open or close (NYX-SHELL-002) |
| No second search backend, no inference in QML | implemented, not verified | QML only draws and sends keys (`Main.qml:10-11`) |

### Assistant Aura (Tier 2, with the Assistant)

| H03 §13 feature | Status | Evidence |
| --- | --- | --- |
| Full Aura, Edge Flow | implemented, not verified | QML `nyx-assistant/apps/assistant/quickshell/Aura/Main.qml:16-24,33`; GTK `assistant-visual` |
| Default renderer | GTK | `assistant-core/src/config.rs:640` (`aura_renderer: "gtk"`); QML draws only with `quickshell` (`assistant-visual/src/main.rs:320`) |
| Shell Core `presentation` overlay | implemented, not verified (QML only) | `Aura/Main.qml:363-372` |
| State reporting | implemented, not verified | states listed in `quickshell/README.md` (Aura section) |
| Monitor awareness, bar inset | partial | the default GTK Aura insets only for the `omarchy-bar` layer (`assistant-visual/src/main.rs:132`), not `nyx-bar` (`nyx-bar/qml/Bar/BarWindow.qml:43`) (NYX-SHELL-008) |

## Failure isolation

Process boundaries on NyxOS (from the units in nyx-packages):

| Failure | Design behaviour | Assessment |
| --- | --- | --- |
| `nyx-shell-qs` crashes | systemd restarts after 2 s; Bar, Dock, Control Center panel, OSD, window menu, Glimpse panel (and QML Aura) vanish and return together (`data/nyx-shell-qs.service:20-22`) | One failure domain for the whole visible shell. After 5 crashes in 60 s it stays down: no bar, no dock, no launcher, while the backends keep running and keys route to them (NYX-SHELL-001) |
| A component backend crashes (Dock, Bar, CC, Glimpse) | its QML keeps the last state and reconnects with backoff up to 5 s (`BackendClient.qml:200-208,256-262`); CC and Glimpse hide while disconnected (`ControlCenter/Main.qml:18`, `Glimpse/Main.qml:39`) | Good isolation; backends use systemd's default start limit (5 in 10 s) |
| `nyx-shell-core` crashes | runtime keeps running, reconnects with a new socket per attempt, re-registers (`ShellCore.qml:319-338,396-403`; `OverlaySurface.qml:62-69`) | Good for quick restarts. Overlay state isn't cleared on disconnect, and Glimpse depends on Shell Core to open and close (NYX-SHELL-002) |
| Shell Core crash loop (start limit) | Bar, Dock, CC keep working (no Shell Core dependency); Glimpse, OSD, window menu stop | Partial: the launcher is lost |
| GTK Notification Center or Switcher crash | own process, `Restart=on-failure` | Isolated |
| `nyx-notifyd` crash | D-Bus activation restarts it (`pkgs/nyx-notification-center.nix:40-47`) | Isolated |
| Nyx Decor fault | in the compositor's process (`hyprland.nix:284`) | Takes Hyprland and the session down; HYPR report owns the plugin |
| Lock screen | separate process, ext-session-lock; Shell Core only reads `LockedHint` | Isolated by design (SEC report verifies) |
| Any NixOS switch | `restartTriggers = [ config.system.path ]` restarts `nyx-shell-qs` (`nyxos/modules/nixos/desktop.nix:122-124`) | Every update blinks the whole shell; acceptable, worth stating in release notes |

## Keyboard and accessibility counts (QML, static)

| Component | `.qml` files | `Keys.` | `Accessible.*` | `Accessible.name` | Nyx.Ui controls | raw `MouseArea`/`TapHandler` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Bar | 6 | 2 | 0 | 0 | 0 | 2 |
| Dock | 14 | 2 | 0 | 0 | 17 | 12 |
| Control Center | 49 | 4 | 0 | 0 | 61 | 19 |
| Notification Center (not shipped) | 13 | 1 | 0 | 0 | 19 | 5 |
| Switcher (not shipped) | 5 | 3 | 0 | 0 | 8 | 4 |
| Desktop Widgets (not shipped) | 5 | 1 | 0 | 0 | 3 | 4 |
| Glimpse | 27 | 18 | 41 | 16 | 56 | 23 |
| OSD + window menu | 2 | 1 | 0 | 0 | 0 | 1 |

The shared `Nyx.Ui` controls (nyx-design `qml/Nyx/Ui`) carry roles and names: `Button`,
`IconButton`, `ListRow`, `Segmented`, `Slider`, `Toggle` each have 5 `Accessible.*` lines and
`activeFocusOnTab`. Raw `MouseArea`s (Dock tiles, CC page dots, Bar items) have neither.
`Nyx.Ui.FocusRing` is used by no component.

## Findings

### NYX-SHELL-001: One Quickshell process is the whole visible shell, with no fallback after its start limit

- **Component:** nyx-shell `data/nyx-shell-qs.service`; nyx-packages autostart lists
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The Bar, Dock, Control Center panel, OSD, window menu and Glimpse panel all run in `nyx-shell-qs`. A fatal QML or Quickshell fault removes all of them at once. systemd restarts it at most 5 times in 60 s; after that the session has no bar, dock or launcher until the user restarts the unit from a terminal (Super+Return still works) or signs out. The backends keep running, so `nyx-glimpse --toggle` and `nyx-control-center --toggle` reach a backend with nothing to draw and fail silently. No `OnFailure=` unit or notification tells the user. Static; confirm at runtime.
- **Expected:** H01 §6 and H03 §3.6, §17.3 (acknowledge the shared failure domain; separate processes where the failure domain is unacceptable); H10 §6 acceptance ("a single shell component failure must not unnecessarily terminate the desktop session").
- **Actual:** `nyx-shell/data/nyx-shell-qs.service:7-8,20-22`; components placed there by `nyx-packages/pkgs/nyx-bar.nix:97-99`, `nyx-dock.nix:27-30`, `nyx-control-center.nix:41-44`, `nyx-glimpse.nix:54-56`, `nyx-shell.nix:41-42`; failure domain documented only generically (`nyx-shell/docs/ARCHITECTURE.md:229,234-237`).
- **Reproduce / verify:** in the VM, `for i in $(seq 6); do pkill -9 -f '\.quickshell-wrapped'; sleep 3; done; systemctl --user status nyx-shell-qs`.
- **Evidence:** above.
- **Affected versions:** nyx-shell `975092e`, nyx-packages `d69e87e`.
- **User impact:** a QML bug that crashes repeatedly (for example on one monitor configuration) leaves the user without bar, dock and launcher.
- **Recommended correction:** keep the Bar (and possibly Glimpse) in a second runtime, or add an `OnFailure=` unit that notifies and offers a reset; document the failure domain per component.
- **Effort:** M
- **Dependencies:** NYX-ARCH-002
- **Verification criteria:** after the start limit the user gets a notification and a working launcher, or the bar survives a dock crash.

### NYX-SHELL-002: Stale overlay state while Shell Core is away traps or disables Glimpse

- **Component:** nyx-shell `qml/Nyx/Shell/ShellCore.qml`; nyx-glimpse `quickshell/Glimpse/Main.qml`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** On disconnect `ShellCore._reset()` clears requests and readiness but keeps `overlays`, so an overlay shown at that moment stays shown. Glimpse's surface (full-screen, Exclusive keyboard, click catcher) hides only through `ShellCore.hideOverlay`, which fails while disconnected, so Escape and clicks do nothing until Shell Core returns. If Shell Core is in a crash loop (start limit hit), Glimpse stays up holding the keyboard, and when it isn't up, Super+Space can't open it at all. Static; confirm at runtime.
- **Expected:** H01 §4.3 ("rapid open/close must not leave orphaned surfaces"), §10 (IPC client reconnection, Shell Core restart); H03 §12.5 (overlay dismissal works).
- **Actual:** `ShellCore.qml:274-282` (no `overlays` reset), `OverlaySurface.qml:28-30,71,76-77,83-88`; `Glimpse/Main.qml:187-193,214-228`.
- **Reproduce / verify:** in the VM open Glimpse, then `systemctl --user kill -s KILL nyx-shell-core` six times within a minute; press Escape and click outside.
- **Evidence:** above.
- **Affected versions:** nyx-shell `975092e`, nyx-glimpse `deecabf`.
- **User impact:** keyboard input can be captured by a panel that won't close (Hyprland binds such as Super+Shift+E still work); the launcher is gone while Shell Core is down.
- **Recommended correction:** on disconnect, mark every client-owned overlay hidden locally; let transient surfaces hide themselves on Escape when not connected; consider a local fallback (Standalone rules) after N failed reconnects.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** with Shell Core stopped, Glimpse closes on Escape and opens on Super+Space (or reports why).

### NYX-SHELL-003: Glimpse and the panels can be open together, both holding the keyboard

- **Component:** nyx-glimpse `quickshell/Glimpse/Main.qml`; nyx-control-center QML
- **Category:** UX
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Glimpse registers in group `launcher`; the Control Center, Notification Center and Switcher are in `panels`. Opening one doesn't close the other, and both request Exclusive keyboard.
- **Expected:** H01 §4.3 ("opening an exclusive interactive overlay closes or deactivates conflicting overlays according to explicit policy"); H03 §6.9 ("does not conflict with other exclusive overlays").
- **Actual:** `Glimpse/Main.qml:200-201`; `ControlCenter/Main.qml:155`; default group `nyx-shell-proto/src/overlay.rs:119,157`.
- **Reproduce / verify:** in the VM, Super+D then Super+Space; type and press Escape.
- **Evidence:** above.
- **Affected versions:** nyx-glimpse `deecabf`, nyx-control-center `7335302`.
- **User impact:** keys go to whichever surface Hyprland picked; Escape may close the wrong one.
- **Recommended correction:** put Glimpse in `panels`, or declare that `launcher` and `panels` exclude each other.
- **Effort:** S
- **Dependencies:** NYX-ARCH-002
- **Verification criteria:** opening either closes the other.

### NYX-SHELL-004: Brightness OSD is polled every 2 seconds for the whole session

- **Component:** nyx-shell `qml/components/nyx-osd`; nyx-control-center `crates/nyx-providers/src/brightness.rs`
- **Category:** performance
- **Severity:** P3
- **Status of feature:** partial
- **Description:** The OSD subscribes to the Control Center backend's `brightness` topic permanently (`BackendTopic` is `active` by default), and that provider runs `brightnessctl -m -l` every 2 s while subscribed. The brightness keys call `brightnessctl` directly, so the OSD appears up to 2 s after the key.
- **Expected:** H03 §10.3 ("appear promptly"), §19 ("avoid unnecessary polling").
- **Actual:** `nyx-osd/Main.qml:29-33,77-90`; `qml/Nyx/Shell/BackendTopic.qml` (`active: true`); `brightness.rs:5-6,37-43`; keys `nyxos/modules/home/hyprland.nix:203-206`.
- **Reproduce / verify:** on hardware with a backlight, press brightness up and time the OSD; `pidstat -p $(pgrep -f control-center-backend) 5` for child spawns.
- **Evidence:** above.
- **Affected versions:** nyx-shell `975092e`, nyx-control-center `7335302`.
- **User impact:** late brightness feedback on laptops; a process spawn every 2 s.
- **Recommended correction:** watch `/sys/class/backlight/*/brightness` (inotify or udev) or route the keys through the backend.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** OSD within one frame of a key press; no periodic spawns.

### NYX-SHELL-005: Keyboard and screen-reader paths missing in most shell QML

- **Component:** nyx-dock, nyx-control-center, nyx-bar, nyx-shell OSD
- **Category:** accessibility
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Outside Glimpse no shell QML sets an `Accessible` role or name (counts above); interactive items built from raw `MouseArea` aren't focusable. The Dock and Bar never take the keyboard, so apps pinned there and bar items can't be reached without a pointer. The Control Center's pages change only by swipe, scroll or clicking dots. The OSD announces nothing. Workarounds exist (Glimpse launches apps, the Switcher switches windows), hence P2.
- **Expected:** H03 §4.5 (keyboard navigation, focus indicators), §5.5 ("ensure keyboard accessibility"), §6.5 ("keyboard-accessible alternative" for the secondary page); H10 §11.
- **Actual:** `nyx-dock/qml/Dock/DockWindow.qml:134,186`; `nyx-bar/qml/Bar/BarWindow.qml:44`; `nyx-control-center/qml/ControlCenter/Panel.qml:336-354`; Nyx.Ui roles in nyx-design `qml/Nyx/Ui/{Button,IconButton,ListRow,Slider,Toggle}.qml`.
- **Reproduce / verify:** in the VM with Orca, open the Control Center (Super+D) and Tab through it; try to reach the second page and the Dock by keyboard.
- **Evidence:** counts table above.
- **Affected versions:** header revisions.
- **User impact:** keyboard-only and screen-reader users can't use the Dock, Bar or CC pages.
- **Recommended correction:** use `Nyx.Ui` controls (or add `Accessible.role/name`, `activeFocusOnTab`, `FocusRing`) for tiles and dots; PageUp/PageDown in the CC; a "focus the dock/bar" shortcut through Shell Core; `Accessible.role: Accessible.AlertMessage` for the OSD.
- **Effort:** M
- **Dependencies:** A11Y report
- **Verification criteria:** every shell control reachable by Tab with a visible focus ring and announced by Orca.

### NYX-SHELL-006: Shell Core asks Hyprland for `nyxdecor` on every desktop update

- **Component:** nyx-shell `crates/nyx-shell-core/src/compositor.rs`
- **Category:** performance
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The watcher callback runs `hyprctl -j nyxdecor` (a socket1 round trip) for every update, including title changes, which terminals emit many times a second. Added in `f203a2e`, whose message says it wasn't run in the VM. Static; confirm at runtime.
- **Expected:** H01 §13 performance (behaviour during rapid changes), H03 §19 (coalesce high-frequency changes).
- **Actual:** `compositor.rs:71-80,83-93`.
- **Reproduce / verify:** in the VM, `yes | head -c 50M` in a terminal whose title updates, then `nyx-shellctl watch --latency` and `strace -c -f -p $(pidof nyx-shell-core)`.
- **Evidence:** above; nyx-shell commit `f203a2e`.
- **Affected versions:** nyx-shell `f203a2e`..`975092e`.
- **User impact:** extra compositor IPC and Shell Core CPU under title bursts.
- **Recommended correction:** query `nyxdecor` only on `openwindow`/`closewindow` changes, or have nyx-decor post a custom event.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** no `nyxdecor` request on title-only updates.

### NYX-SHELL-007: Dock swipe following isn't active on NyxOS

- **Component:** nyx-packages `pkgs/nyx-dock.nix`
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** partial
- **Description:** The dock's Hyprland plugin (`nyx-dock-swipe.so`) isn't built for NyxOS, so the dock doesn't follow a workspace swipe and hides once it ends.
- **Expected:** H03 §5 baseline (preserve existing behaviour); `MIGRATION.md:241` lists swipe following as moved.
- **Actual:** `nyx-packages/pkgs/nyx-dock.nix:4-5`.
- **Reproduce / verify:** three-finger swipe in the VM (or `hyprctl dispatch workspace +1` during a gesture on hardware).
- **Evidence:** above.
- **Affected versions:** nyx-packages `d69e87e`.
- **User impact:** visual inconsistency during swipes.
- **Recommended correction:** build the plugin against `hyprland-nyx` as `nyx-decor` is (`pkgs/nyx-decor.nix`), or fold the events into nyx-decor.
- **Effort:** S
- **Dependencies:** HYPR report
- **Verification criteria:** dock follows the swipe on NyxOS.

### NYX-SHELL-008: The default (GTK) Aura doesn't leave room for Nyx Bar

- **Component:** nyx-assistant `crates/assistant-visual`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** partial
- **Description:** The GTK Aura, the default renderer, insets its top edge only for a layer named `omarchy-bar`; on NyxOS the bar is `nyx-bar`, so the Aura's top edge is drawn under or over the bar. The QML Aura isn't the default.
- **Expected:** H03 §13.5 (Aura respects monitor geometry and shell placement).
- **Actual:** `nyx-assistant/apps/assistant/crates/assistant-visual/src/main.rs:126-134`; `assistant-core/src/config.rs:640`; `nyx-bar/qml/Bar/BarWindow.qml:43`.
- **Reproduce / verify:** in the VM (Assistant enabled), trigger listening and screenshot the top edge.
- **Evidence:** above.
- **Affected versions:** nyx-assistant `58ed80e`.
- **User impact:** cosmetic overlap for Assistant users.
- **Recommended correction:** use the monitor's reserved area (Shell Core's `reserved`) instead of a namespace; or make the QML Aura the NyxOS default.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Aura edge sits below the bar on NyxOS.

## Runtime results

Dev VM, 2026-11-12 (logs under evidence/logs/; summary in [reliability.md](reliability.md)):

- **NYX-SHELL-001 confirmed.** Five SIGKILLs of `nyx-shell-qs` within a minute restart it (2 s each); the sixth hits `start-limit-hit`, leaving only the wallpaper: no bar, dock, Control Center or Glimpse. `systemctl --user start` is refused until `reset-failed`; Shell Core doesn't restart it (logs/shell-qs-crashloop.txt, shots/shell-qs-crashloop.png).
- **NYX-SHELL-002 partly confirmed.** With Glimpse open, killing Shell Core did *not* trap it: Escape still closed it. While Shell Core is stopped, `nyx-glimpse --toggle` (the Super+Space command) opens nothing; the first toggle 2 s after Shell Core returns also does nothing; later toggles work (logs/shell-core-loss.txt).
- **Backends recover.** One SIGKILL each of the bar, dock, Control Center, Glimpse, notification, switcher and theme backends: each back within 4 s with its surface (logs/shell-backend-kills.txt).
- **Monitor hot-plug:** a new output got the wallpaper and Glimpse but no bar or dock (NYX-REL-003).
- **Fullscreen workspaces** (nyx-hyprland 0012): fullscreen moves the window to `fullscreen-1-1` and back, cleanup on close works (logs/hyprland-fullscreen.txt).
- **Theme change** reached the bar in 375 ms (logs/theme-switch.txt).
- Shell Core used 3 min 53 s CPU in 21 h; Quickshell holds 297 MB (performance.md).
- Not measured: frame timing, overlay latency, brightness OSD latency (no backlight in the VM), multi-monitor on hardware.
