# Nyx Settings: configuration audit

Handoff 09, stage A. Audited 2026-11-08 from the checkouts in `~/Projects` (read-only).
Paths under `src/` are `nyx-settings/apps/settings/src/`.

## Summary

- **The layered model the handoff asks for already exists, in one place.** `nyx-config`
  (`nyx-system/crates/nyx-config`) merges `/etc/nyxos/defaults/DOMAIN.toml`,
  `/etc/nyxos/overrides/DOMAIN.toml` and `~/.config/nyx/DOMAIN.toml` key by key, reports
  which layer a value came from, and resets by removing the user key. Shell Core and
  `nyx-system config` use it. It has no schema version, no migrations, no change watcher,
  and fails a whole domain when a file is malformed.
- **The shell components bypass it.** The dock, Control Center, bar and switcher keep
  `~/.config/nyx/{dock,control-center,bar,switcher}.toml`, the same file names as
  nyx-config's user layer, but each reads and rewrites the whole file itself. A NyxOS
  default can't reach them, and the first save freezes every built-in default into the
  user's file. Notification settings are a single JSON row in `notifications.db`.
- **Settings owns Hyprland overrides** in `~/.config/nyx-settings/state.json`, rendered to
  `~/.config/hypr/settings.lua`, loaded last over NyxOS's generated `hyprland.lua`. Reset
  (per row, device, display or page) removes the key. There's no schema version.
- **Capability detection is per page and binary-only.** `Section::visible` is mostly
  `cmd::present(program)`; extension pages are gated by their helper. There's no notion
  of "installed but inactive" or "temporarily unavailable", and a 4-second timer
  refreshes live pages.
- **No device is remembered.** Monitors are keyed by connector (`eDP-2`), so a scale set
  for a monitor on DP-1 applies to whatever is plugged into DP-1. Audio, touchpad and
  keyboard have no per-device storage; mice are keyed by Hyprland device name. Only the
  Logitech and Razer extensions keep per-device state.
- **Theme preference is stored twice.** `/etc/nyxos/defaults/appearance.toml` has
  `theme`; `nyx-theme-core` reads `~/.config/nyx/theme.toml`, which NyxOS seeds once at
  login. A later change of the NyxOS default never reaches an existing user.
- **Settings doesn't talk to Shell Core**, though Shell Core already grants `nyx-settings`
  the `config.write` capability.
- **The platform is chosen at compile time** (`--features nyxos`, `platform/mod.rs:20`).
  Shared pages still call Omarchy scripts directly in `backend/bt.rs`, `displays.rs`
  (brightness), `bar.rs`, `barlayout.rs`, `nightlight.rs`, `network.rs` and
  `trackpad.rs`; on NyxOS those rows fail or show nothing.

## Existing Settings capability matrix

"Detection" is how the page or row decides to show today. "NyxOS" is its state in a
`--features nyxos` build.

| Page | Backend | Owner of the data | Detection | NyxOS |
| --- | --- | --- | --- | --- |
| Home | `checkupdates`/`nyx-system update status`, `omarchy-version`, `powerprofilesctl` | System Manager, packages | always | works (OS name when `omarchy-version` is missing) |
| Wi-Fi | `nmcli` | NetworkManager | always | works |
| Bluetooth | `bluetoothctl`; power and pairing through `omarchy-bluetooth-*` | BlueZ | always | **pairing and power fail** (Omarchy scripts) |
| Network | `nmcli`, `omarchy-dns`, `omarchy-network-*`, `ufw` via helper, Tailscale/NordVPN CLIs | NetworkManager, firewall | always; VPN rows by CLI | DNS, band, speed test fail; firewall through System Manager |
| Network Drives | `/etc/fstab` via helper; `SystemSettings.mounts` on NyxOS | System Manager | always | works |
| Sharing | Nyx Share D-Bus (`Share1`) | Nyx Share | always | works |
| Displays | `hyprctl monitors all -j`; `state.monitors` → `settings.lua`; `omarchy-brightness-display` | Settings (Hyprland rules) | always; laptop group needs `omarchy-hw-laptop` | brightness and laptop group missing |
| Sound | `pactl`, `pw-dump`, PipeWire filter-chain EQ (`settings-eq.service`) | PipeWire/WirePlumber; Settings for EQ | always; limiter by LV2 file | works |
| Power | `powerprofilesctl`, `brightnessctl`, `platform::set_power` | System Manager (logind), power-profiles-daemon | battery by sysfs | works |
| Lock Screen | `shell.json` (Omarchy); `nyx-system config idle` (NyxOS) | NyxOS idle | always | works (NyxOS page) |
| Printers | CUPS, `cups-pk-helper` | CUPS | always | works |
| Disks | UDisks2 | UDisks2 | always | works |
| Appearance | `omarchy-theme-*` or `nyx_theme::engine` | Theme Engine | Omarchy palette present | works (engine) |
| Window Style | Hyprland options | Settings | always | works |
| Bar & Notifications | `omarchy-shell`, `omarchy-bar`, `shell.json` | Omarchy shell | always | **fails**: no Omarchy shell on NyxOS |
| Bar Plugins | `omarchy-plugin-*` / `nyx plugin` | plugin host | always | works (`nyx plugin`) |
| Night Light | `hyprsunset`, `omarchy-toggle-nightlight` | hyprsunset | always | toggle fails |
| Dock | `~/.config/nyx/dock.toml` (whole file) | Nyx Dock | `nyx-dock` on PATH | works, no NyxOS defaults |
| Control Center | `~/.config/nyx/control-center.toml` | Nyx Control Center | binary | works, no NyxOS defaults |
| Notifications | `Notifications1` D-Bus (`busctl`) | nyx-notifyd | binary | works |
| Switcher | `~/.config/nyx/switcher.toml` | Nyx Switcher | binary | works |
| Tiling & Workspaces | `state.workspaces`, `persistent_workspaces` | Settings | always | works |
| Workspace Profiles | `nyx_desktop::profiles` | nyx-desktop | always | works |
| Keyboard Shortcuts | `state.binds`/`unbinds`, `hyprctl binds` | Settings | always | works |
| Startup & Rules | `state.autostart`, rules, `~/.config/autostart` | Settings | always | works |
| Capture | `omarchy-capture-*`, `nyx-capture` | Capture | always | Omarchy rows fail |
| Keyboard / Mouse / Trackpad | `input.*`, `hl.device`; `omarchy-toggle-touchpad` | Settings | always; touchpad switches by `omarchy-hw-touchpad` | toggles missing |
| Users | `pkexec nyx-settings-helper` / System Manager | System Manager | always | works (NyxOS page) |
| Sign-in | `nyx-authctl` | Nyx Biometrics | `nyx-authctl` present | works |
| Online Accounts | `nyx_accounts_native`, `nyx_pim`, `nyx_cloud` | Nyx Accounts, Cloud | always | works |
| Local AI | `nyx-ai --json`, `nyx-aid.socket` | Nyx AI | `nyx-ai` present | works |
| Assistant (7 pages) | `nyx-assistant config` | Nyx Assistant | `nyx-assistant` present | works |
| Time & Language | `timedatectl`, helper / System Manager | System Manager | always | works |
| Boot | `omarchy-plymouth-*`, `limine` / System Manager | System Manager | always | works (NyxOS page) |
| Default Apps | `xdg-settings`, `mimeapps.list`, `nyx agent` | xdg | always | works |
| Software | `pacman`, `yay`, `flatpak` / System Manager | System Manager | always | works (NyxOS page) |
| Services | `systemctl` / System Manager | systemd | always | works |
| Extensions | git checkouts | Settings | always | works |
| About | backup, self-update | Settings | always | works |

## Configuration ownership map

Settings is the interface; the owner is the only writer of the authoritative value.

| Area | Owner | Authoritative store | How Settings changes it |
| --- | --- | --- | --- |
| Shell behaviour (focus restore, per-screen components, overlays, shortcuts) | Shell Core | nyx-config `shell` | Shell Core IPC `UpdateShellConfig`/`ResetShellConfig` |
| Dock | Nyx Dock | nyx-config `dock` | nyx-config user layer (the dock watches it) |
| Control Center layout | Nyx Control Center | nyx-config `control-center` | nyx-config user layer |
| Bar layout | Nyx Bar | nyx-config `bar` | nyx-config user layer |
| Switcher | Nyx Switcher | nyx-config `switcher` | nyx-config user layer |
| Notification settings | nyx-notifyd | `notifications.db` row over defaults `notifications` | `Notifications1.SetSettings` (changed fields only) |
| Theme | Theme Engine | `theme.toml` over nyx-config `appearance` | `nyx_theme::engine` |
| Hyprland look, input, workspaces, binds, rules | Settings | `state.json` → `settings.lua` over NyxOS `hyprland.lua` | itself |
| Monitor arrangement and scale | Settings (Hyprland rules) | `state.json` `monitors`, by monitor | itself; Hyprland applies on connect |
| Per-device input | Settings (`hl.device`) | `state.json` `devices` | itself; Hyprland applies on connect |
| Audio routing and volume | WirePlumber | WirePlumber state | `pactl`; per-device preferences rendered as WirePlumber rules |
| EQ | Settings | `audio.toml`, `settings-eq.service` | itself |
| Bluetooth pairing and trust | BlueZ | BlueZ | `bluetoothctl` |
| Fingerprint, face, keys | Nyx Biometrics | its own stores | `nyx-authctl` |
| Idle and lock times | NyxOS idle | nyx-config `idle` | `nyx-system config set idle` |
| Hostname, locale, keyboard layout, packages, services, users, mounts, power keys, boot and login theme | System Manager | `/etc/nyxos/overrides/system.json` | `nyx-system apply` (polkit) |
| System-wide defaults for every user | System Manager | `/etc/nyxos/overrides/DOMAIN.toml` | `SetDefault`/`ResetDefault` (polkit) |
| App-specific preferences (Chat personas, Vault, Assistant personas) | each app | each app | links to the app |
| Remembered-device index | Settings | `~/.config/nyx/devices.json` | itself; preferences stay with their owners above |

## Device identity and persistence assessment

| Category | Identifier available | Stable across ports and reboots | Unique | Used for | Notes |
| --- | --- | --- | --- | --- | --- |
| Monitor | EDID make, model, serial (`hyprctl monitors`), as `nyx_desktop::Monitor::stable_id()` = `make\|model\|serial` | yes | only with a serial; many cheap monitors report none or `0` | profile id; Hyprland `desc:` rules | Shell Core `monitors.screens` and the dock's `[monitors]` already use `stable_id`; the bar and Control Center use connector names. Two connected monitors with the same id are ambiguous: nothing is applied and Settings asks |
| Laptop panel | connector `eDP-*`/`LVDS-*`/`DSI-*` plus EDID | yes | yes | profile id | Its EDID is the identity; the connector only marks it internal |
| Audio output / input | PipeWire `node.name` (`alsa_output.usb-<vendor>_<product>_<serial>-00.analog-stereo`, `bluez_output.<MAC>.1`) | yes, for USB and Bluetooth; for onboard cards, per machine | USB devices without a serial collide | profile id; WirePlumber `node.name` match | WirePlumber already restores volume and route per node |
| Input (mouse, keyboard, touchpad) | Hyprland device name (`logitech-mx-master-3s`) | yes | no: two identical mice share a name | profile id; `hl.device` | Hyprland applies `hl.device` by name on connect; identical devices share a profile, which is the right behaviour for preferences |
| Bluetooth | BlueZ address | yes | yes | profile id (hashed in the index) | BlueZ owns pairing; Forget preferences, Disconnect and Unpair stay separate |
| USB storage | filesystem UUID | yes | yes | only when a mount is configured | Never remembered automatically |
| Fingerprint reader | USB vendor:product (nyx-auth-hw) | yes | per model | capability only | Enrolments belong to fprintd |

Raw identifiers are kept only where the owning subsystem needs them to match the device
(Hyprland's `desc:`, WirePlumber's `node.name`); the index stores Bluetooth addresses
hashed.

## Settings migration plan

| Store | Today | After | Migration |
| --- | --- | --- | --- |
| `nyx-settings/state.json` | no version; `monitors` by connector | `schema = 2`; `monitors` by `stable_id`, rendered as `desc:` rules | backup `state.json.v1.bak`; a connector entry becomes a profile the first time that monitor is seen connected; entries whose monitor never reappears stay connector-keyed and are listed under Remembered devices as "Display on DP-1" |
| `nyx-settings/settings.toml` | no version | `schema = 1` | add the field |
| `nyx/dock.toml`, `control-center.toml`, `switcher.toml`, `bar.toml` | whole file | only changed keys, `schema = 1` | backup `DOMAIN.toml.v0.bak`; drop keys equal to the component's built-in default, so they follow the NyxOS default |
| notifyd settings row | full JSON | changed fields only | drop fields equal to the built-in default |
| `nyx/theme.toml` | `theme` always written | `theme` only when the user chose one | drop a `theme` equal to the current system default when `mode = "theme"` |
| Omarchy laptop configuration | — | — | none: the capture is a development input, and no Omarchy-to-NyxOS migration tool is built (handoff §26.4) |
