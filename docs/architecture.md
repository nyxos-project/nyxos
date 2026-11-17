# NyxOS architecture

How NyxOS 0.1 is put together: where its parts come from, what runs on an installed
machine, and how changes reach it. The [security model](security.md) covers who is
trusted with what. Component designs live in their own repositories (linked below).

## Where it comes from

| Repository | What it holds |
| --- | --- |
| [nyxos](https://github.com/nyxos-project/nyxos) (this one) | The distribution flake: NixOS modules (`modules/nixos`), Home Manager defaults (`modules/home`), the live USB (`iso`), the development VM (`hosts/incus-dev`), the `nyx` command (`pkgs/nyx-cli`) and the pinned coding agents and tools (`pkgs/tools`) |
| [nyx-packages](https://github.com/nyxos-project/nyx-packages) | Every Nyx package and its NixOS module (`nyx.<app>.enable`), the forks and newer libraries NyxOS needs ahead of nixpkgs, and CI checks (Hyprland's tests, Files' VM tests, overrides, the CUDA worker) |
| [nyx-system](https://github.com/nyxos-project/nyx-system) | The Nyx System Manager, the software catalog (`crates/nyx-catalog/catalog.toml`) and the update engine |
| [nyx-hyprland](https://github.com/design-nexus/nyx-hyprland) | Hyprland's patch series, one folder per Hyprland release (`patches/0.57.2`) |
| App repositories (`design-nexus/nyx-*`) | Each Nyx app, built on the shared crates of nyx-core (desktop, plugins, peers) and nyx-design (theme, widgets) |

nyx-packages pins each source by revision in its `flake.lock`; nyxos pins nyx-packages
the same way. Every app builds against one revision of each shared crate
(`scripts/shared-pins` in nyx-packages checks it). NyxOS is built on NixOS 26.05, with
Rust from rust-overlay at the version the Nyx repositories name.

## Channels

- `main`: development. Every change lands there first; CI builds it and fills the
  binary cache (`nyxos.cachix.org`).
- `stable`: what installed machines follow. `scripts/promote-stable` moves nyxos'
  and nyx-packages' `stable` together, only forward, only to commits whose CI passed,
  and tags the nyxos commit `known-good/<n>` with the release key. `stable` requires a
  passing `ci` check.

A machine's `/etc/nyxos/flake` is a copy of the channel's flake with its own lock. On
`stable`, `nyx update` moves it only to a `known-good` tag signed by a key in
`release-signers`; on `main` (testing) it takes the branch as it is.

## Configuration

Three layers, later ones winning key by key ([README](../README.md#configuration-layers)):

1. Distribution defaults: this flake and `/etc/nyxos/defaults/`.
2. System overrides: `/etc/nyxos/overrides/system.json` (the flake's `nyxos-overrides`
   input) and per-domain TOML, written only by the Nyx System Manager.
3. User settings in `~/.config/nyx/`, written by the user's apps.

A system change is a rebuild: the manager builds the new system first and switches to
it only if the build succeeds, and snapper takes Btrfs snapshots before and after.
Every generation stays in the boot menu with a NyxOS Recovery entry beside it.

## Boot and sign-in

Limine shows the generations (and Windows, when it's there), Nyx Plymouth the splash,
then greetd starts Nyx Greeter in a bare Hyprland session in the login theme. Signing
in starts Hyprland through UWSM. NyxOS Recovery boots a text console without the
desktop or network and runs `nyx-recovery` after an administrator's password.

## The desktop

- **Hyprland 0.57.2** from Hyprland's own flake, built with the Nyx patch series:
  workspace-swipe wrap, virtual monitors, fullscreen on its own workspace, layers that
  slide with their workspace.
- **Nyx Shell**: Nyx Shell Core, a Rust daemon holding the one model of Hyprland's
  monitors, workspaces and windows, and the Quickshell runtime (`nyx-shell-qs`) that
  draws the bar, dock, switcher, Glimpse's panel and other overlays from it
  ([nyx-shell](https://github.com/design-nexus/nyx-shell)). Panels still drawn in
  GTK 4 join its overlay policy over D-Bus (`Panel1`).
- **nyx-themed** applies each user's Nyx theme to Hyprland, the terminal, GTK and the
  wallpaper, live; the apps follow it through nyx-design.

## System and session services

| Service | Runs as | What it does |
| --- | --- | --- |
| Nyx System Manager (`nyx-system`) | root, D-Bus, started on demand | Typed system changes (settings, packages for everyone, services, users, updates, rollback, mounts, firewall), each a polkit action, logged to the journal |
| Nyx AI Core (`nyx-aid`) | the user, socket-activated | The local model runtime (llama.cpp) every Nyx app shares; an OpenAI-compatible endpoint only when turned on |
| Nyx Voice | the user, socket-activated | Dictation and speech for apps |
| Nyx Online Accounts | the user, D-Bus | Sign-in and tokens for Mail, Calendar, Contacts and Reminders |
| Nyx Biometrics | root key service and PAM | Face, fingerprint and security-key sign-in, when turned on in Settings |
| Nyx Connect (fluxd) | the user | Phone pairing; starts once a phone is paired |
| Nyx Share | the user, D-Bus | Nearby sharing (LocalSend's protocol) and the Share Sheet |
| Nyx Backup (`nyx-backupd`) | the user | Restic backups on schedule, restores, a recovery kit |

## Software

The catalog is one list shared by Welcome, the Store and `nyx install`. It has three
tiers: base (on every install), Welcome (offered at setup), and Store only. Nyx apps a
person installs go into their own Nix profile from the system's channel: no rebuild,
no password. Services, drivers and anything for everyone go through the System Manager
as a rebuild. The Store also installs Flathub apps for the user. Coding agents and tools
nixpkgs doesn't have come from pins in `pkgs/tools/sources.json`, updated by CI as pull
requests.

## Updates

`nyx update` (and Settings › Updates) updates the system to the channel's newest signed
revision, the user's Nyx apps and tools, and firmware when fwupd is on
([nyx-system docs/updates.md](https://github.com/nyxos-project/nyx-system/blob/main/docs/updates.md)).
A failed update leaves the running system as it was; `nyx rollback` or an earlier boot
entry goes back.
