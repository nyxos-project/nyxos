# Architecture compliance

Handoff 10 §5. Static review on 2026-11-12 of the checkouts in `~/Projects` (no builds,
no VM). Measured against Handoff 01 (Shell Core) and Handoff 03 (Quickshell migration).
Revisions: nyx-shell `975092e`, nyx-packages `d69e87e`, nyxos `97f1573`, nyx-bar
`4a84c75`, nyx-dock `0cd8173`, nyx-control-center `7335302`, nyx-notification-center
`b0801d6`, nyx-switcher `5ed009a`, nyx-desktop-widgets `8b8bf32`, nyx-glimpse `deecabf`,
nyx-assistant `58ed80e`, nyx-hyprland `71afdcb`, nyx-core `9187295` (the shell
components pin older nyx-core revisions; see `evidence/shared-crate-pins.txt`).

The nyx-shell docs (`ARCHITECTURE.md`, `AUDIT.md`, `NYXOS.md`, `MIGRATION.md`,
`HANDOFF-03.md`, `SECURITY.md`) were treated as claims. Where they disagree with the
packaging, the packaging wins: that is what a NyxOS install runs.

## What a NyxOS session actually runs (shell)

From `nyx-packages/pkgs/*.nix` `passthru.autostart` and `nyxos/modules/nixos/apps.nix:54-63`:

| Process | Unit | UI | Talks to Hyprland itself |
| --- | --- | --- | --- |
| `nyx-shell-core` | `nyx-shell-core.service` (`Type=notify`) | none | yes (the one meant to) |
| `nyx-shell-qs` (Quickshell) | `nyx-shell-qs.service` | Bar, Dock, Control Center panel, OSD, window menu, Glimpse panel (and the Aura if opted in) | yes: the window menu (`Quickshell.Hyprland`) |
| `nyx-bar-backend` + plugin processes | `nyx-bar-backend.service` | none | yes: host watcher, `workspaces` and `keyboard` plugins |
| `nyx-dock-backend` | `nyx-dock-backend.service` | none | yes: watcher, `cursorpos`, snapshots |
| `nyx-control-center-backend` | same name | none | yes, while the mode tile shows |
| `nyx-notification-center` (GTK panel and pop-ups) | `nyx-notification-center.service` | GTK | yes: focused-monitor lookup |
| `nyx-notifyd` | `nyx-notifyd.service` (`Type=dbus`) | none | no |
| `nyx-switcher` (GTK) | `nyx-switcher.service` | GTK | yes: watcher |
| `nyx-glimpse-backend`, `nyx-glimpsed` | their units | none | no |
| Nyx Decor | Hyprland plugin, in the compositor (`nyxos/modules/home/hyprland.nix:284`) | headerbars | n/a |

Not shipped by any host: Desktop Widgets (NYX-ARCH-006). The Notification Center's and
Switcher's QML front ends exist but NyxOS starts their GTK units (NYX-ARCH-007).

## Compliance matrix

| Requirement (source) | Status | Evidence | Recommended correction |
| --- | --- | --- | --- |
| Customized Hyprland is the compositor (H01 §3, §7) | implemented, not verified | `nyxos/modules/nixos/desktop.nix:31-36` sets `programs.hyprland.package` to nyx-packages' build; `nyx-packages/pkgs/hyprland.nix:1-4,28-43` applies `nyx-hyprland/patches/0.57.2/` (13 patches); greeter and session both use it (`desktop.nix:150-159`) | None. Patch risk is the HYPR report's |
| Shell Core runs one per session, attaches, detects stale state (H01 §4.1) | implemented, not verified | `nyx-shell/crates/nyx-shell-core/src/session.rs:24-45` (flock, stale socket removed, 0700 dir); `apps/shell-core/src/main.rs:62-67` exits quietly if another answers | None |
| Shell Core doesn't block on optional services; readiness bounded (H01 §4.1, §10) | implemented, not verified | `server.rs:101-114` (D-Bus bridge spawned, 2 s ready timeout); `core.rs:255-260` (`Degraded` + `READY=1` on timeout) | None |
| Normalized monitor/workspace/window state with generations, deltas, resync (H01 §4.2) | implemented, not verified | `nyx-shell-proto/src/desktop.rs:9-11,26,62-82,121-138` (stable ids, scale, refresh, reserved, pid); `qml/Nyx/Shell/ShellCore.qml:145-159,203-212` (base generation check, seq gaps refetch) | None |
| One authoritative window model; components don't run their own watchers (H01 §3 L3, H03 §3.3, §8.4) | partial | Six other subscribers: `nyx-bar/apps/bar-backend/src/host.rs:127`, `nyx-bar/plugins/workspaces/src/main.rs:10`, `nyx-bar/plugins/keyboard/src/main.rs:110-112`, `nyx-dock/apps/dock-backend/src/main.rs:934`, `nyx-switcher/apps/switcher/src/ui.rs:218` (GTK, shipped), `nyx-control-center/apps/control-center-backend/src/topics.rs:189`, `nyx-shell/qml/components/nyx-window-menu/Main.qml:3,55-57` | NYX-ARCH-001 |
| Overlay coordination through one registry and a shared surface controller (H01 §4.3, H03 §4.2) | partial | Registry exists (`crates/nyx-shell-core/src/overlay.rs`); only Glimpse, OSD, window menu and the opt-in Aura use `OverlaySurface`. Bar, Dock, Control Center, Notification Center, Switcher draw raw `PanelWindow`s (`nyx-dock/qml/Dock/DockWindow.qml:114-134`, `nyx-control-center/qml/ControlCenter/Main.qml:150-155`) and coordinate through `Panel1` D-Bus bridged into Shell Core (`docs/ARCHITECTURE.md:143-149`) | NYX-ARCH-002 |
| Focus restoration without loops (H01 §4.4) | implemented, not verified | `crates/nyx-shell-core/src/focus.rs`; rules in `docs/ARCHITECTURE.md:152-164` (500 ms debounce, user choice wins) | Runtime check (shell.md) |
| Shortcut and action router; no duplicate ownership; no arbitrary command execution (H01 §4.5) | partial | Router: `actions.rs:53-58,140-174` (fixed routes, no client-named command). But no shipped key goes through it: `nyxos/modules/home/hyprland.nix:213-222` binds `nyx-glimpse --toggle`, `nyx-control-center --toggle`, `nyx-notification-center --toggle` directly; switcher writes its own file at every start (`nyx-packages/modules/nixos/default.nix:615-619`) | NYX-ARCH-004 |
| Component registry with health and restart policy (H01 §4.6) | partial | Registry `registry.rs:1-5,36-55,61-72`; only `nyx.osd`, `nyx.window-menu` (`qml/components/*/Main.qml`, `ShellComponent`) and the opt-in Aura register. Bar, Dock, Control Center, Glimpse never do | NYX-ARCH-003 |
| Component restart: bounded backoff, compositor never restarted (H01 §10) | implemented, not verified | systemd only (`registry.rs:3`). `nyx-shell-core.service:6-7,13-14` and `nyx-shell-qs.service:7-8,21-22` (5 in 60 s); backends `Restart=on-failure`, `RestartSec=1`, systemd's default limit (e.g. `nyx-dock/apps/dock-backend/data/nyx-dock-backend.service:6-9`). No unit restarts Hyprland | Failure domain: shell.md NYX-SHELL-001 |
| Typed config, layered defaults, reset, Settings integration (H01 §4.7) | implemented, not verified | `config.rs`; `/etc/nyxos/defaults/shell.toml` from `nyx-packages/modules/nixos/default.nix:295-297`; Settings client `nyx-settings/apps/settings/src/backend/shell_core.rs` | None |
| Theme events from Theme Engine 2.0, no second engine (H01 §4.8, H03 §3.4) | implemented, not verified | `docs/ARCHITECTURE.md:210-222`; components read `Nyx.Theme` from the engine's snapshot (`nyx-packages/modules/nixos/default.nix:587-588`) | Out of scope (THEME report) |
| Versioned IPC, typed messages, errors, backpressure, peer checks (H01 §5) | implemented, not verified | `server.rs:270-280` (`SO_PEERCRED` uid), `server.rs:391-396` (version range), `proto/frame.rs:262-287` (op → capability), per-client bounded queue `server.rs:286` | None |
| No unrestricted command execution over IPC (H01 §4.5, §5) | implemented, not verified | Shell Core: fixed argv only (`actions.rs:157-160`, `compositor.rs:168`). Dock backend `Command` op is allow-listed (`nyx-dock/apps/dock-backend/src/main.rs:793-801`) | None |
| One IPC contract per concern, no needless bridge daemon (H01 §5) | partial | No bridge daemon: QML speaks to Shell Core directly (`ShellCore.qml:354-394`). But five mechanisms coexist (NYX-ARCH-005) | NYX-ARCH-005 |
| Permission boundaries consistent across shell IPC (H01 §5 security) | partial | Shell Core grants capabilities by executable (`peer.rs:46-62`); every `nyx-ui-link` backend accepts any same-user peer (`nyx-core/crates/nyx-ui-link/src/lib.rs:79-80,89-98`; no `allow` set in `nyx-dock/apps/dock-backend/src/main.rs:900`, `nyx-bar/apps/bar-backend/src/main.rs:100`, `nyx-control-center/apps/control-center-backend/src/main.rs:167`) | NYX-ARCH-010 |
| Quickshell for shell surfaces; Rust backends own logic (H01 §3, H03 §3.2) | partial | QML front ends + Rust backends for Bar, Dock, Control Center, OSD, Glimpse (`nyx-packages/pkgs/nyx-{bar,dock,control-center,glimpse}.nix` postInstall). Notification Center and Switcher still GTK on NyxOS | NYX-ARCH-007 |
| Lock screen and authentication outside the ordinary shell (H01 §9, H03 §14) | implemented, not verified | Shell Core reads only logind `LockedHint`; no unlock op (`docs/SECURITY.md:45-50`, op list `core.rs:285-405`). Locker and prompt are separate user units (`nyx-packages/modules/nixos/default.nix:551-580`) | Verify in SEC report |
| No privileged UI processes | implemented, not verified | Every shell unit is a user unit (`ConditionUser=!@system`, `nyx-packages/modules/nixos/default.nix:134-144`); plugins in bubblewrap (`pkgs/nyx-bar.nix:70-72`) | None |
| No hardcoded developer paths in shell code | verified (static) | `rg '/home/ken'` finds nothing in shell sources; `/usr/bin/quickshell` default is replaced by the store path (`nyx-packages/pkgs/nyx-shell.nix:26-28`); unit `%h/.local/bin` paths rewritten by `lib/default.nix:121` | None |
| No Omarchy-specific implementation in NyxOS paths (H01 §11) | partial | Adapters guarded by `omarchy-menu` presence (`nyx-control-center/crates/nyx-providers/src/omarchy.rs:27-29`). Functional leftovers: minimize only via `omarchy-hyprland-window-minimize` (`nyx-shell/crates/nyx-shell-core/src/window.rs:10-18`, `compositor.rs:168`) | NYX-ARCH-009 |
| Documented startup order (H01 §10, H03 §17.4) | partial | Core then qs ordered (`nyx-shell-qs.service:4-5`); backends only `After=graphical-session.target`; QML reconnects with backoff (`BackendClient.qml:256-262`). The written order is stale (`nyx-shell/docs/NYXOS.md:69-77`) | NYX-ARCH-008 |
| Fragile shutdown | implemented, not verified | All units `PartOf=graphical-session.target`; core sends `Shutdown`, removes socket (`core.rs:262-269`, `server.rs:129-148`) | None |
| Failure domains documented (H03 §3.6, §17.4) | partial | `docs/ARCHITECTURE.md:224-237` says one runtime for ordinary surfaces; nothing says that the bar and the launcher share it with the dock, or what happens at the start limit | shell.md NYX-SHELL-001 |
| Circular dependencies | none found | Units: qs `Wants=` core, NC `Wants=` notifyd; no cycle | None |

## Findings

### NYX-ARCH-001: Shell components keep their own Hyprland watchers and window models

- **Component:** nyx-bar, nyx-dock, nyx-switcher, nyx-control-center, nyx-shell (window menu), nyx-assistant
- **Category:** architecture
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Shell Core is meant to be the one compositor watcher whose normalized state every shell surface uses. On NyxOS at least six other processes subscribe to Hyprland's event socket and build their own window model.
- **Expected:** H01 §3 Layer 3 ("do not independently own compositor state"); H03 §3.3 (no independent Hyprland watchers or workspace caches); H03 §8.4 (Dock and Switcher share Shell Core's window state).
- **Actual:** `nyx-bar/apps/bar-backend/src/host.rs:127` (`watch_local`), `nyx-bar/plugins/workspaces/src/main.rs:10` (its own `watch`), `nyx-bar/plugins/keyboard/src/main.rs:110-112` (raw `.socket2.sock`), `nyx-dock/apps/dock-backend/src/main.rs:934`, `nyx-switcher/apps/switcher/src/ui.rs:218` (GTK switcher, the one shipped: `nyx-packages/pkgs/nyx-switcher.nix:14-15`), `nyx-control-center/apps/control-center-backend/src/topics.rs:189` (while the mode tile shows), `nyx-shell/qml/components/nyx-window-menu/Main.qml:3,55-57` (`Quickshell.Hyprland` inside `nyx-shell-qs`, for the `nyx-window-menu` custom event), and with the Assistant `assistant-visual/src/main.rs:1278`. `MIGRATION.md:73-78` documents the Dock and Switcher backends as an open item (Shell Core's state lacks window geometry); its claim that "QML surfaces never open Hyprland's sockets in Shell Core mode" is contradicted by the window menu. The components also pin different nyx-core revisions, so they run different versions of the same parser (`evidence/shared-crate-pins.txt`).
- **Reproduce / verify:** in the VM, `ls -l /proc/$(pgrep -f nyx-dock-backend)/fd` and `ss -xp | grep socket2` to count event-socket clients.
- **Evidence:** source references above.
- **Affected versions:** the revisions in this report's header.
- **User impact:** Dock, Switcher and Bar can disagree about window membership or focus during rapid changes; each process repeats parsing and snapshot work (H03 §19 "avoid duplicate compositor subscriptions").
- **Recommended correction:** add window geometry and custom-event forwarding to Shell Core's state, then move the Dock and Switcher backends and the Bar host to it; have the window menu receive `nyx-window-menu` through Shell Core.
- **Effort:** L
- **Dependencies:** NYX-ARCH-007
- **Verification criteria:** only `nyx-shell-core` holds an event-socket connection in a NyxOS session.

### NYX-ARCH-002: Most shell surfaces bypass Shell Core's overlay registry

- **Component:** nyx-bar, nyx-dock, nyx-control-center, nyx-notification-center, nyx-switcher
- **Category:** architecture
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Only Glimpse, the OSD, the window menu and the opt-in Aura declare overlay policy through `OverlaySurface`. The others draw raw `PanelWindow`s with their own keyboard and fullscreen rules; mutual exclusion among the Control Center, Notification Center and Switcher still runs over the peer-to-peer `Panel1` D-Bus protocol, which Shell Core bridges. Dock menus and cards and Bar popovers sit outside any exclusion.
- **Expected:** H01 §4.3 (central overlay coordination, declarative policy); H03 §4.2 (every surface declares id, category, keyboard, fullscreen, conflict group through a shared controller).
- **Actual:** `nyx-dock/qml/Dock/DockWindow.qml:114-134`, `nyx-bar/qml/Bar/BarWindow.qml:43-44`, `nyx-control-center/qml/ControlCenter/Main.qml:150-155` (Exclusive keyboard, no registration); `Panel1` bridge `nyx-shell/docs/ARCHITECTURE.md:143-149`; `HANDOFF-03.md:85-87` lists moving to overlay registration as open.
- **Reproduce / verify:** `nyx-shellctl status` in the VM: the overlay list shows only `glimpse`, `nyx.osd`, `nyx.window-menu` plus the built-in panel entries.
- **Evidence:** above.
- **Affected versions:** header revisions.
- **User impact:** overlapping popovers (a Dock card and the Control Center, a Bar popover and Glimpse) aren't closed by policy; fullscreen behaviour differs per component.
- **Recommended correction:** wrap each QML surface in `OverlaySurface`/`PinnedSurface` with a declared policy; retire `Panel1` once the Notification Center and Switcher are QML on NyxOS.
- **Effort:** M
- **Dependencies:** NYX-ARCH-007
- **Verification criteria:** every shell layer surface appears in `nyx-shellctl status`; opening any transient closes its group.

### NYX-ARCH-003: Component registry and health reflect almost none of the shell

- **Component:** nyx-shell (registry), all Quickshell components
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** partial
- **Description:** `ShellComponent` is used only by the OSD and the window menu (and the opt-in Aura). Bar, Dock, Control Center and Glimpse never register, so Shell Core's status (the diagnostics interface Settings reads) can't report them degraded or failed.
- **Expected:** H01 §4.6, §4.9 (component readiness and failures visible for diagnostics and Settings).
- **Actual:** `rg ShellComponent` finds only `nyx-shell/qml/components/nyx-osd/Main.qml:42-45`, `nyx-window-menu/Main.qml:29-32`, `nyx-assistant/apps/assistant/quickshell/Aura/Main.qml:363`. Built-ins are the core, Hyprland, D-Bus and the three `Panel1` panels (`registry.rs:36-55`).
- **Reproduce / verify:** `nyx-shellctl status` in the VM.
- **Evidence:** above.
- **Affected versions:** header revisions.
- **User impact:** none directly; support and Settings can't see a dead Dock or Bar backend.
- **Recommended correction:** a `ShellComponent` in each component's `Main.qml`, reporting `degraded` while its `BackendClient` is disconnected.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** killing `nyx-dock-backend` shows `nyx.dock degraded` in status.

### NYX-ARCH-004: No shipped shortcut goes through Shell Core's action router

- **Component:** nyxos `modules/home/hyprland.nix`, nyx-switcher, nyx-shell
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Shell Core's router and owned shortcut file work, but NyxOS binds every shell key directly to each program, and key ownership is spread across `hyprland.nix`, `nyx-switcher.lua` (rewritten with `--integrate --force` and a Hyprland reload at every switcher start), `nyx-shell.lua`, `nyx-window-controls.lua`, `settings.lua` and `user.lua`.
- **Expected:** H01 §4.5 (centralized action ids, avoid duplicate or conflicting shortcut ownership).
- **Actual:** `nyxos/modules/home/hyprland.nix:213-222,257-263,268-275,282-291,321-339`; `nyx-packages/modules/nixos/default.nix:615-619`; `nyx-shell/docs/NYXOS.md:64-67` (keys deliberately stay in `hyprland.nix`).
- **Reproduce / verify:** `hyprctl -j binds | jq '.[].description'` in the VM; none start with `Nyx Shell:`.
- **Evidence:** above.
- **Affected versions:** nyxos `97f1573`.
- **User impact:** low today; a user rebinding in Settings and the switcher's file can collide, and only `nyx-shellctl shortcuts --check` detects it.
- **Recommended correction:** move the shell keys into `[shortcuts]` with the components (as `NYXOS.md` plans); have the switcher's binds come from the same owner.
- **Effort:** M
- **Dependencies:** NYX-ARCH-002
- **Verification criteria:** `nyx-shellctl shortcuts --check` lists every shell key with one owner.

### NYX-ARCH-005: Five IPC mechanisms inside the shell

- **Component:** nyx-shell, nyx-core `nyx-ui-link`, all shell components
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** partial
- **Description:** A shell action can cross: Shell Core NDJSON v1 (`core.sock`), a per-component `nyx-ui-link` NDJSON socket (`$XDG_RUNTIME_DIR/<app>/ui.sock`), D-Bus (`Panel1`, `ControlCenter`, `NotificationCenter`, `Bar1`, `DesktopWidgets1`, `Notifications1`), the switcher's text-line socket, and Hyprland custom events (`nyx-monitors`, `nyx-window-menu`, `nyxswipe`). They share framing where they are NDJSON, so they don't conflict, but two mutual-exclusion systems (Panel1 and overlay groups) must be kept in step by a bridge.
- **Expected:** H01 §5 ("evaluate existing IPC", one versioned contract); H03 §17.4 (document IPC connections).
- **Actual:** `nyx-shell/docs/ARCHITECTURE.md:20-31`, `MIGRATION.md:59-65,76-82`, `actions.rs:13-25`.
- **Reproduce / verify:** n/a (static).
- **Evidence:** above.
- **Affected versions:** header revisions.
- **User impact:** none directly; failure analysis and testing must cover every path.
- **Recommended correction:** keep `nyx-ui-link` (backend data) and Shell Core (coordination); retire `Panel1` toggling and the switcher socket's overview line once components register overlays; document the remaining set in one table.
- **Effort:** M
- **Dependencies:** NYX-ARCH-002
- **Verification criteria:** one table in nyx-shell docs lists every shell IPC path, and `Panel1` has no consumers.

### NYX-ARCH-006: Desktop Widgets aren't enabled on any NyxOS configuration

- **Component:** nyxos `modules/nixos/apps.nix`, nyx-packages, release inventory
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** implemented, not verified (packaged, enabled nowhere)
- **Description:** The package and its QML exist and the option `nyx.desktop-widgets.enable` exists, but neither the base tier, the example host, the dev VM nor the catalog turns it on. `apps.nix`'s comment and the release inventory say `nyx-shell-qs` draws Desktop Widgets.
- **Expected:** H03 §9 (Desktop Widgets in scope); release inventory accuracy (H10 Gate I).
- **Actual:** option `nyx-packages/modules/nixos/default.nix:54`; not set in `nyxos/modules/nixos/apps.nix:54-63` (comment at `:61-62` claims it), `hosts/incus-dev/default.nix:25-61`, or `nyx-system/crates/nyx-catalog/catalog.toml`; `release-inventory.md` row "Shell Core, OSD, CC panel, widgets, window menu".
- **Reproduce / verify:** `nix eval /etc/nyxos/flake#nixosConfigurations.<host>.config.nyx.desktop-widgets.enable` → `false`.
- **Evidence:** above.
- **Affected versions:** nyxos `97f1573`.
- **User impact:** an H03 component is absent; the inventory overstates what ships.
- **Recommended correction:** decide: enable it in `apps.nix` (after a runtime check) or mark it "not shipped" in the inventory and fix the comment.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** inventory and configuration agree.

### NYX-ARCH-007: Notification Center and Switcher still run their GTK front ends on NyxOS

- **Component:** nyx-packages `pkgs/nyx-notification-center.nix`, `pkgs/nyx-switcher.nix`
- **Category:** architecture
- **Severity:** P3
- **Status of feature:** approved, not implemented (on NyxOS)
- **Description:** Both have QML front ends and Rust backends (used on the laptop), but the NyxOS packages autostart the GTK units and don't install the QML or backend units. Not a regression: H03 §18 allows staged moves and the GTK versions are the baseline.
- **Expected:** H03 §7, §8 (migration), §18 Stage J.
- **Actual:** `nyx-packages/pkgs/nyx-notification-center.nix:33-35,49-52`; `nyx-packages/pkgs/nyx-switcher.nix:14-15`; `nyx-shell/docs/HANDOFF-03.md:77-81`.
- **Reproduce / verify:** `systemctl --user list-units 'nyx-*'` in the VM.
- **Evidence:** above.
- **Affected versions:** nyx-packages `d69e87e`.
- **User impact:** two UI toolkits in the shell, two more watchers (NYX-ARCH-001), and the GTK Switcher's keyboard model rather than the QML one; otherwise working.
- **Recommended correction:** move them as the Dock moved (`pkgs/nyx-dock.nix:14-30`) after a parity run in the VM, or record them as GTK for 0.1.0.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** the release inventory states which toolkit each ships with.

### NYX-ARCH-008: Shell documentation describes an older NyxOS arrangement

- **Component:** nyx-shell `docs/`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Several claims no longer hold: Shell Core "off by default" and `nyx-shell-qs` "installed but not started"; "Nyx Bar stays GTK"; the Dock "GTK until its package moves"; process table "GTK panels, dock, bar, widgets: as today"; session order step 3 "when enabled" and step 4 "GTK panels start as before". The real startup order (backends and the runtime start in parallel after `graphical-session.target`; QML reconnects to each backend with backoff) isn't written down.
- **Expected:** H01 §16 item 13, H03 §17.4 (documented runtime boundaries and startup).
- **Actual:** `nyx-shell/docs/NYXOS.md:3-4,17-20,45-46,69-77`; `MIGRATION.md:10,16`; `ARCHITECTURE.md:230`; against `nyxos/modules/nixos/apps.nix:63`, `nyx-packages/pkgs/nyx-shell.nix:34-37`, `pkgs/nyx-bar.nix:96-99`, `pkgs/nyx-dock.nix:26-30`.
- **Reproduce / verify:** read side by side.
- **Evidence:** above.
- **Affected versions:** nyx-shell `975092e`.
- **User impact:** maintainers and testers follow wrong instructions.
- **Recommended correction:** one "NyxOS today" table in `NYXOS.md` generated from the packages' `autostart` lists; date-stamp historical sections.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** every NyxOS claim in the docs matches `nyx-packages` at the pinned revision.

### NYX-ARCH-009: Omarchy leftovers in code that runs on NyxOS

- **Component:** nyx-shell, nyx-control-center, nyx-dock
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** partial
- **Description:** Most Omarchy references are guarded adapters (acceptable under H01 §11 "platform adapters"). Two have NyxOS consequences: window **minimize** exists only through `omarchy-hyprland-window-minimize`, so it is never offered on NyxOS; and Control Center ops and topics are still named `omarchy.*` (they fall back to `nyx-notifyd`, `hyprsunset`, `systemd-run` without Omarchy). The Dock seeds first-run pins from `~/.config/omarchy/shell.json` when present.
- **Expected:** H01 §11 ("avoid hardcoded Omarchy-specific paths in the core architecture").
- **Actual:** `nyx-shell/crates/nyx-shell-core/src/window.rs:10-18`, `compositor.rs:72-76,168`; `nyx-control-center/qml/ControlCenter/TileView.qml:42,50,58`, `crates/nyx-providers/src/omarchy.rs:27-29,138-145`; `nyx-dock/apps/dock-backend/src/main.rs:122,129-130`.
- **Reproduce / verify:** window menu on a floating window in the VM: no Minimize.
- **Evidence:** above.
- **Affected versions:** header revisions.
- **User impact:** no minimize on NyxOS; naming confuses maintenance.
- **Recommended correction:** a NyxOS minimize (special workspace via Shell Core dispatch) or drop the action explicitly; rename the `omarchy` provider to a platform adapter.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** no `omarchy-*` executable is required on any NyxOS code path.

### NYX-ARCH-010: Component backends accept any same-user client

- **Component:** nyx-core `nyx-ui-link`; every `*-backend`
- **Category:** security
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** Shell Core limits same-user programs to read-only by executable; the component backends set no `allow` filter, so any same-user process can drive them (empty Trash, uninstall through Store, read notification history via the Notification Center backend where shipped, run Control Center ops). Same-user is the documented boundary (`SECURITY.md:41-44`), so this is inconsistency, not a bypass.
- **Expected:** H01 §5 ("authorize operations according to component capabilities", "do not assume a Unix socket is secure merely because it is local").
- **Actual:** `nyx-core/crates/nyx-ui-link/src/lib.rs:79-80,89-98,272-276` (uid check only); `nyx-dock/apps/dock-backend/src/main.rs:777-791,900`; `nyx-bar/apps/bar-backend/src/main.rs:100`; `nyx-control-center/apps/control-center-backend/src/main.rs:167`.
- **Reproduce / verify:** in the VM, `printf '{"v":1,"id":1,"op":"Hello"}\n' | nc -U $XDG_RUNTIME_DIR/nyx-dock/ui.sock` from a shell.
- **Evidence:** above.
- **Affected versions:** nyx-core as pinned by each component.
- **User impact:** a compromised same-user process gets a convenient API; low, since it already has the user's files and `hyprctl`.
- **Recommended correction:** set `allow` to the trusted Quickshell runtime and the component's own CLI (the same `nyx-peer` check Shell Core uses).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `nc` from a shell is refused; the runtime and `nyx-dock --toggle`-style CLIs still work.
