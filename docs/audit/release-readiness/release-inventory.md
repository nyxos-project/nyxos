# Release inventory

What a NyxOS 0.1.0 install actually ships, from the configuration rather than from the
handoffs. Sources: [modules/nixos/apps.nix](../../../modules/nixos/apps.nix) (what every
install enables), nyx-packages' NixOS module, the software catalog
(`nyx-system/crates/nyx-catalog/catalog.toml`, which Welcome and Store read: `tier =
"base" | "welcome" | "store"`), [templates/host/example-host.nix](../../../templates/host/example-host.nix)
(what the installer writes) and [hosts/incus-dev](../../../hosts/incus-dev/default.nix)
(the development VM, which turns on many more apps to test their packages).

The **status** column is the audit's verdict after Phases C to F; the evidence is in the
linked reports. Status values follow handoff 10 section 2: verified, implemented but not
verified, partial, approved but not implemented, exploratory, deprecated.

## Tier 1: on every install (base)

| Component | Package / option | Repository | Status (this audit) |
| --- | --- | --- | --- |
| Compositor | `programs.hyprland` with nyx-packages' patched Hyprland 0.57.2 | `nyx-hyprland` | Verified in VM (fullscreen workspaces, wrap); patches untested by automation (NYX-HYPR-004) |
| Boot splash, login | `nyx-plymouth`, `nyx-greeter` (greetd) | same | Verified on the installed VM (greeter sign-in) |
| Lock screen, polkit agent | `nyx.locker`, `nyx.prompt` | `nyx-greeter` (locker, prompt), `nyx-biometrics` | Lock chain verified (crash fallbacks) |
| Shell Core, OSD, CC panel, window menu | `nyx.shell` | `nyx-shell` | Implemented; partly bypassed by surfaces (NYX-ARCH-001/002); crash-loop gap (NYX-SHELL-001) |
| Desktop Widgets | packaged | `nyx-desktop-widgets` | Packaged but enabled on no host (NYX-ARCH-006): not in the release |
| Bar, Dock, Control Center, Glimpse | `nyx.bar`, `nyx.dock`, `nyx.control-center`, `nyx.glimpse` (Quickshell surfaces in `nyx-shell-qs`) | same | Verified in VM; no bar/dock on hot-plugged monitors (NYX-REL-003) |
| Notification Center, Switcher | `nyx.notification-center`, `nyx.switcher` | same | Running their **GTK** front ends on NyxOS (Quickshell migration not done, NYX-ARCH-007) |
| Theme Engine | `nyx.themes` (`nyx-themed`, `nyx-theme`, `Nyx.Theme` QML), wallpapers | `nyx-system`, `nyx-design`, `nyx-wallpapers` | Verified: live switching; contrast gaps (NYX-A11Y-002) |
| System Manager, recovery, updates | `nyx.system` | `nyx-system` | Rollback and failed-build undo verified; breaks after GC on installs (NYX-INST-002); interrupted change (NYX-REL-002) |
| AI Core | `nyx.ai` (started on first use) | `nyx-ai` | Verified working (VM); unauthenticated endpoint (NYX-SEC-001) |
| Nyx Connect | `nyx.connect` (upstream fluxd 0.19.1 + patch) | `flux` | Failure handling verified; pairing not verified (no phone) |
| Online Accounts | `nyx.accounts` | `nyx-accounts` | Implemented, not verified (development preview; MAIL-001) |
| Apps | Settings, Store, Files, Capture, Activity, Backup, Share, Welcome | same | All open (smoke); Backup restore verified; Share blocked by firewall (SHARE-001) |
| CLI | `nyx` (nyxos `pkgs/nyx-cli`), `nyx-actions`, icons | `nyxos`, `nyx-core`, `nyx` | Verified (update, system, settings, devices commands) |
| Accessibility | (none: `services.gnome.at-spi2-core` off) | `nyxos` | **Disabled** (NYX-A11Y-001) |
| Installer | live USB | `nyx-installer`, `nyxos/iso` | **Broken on 0.1.0** (NYX-INST-001); works once `/mnt` exists |

## Tier 2: offered in Welcome (installed per user, preselected for four)

Notepad, Calculator, Archive, Photos (preselected; `standaloneApps = "per-user"` on new
installs). Status: every Tier 2 and 3 app opens from the dock and Glimpse in the VM
(smoke tests); per-user installation of two apps with session units fails (NYX-PKG-008)
and per-user apps lack D-Bus activation and actions until wired (NYX-PKG-009). Per-app
status is in each scorecard under apps/. Also offered: Mail, Calendar, Contacts, Notes, Office, PDF, News, Music,
Lyra, Media Player, Theater, Home, Containers, Git, Passwords, Torrents, Pulse,
Assistant, Chat.

Assistant pulls in Nyx Voice (`nyx.voice` defaults to `nyx.assistant.enable`); Chat and
Assistant use AI Core.

## Tier 3: Store only

Weather, Maps, Reminders, Clipboard, Transfer, Cloud.

## Not offered to users

| Item | Status |
| --- | --- |
| Nyx Agents | Packaged; enabled only on the dev VM; not in the catalog |
| Nyx Fonts | Packaged; not in the catalog |
| Nyx Biometrics (face, fingerprint, key) | Packaged with a NixOS module; turned on only in a machine's NixOS configuration (the dev VM does); no catalog entry, and Settings can't turn it on (apps/biometrics.md) |
| Nyx Browser | Not packaged (1.2k-line prototype) |
| nyx-themes | Not packaged; superseded by nyx-design's themes |
| Assistant Aura | Implemented inside nyx-assistant (`assistant-visual`), not a shell component; default doesn't leave room for Nyx Bar (NYX-SHELL-008) |

## Handoff concepts and where they live

| Handoff concept | Real component | Notes |
| --- | --- | --- |
| Nyx Shell Core (H01) | `nyx-shell`: `nyx-shell-core` daemon, `nyx-shellctl`, `nyx-shell-proto` | QML host `nyx-shell-qs` in the same repo |
| Quickshell components (H03) | `nyx-dock`, `nyx-control-center`, `nyx-notification-center`, `nyx-switcher`, `nyx-desktop-widgets`, `nyx-bar`, Glimpse panel | Each keeps a Rust backend (`*-backend`) and QML front end |
| Theme Engine 2.0 (H02) | `nyx-design` (`nyx-theme-core`, `nyx-theme`, `nyx-theme-cli`), `nyx-system/apps/themed` | One schema, GTK and QML adapters |
| Shared AI Core (H04) | `nyx-ai` (`nyx-aid`, `nyx-ai-client`), `llama-prism` package | PrismML llama.cpp build |
| Chat, Glimpse 2.0, Assistant 2.0 (H05) | `nyx-chat`, `nyx-glimpse`, `nyx-assistant` | |
| Nyx Voice (H05) | `nyx-voice` (`nyx-voiced`, `nyx-voice-asr`) | sherpa-onnx |
| Shared action registry (H05) | `nyx-core/crates/nyx-actions`, `share/nyx/actions` manifests | |
| Nyx Connect (H06) | upstream `fluxd` (nyx-packages `flux.nix` + `flux-nyxos.patch`), `nyx-core/crates/nyx-connect`, `nyx-devices` | |
| Unified updates (H08) | `nyx-system/crates/nyx-update`, `nyx` CLI, nyxos `tool-updates.yml` | |
| Settings and defaults (H09) | `nyx-settings`, `nyxos/defaults`, `nyx-core/crates/nyx-capability` | |
| Handoff 07 | No document in `~/Downloads/NyxOS` | Not audited against |
