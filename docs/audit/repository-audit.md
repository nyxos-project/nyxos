# Nyx repository audit for NyxOS

Audited 2026-11-02 from local checkouts in `~/Projects` (default branches). Read-only:
code, manifests and install scripts were inspected; nothing was built. Phase 2 repeats
this for every app it packages.

Classification:

1. Ready to package
2. Requires minor NixOS adaptation
3. Requires significant platform integration
4. Requires replacement
5. Incomplete or not ready

## Cross-cutting findings

- No repository ships a `flake.nix` or `default.nix`. CI runs in a pinned Arch
  container (`tools/ci-bootstrap.sh` uses `pacman`).
- Builds pin Rust 1.99.1, edition 2024, x86_64 only, and gtk4-rs with `v4_18`
  (GTK 4.18 or newer). No repository uses libadwaita; the dock and panels use
  gtk4-layer-shell. SQLite is rusqlite `bundled`; D-Bus is zbus (pure Rust); TLS is
  rustls. nixpkgs 26.05 may not carry Rust 1.99, so `nyx-packages` will likely need
  `rust-overlay` (Herdr already does this).
- Sibling crates are git dependencies pinned by `rev`, never `path`. The pins
  disagree: `nyx-core` is pinned at `52cba5e`, `44d4d4c` and `9dc1962`; `nyx-design`
  at `5c41729`, `976fed9`, `144e77d` and `d6400bb` (local heads: `nyx-core` `1c309f2`,
  `nyx-design` `bcbd8dd`). Every pin needs a `cargoLock.outputHashes` entry, so
  `nyx-packages` should align them first.
- Every `install.sh` is a copy of the suite installer: `sudo pacman -S` for
  dependencies, binaries into `~/.local/bin`, omarchy-shell QML plugins into
  `~/.config/omarchy/plugins`, edits to `~/.config/hypr/hyprland.lua`, and for some
  apps `sudo`/`pkexec` writes to `/usr/local/lib` and `/usr/share/polkit-1/actions`.
  None of this applies on NixOS; derivations and modules replace it.
- Desktop components reach Hyprland through `nyx-desktop` (in `nyx-core`), which uses
  the Hyprland sockets directly, plus `hyprctl` and many `omarchy-*` scripts. Those
  scripts are the main porting surface.

## Libraries and suite

| Repository | Class |
| --- | --- |
| `nyx-core` | 2 |
| `nyx-design` | 2 |
| `nyx-fonts` | 2 |
| `nyx` (suite installer) | 3 |
| `nyx-themes` | 4 |

**nyx-core.** Library workspace, 14 crates (about 35k lines, 19.7k of them generated
EDS bindings). Provides app identity, XDG paths (`XDG_*` honoured everywhere, suite
settings under `<config>/nyx`), TOML preferences, D-Bus control, accounts metadata
(GOA/EDS), WebDAV sync and PIM storage. Needs `libedataserver-1.2`, `libecal-2.0`,
`libical-glib` and `json-glib-1.0` via pkg-config. Git dependency on
`nyx-accounts`. The `nyx-desktop` crate is class 3 on its own: it calls `hyprctl`,
`omarchy-hyprland-workspace-layout-toggle` and reads Omarchy state. About 160 tests.

**nyx-design.** Library workspace: `nyx-theme`, `nyx-ui`, `nyx-playback`,
`nyx-icons`. Has a real token system (`Palette` and `Look`) and 17 bundled themes,
including `nyx-dark` and `nyx-light`. Style is flat with solid surfaces; there is no
glass or `backdrop-filter`. Defaults to "Follow Omarchy" when
`$XDG_STATE_HOME/omarchy/current/theme` exists, so NyxOS needs its own default theme
source. Fonts (Inter, JetBrains Mono) must be supplied by the system.

**nyx-fonts.** One binary. Plain `buildRustPackage` with `fontconfig` and `gnutar`
on `PATH`; user fonts in `~/.local/share/fonts` work on NixOS.

**nyx.** No Rust any more: `suite.toml` pins about 30 app repositories by revision
and artifact hash, and `tools/install-suite.py` installs them imperatively. The
installer and its icon/theme hooks don't fit Nix, but `suite.toml` is a useful source
of pins for generating `nyx-packages`.

**nyx-themes.** Data only, in Omarchy's theme format. The same palettes already live
in `nyx-design`; NyxOS themes should come from there.

## Desktop shell

| Repository | Class |
| --- | --- |
| `nyx-files` | 2 |
| `nyx-dock` | 3 |
| `nyx-control-center` | 3 |
| `nyx-notification-center` | 3 |
| `nyx-glimpse` | 3 |

**nyx-dock.** About 3.9k lines. Layer-shell, one window per monitor, folder stacks,
MPRIS controls, badges, auto-hide, and window previews via `ext-foreign-toplevel-list`
and `ext-image-copy-capture`. Omarchy ties: enable/disable through
`omarchy-plugin-*`, pin import from Omarchy's dock, `omarchy-launch-*`, Omarchy theme
colours.

**nyx-control-center.** About 8.8k lines. Provider modules for VPN, Tailscale, audio,
network, power, DNS, display and brightness, built on `nmcli`, `pactl`,
`brightnessctl` and VPN CLIs, but about 25 tiles wrap `omarchy-*` scripts that NyxOS
must supply or replace.

**nyx-notification-center.** About 4.9k lines: panel, `nyx-notifyd`, and a store
crate. It already implements `org.freedesktop.Notifications` with zbus and draws its
own layer-shell toasts, with SQLite history, retention and pins, but only with
`--use-nyx-popups`. The default mode reads Omarchy's notification files. Making the
standalone mode the default is the shortest path. Has a D-Bus compatibility test
suite.

**nyx-glimpse.** About 11.3k lines: launcher, indexer daemon, plugin SDK. Needs a
llama.cpp derivation for `inference/`, its plugin sandbox hardcodes `/usr/bin` paths
that don't exist on NixOS, and it calls `hyprctl` and `omarchy-menu` directly.

**nyx-files.** Strata fork, about 395k lines, GPL-3.0-or-later, extensive tests.
General-purpose; Omarchy code is optional. The work is a long native dependency list
(gtksourceview5, poppler-glib, GStreamer, `unrar_sys`) and runtime tools (`bwrap`,
`ffmpeg`, `ffmpegthumbnailer`, `dcraw`).

## System applications

| Repository | Class |
| --- | --- |
| `nyx-accounts` | 1 |
| `nyx-backup` | 2 |
| `nyx-settings` | 3 |
| `nyx-biometrics` | 3 |
| `nyx-store` | 4 |

**nyx-accounts.** About 3k lines, no GTK. `nyx-accountsd` (session D-Bus,
`io.github.design_nexus.nyx.Accounts1`) and `nyx-accountsctl`. Secret Service for
tokens, SQLite for metadata. No Omarchy or pacman references; needs only a user D-Bus
service. Caveat: preview maturity; Microsoft sign-in unverified.

**nyx-backup.** About 10.7k lines: GTK app, `nyx-backupd` (user systemd and D-Bus),
CLI, and an offline whole-disk recovery tool. Wraps `restic`, `rclone` and
`secret-tool`; user-level install only. No system restore from the desktop side.
`backup-migrate` and inventory are pacman/Omarchy-specific, and the recovery kit
depends on mkinitcpio, so both need NixOS replacements.

**nyx-settings.** About 35k lines plus 13 hardware extension crates. Writes Hyprland
settings to `~/.config/hypr/settings.lua` (applied live) and Omarchy settings to
`~/.config/omarchy/shell.json`. 457 Omarchy references; Software/Home pages read
pacman/AUR; the root helper runs `useradd`, `ufw`, `localectl`, `hostnamectl` and
`timedatectl`, all of which conflict with declarative NixOS. Reusable: UDisks2 over
zbus, NetworkManager, PipeWire EQ, Bluetooth, power profiles, brightness, CUPS, and
the DDC/ASUS/OpenRGB/tablet extensions. The brief already calls for a NyxOS rebuild.

**nyx-biometrics.** About 8.8k lines, 8 crates: session broker, socket-activated root
key daemon (TPM via `systemd-creds`), pkexec helper, PAM gate. It writes PAM stacks
directly into `/etc/pam.d` with snapshot and timed rollback. NixOS generates
`/etc/pam.d` read-only, so this must become a NixOS module that sets
`security.pam.services.<name>`. Face backends (`irlume`, `gaze`) are not in nixpkgs.
The policy engine, broker and key daemon are reusable.

**nyx-store.** About 4.3k lines. The package backend is pacman/AUR/BlackArch
throughout (`/var/lib/pacman`, `makepkg`, `pacman-key`). Reusable: the home/shelves
UI, AppStream catalog parsing and artwork handling. The NyxOS Store is a new
implementation; the Omarchy Store stays as is.

## Phase 2: remaining repositories

Audited 2026-11-03, same method. Packaged so far in
[nyx-packages](https://github.com/nyxos-project/nyx-packages): `nyx-accounts`,
`nyx-fonts`, the `nyx-design` icons, and test checks for `nyx-core` and `nyx-design`.

### Findings that apply to many repositories

- systemd user units start programs from `%h/.local/bin` or `%h/.local/lib`, and D-Bus
  activation files use `Exec=/usr/bin/false` with `SystemdService=`. Packages must
  install both with store paths. Affects calendar, chat, clipboard, cloud, home, mail,
  passwords, reminders, share and transfer.
- Calendar, Contacts, Reminders and Settings use `nyx-pim`, which requires libical 4;
  nixpkgs 26.05 has 3.0.20. See nyx-packages `docs/compatibility.md`. They're blocked
  on a small upstream change in nyx-core, whatever their class below.
- Calendar, Contacts, Clipboard, Mail and Reminders lock two nyx-core revisions
  (`52cba5e` and `9dc1962`) at once. That builds, but aligning on one is cleaner.
- Outside Glimpse and Assistant, Omarchy ties in Rust are mostly the default
  `ThemeMode::Omarchy` in `nyx-theme`. A NyxOS theme source in nyx-design fixes them
  all at once.
- None use libadwaita. Every GTK app needs only the GTK 4 stack plus the extras listed.

### Not separate packages

| Directory | What it is |
| --- | --- |
| `nyx-assistant-auth` | Worktree of `nyx-assistant` (branch `secrets-through-broker`) |
| `nyx-passwords-face` | Worktree of `nyx-passwords` (branch `face-unlock`) |
| `nyx-passwords-ssh-ext` | Branch `extension-ssh-keys` of `nyx-passwords`, no directory |
| `nyx-glimpse-protected` | A copy of Glimpse (see `nyx-glimpse` above) |
| `nyx-integration-audit` | Markdown and JSON reports, no code |

### Applications

| Repository | Class | Extra native deps | Runtime tools to wrap | Notes |
| --- | --- | --- | --- | --- |
| `nyx-notepad` | 1 | none | none | Simplest build in the set |
| `nyx-calculator` | 1 | bundled SQLite | `hyprctl` (optional) | |
| `nyx-archive` | 1 | none | `7zz` | |
| `nyx-pdf` | 1 | poppler-glib 24.12+ (nixpkgs 26.10) | `xdg-open` | Pulls in nyx-share crates |
| `nyx-news` | 1 | bundled SQLite | `xdg-open` | Pulls in nyx-glimpse SDK |
| `nyx-office` | 1 | gtksourceview5, libspelling | `qpdf` | 43k lines, 129 tests |
| `nyx-contacts` | 1 | libical-glib | none | Blocked on libical 4 |
| `nyx-maps` | 1 | libshumate 1.7+ | none | Blocked: nixpkgs has libshumate 1.6.3 |
| `nyx-git` | 2 | gtksourceview5 | `git`, `ssh`, `secret-tool` | |
| `nyx-music` | 2 | GStreamer plugin sets | `notify-send` | |
| `nyx-media-player` | 2 | libmpv | `ffmpeg`, `yt-dlp` | |
| `nyx-theater` | 2 | libmpv | `secret-tool` | |
| `nyx-photos` | 2 | none | `ffmpeg`, `ffmpegthumbnailer` | "Set as background" calls `omarchy-theme-bg-set` |
| `nyx-home` | 2 | OpenSSL (native-tls) | `wpctl`, `secret-tool` | Unit and D-Bus files templated with `@BINDIR@` |
| `nyx-share` | 2 | none | `wl-copy`, `tailscale`, `bwrap` | Shared service; sandbox sets `PATH=/usr/bin` |
| `nyx-transfer` | 2 | none | `rclone`, `ssh-keygen` | D-Bus service |
| `nyx-cloud` | 2 | none (no GTK) | `rclone`, `fusermount3` | Needs the setuid `fusermount3` wrapper |
| `nyx-clipboard` | 2 | gtk4-layer-shell | `wtype` | Daemon, D-Bus service |
| `nyx-chat` | 2 | none | `llama-server` | Replace its llama.cpp installer with nixpkgs `llama-cpp` |
| `nyx-activity` | 2 | none | `nvidia-smi` | Reads `/usr/share/hwdata/pci.ids` and Omarchy autostart |
| `nyx-containers` | 2 | vte4, gtksourceview5 | `docker`, `incus` | Fix-it hints use pacman; should point to NixOS options |
| `nyx-torrents` | 2 | libtorrent-rasterbar 2, Boost | `python3` | C++ shim via cxx |
| `nyx-weather` | 2 | none | `hyprctl` | Bar widget targets the Omarchy shell |
| `nyx-calendar` | 2 | libical-glib | `systemctl` | Blocked on libical 4 |
| `nyx-reminders` | 2 | libical-glib | `systemctl` | Blocked on libical 4 |
| `nyx-mail` | 3 | WebKitGTK 6.0 2.50+ (nixpkgs 2.54) | `systemctl` | Six Git dependencies; daemon unit path |
| `nyx-capture` | 3 | gtk4-layer-shell, onnxruntime | `grim`, `slurp`, `ffmpeg`, `tesseract` | `ort` downloads binaries at build time; needs `omasnap` |
| `nyx-passwords` | 3 | aws-lc | `pkcheck`, `secret-tool` | Polkit action, browser native-messaging hosts, root broker |
| `nyx-pulse` | 3 | libclang, TDLib, libntgcalls | `python3`, `ffmpeg` | Downloads prebuilt libraries; hardcoded `/usr` paths |
| `nyx-assistant` | 3 | llama.cpp, whisper, sherpa-onnx, onnxruntime, PipeWire | many | pacman tools, Omarchy crate, root helper, Quickshell HUD |

### Packaging order

1. No blockers, no services: notepad, calculator, archive, pdf, news, office.
2. Wrappers only: git, music, media-player, theater, photos.
3. Services (needs a shared helper for unit and D-Bus files): share, transfer, cloud,
   clipboard, home, chat.
4. After the libical change in nyx-core: contacts, calendar, reminders. Maps after
   libshumate 1.7 reaches nixpkgs, or with an overlay.
5. Need NixOS modules, not just packages: mail, capture, passwords, pulse, assistant,
   and the Omarchy-coupled shell pieces (dock, control center, notifications, glimpse).
