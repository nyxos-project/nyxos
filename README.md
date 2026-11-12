# NyxOS

NyxOS is a NixOS distribution built around the Nyx desktop and applications. This
repository holds the distribution flake: NixOS modules, Home Manager defaults and host
definitions. Nyx applications stay in their own repositories and are packaged by
[nyx-packages](https://github.com/nyxos-project/nyx-packages).

Version: **NyxOS 0.1.0** ([VERSION](VERSION)), on NixOS 26.05. The version is what
`/etc/os-release`, Settings, Recovery, the boot menus and the live USB
(`nyxos-0.1.0-installer.iso`, `nix build .#iso`) show; NixOS's own stays in `BUILD_ID`.

The live USB isn't signed for Secure Boot: turn Secure Boot off in the computer's
firmware settings to start it. An installed NyxOS can sign its own boot with the
computer's own keys (`nyxos.boot.secureBoot`), keeping Microsoft's so Windows still starts.

Status: phase 1, a development VM that boots into the Nyx desktop. See [docs/dev-vm.md](docs/dev-vm.md) to run it and
[docs/audit/repository-audit.md](docs/audit/repository-audit.md) for the state of the
Nyx repositories.

## Layout

| Path | Contents |
| --- | --- |
| `flake.nix` | Inputs (nixpkgs 26.05, Home Manager, Herdr, nyx-packages) and outputs |
| `VERSION` | NyxOS's version |
| `iso` | The live USB: its own image, started by Limine on UEFI and BIOS (`live-image.nix`, `boot-menu.nix`) |
| `hosts/incus-dev` | The Incus development VM |
| `modules/nixos` | System defaults: Nix, users, network, audio, desktop, shell, packages, base Nyx apps |
| `modules/home` | User defaults: Foot, Zsh and the Nyx prompt, Helix, Herdr, Hyprland |
| `themes` | Theme tokens (Nyx Dark), mirrored from nyx-design |
| `pkgs/nyx-cli` | The `nyx` command on NyxOS |
| `pkgs/antigravity-cli` | Catalog packages nixpkgs lacks, added to `pkgs` by an overlay |
| `agents/skills` | Skills that teach coding agents NyxOS, shared by every agent ([docs/agent-skills.md](docs/agent-skills.md)) |
| `scripts/dev-vm` | Create, rebuild, snapshot and inspect the VM |

## Channels

- `main`: development; every change lands here first.
- `stable`: the last known-good state (`known-good/<n>` tags), with nyx-packages pinned at
  its own `stable`. Follow it with `github:nyxos-project/nyxos/stable`.

## Configuration layers

1. Distribution defaults: this flake, and `/etc/nyxos/defaults/` for user settings.
2. System overrides: `/etc/nyxos/overrides/`, written by the Nyx System Manager.
   `system.json` (host name, time zone, locale, keyboard, packages for everyone, the
   services NyxOS manages, the system, boot and login themes) is the flake's
   `nyxos-overrides` input; `DOMAIN.toml` files are every user's defaults.
3. User settings: `~/.config/nyx/`, written by the user's apps.

Later layers win, key by key. Updates replace only the first layer. Ordinary desktop
preferences change live; system settings are built and switched to (see below).

## System services

From [nyx-system](https://github.com/nyxos-project/nyx-system):

- **Nyx System Manager**: a root D-Bus service, started on demand, for Settings, Welcome,
  Store, the `nyx` command and recovery tools. Typed changes only, each kind authorized
  through polkit and written to the journal; a change is built before it's switched to,
  and undone if either fails. `nyx system` and `nyx service` drive it.
- **nyx-themed**: each user's Nyx theme (the one their apps follow) on Hyprland, Foot
  (and Helix, through the terminal's palette), GTK and the wallpaper, live.

Rollback without it: pick an earlier generation in the boot menu, or
`sudo nixos-rebuild switch --rollback --flake /etc/nyxos/flake#HOST`.

## The `nyx` command

Short commands for the Nix package manager. Each runs one `nix` command for the
current user; anything else goes to `nix` unchanged (`nyx build`, `nyx flake`, …).

| nyx | nix |
| --- | --- |
| `install PKG…` | `nix profile add nixpkgs#PKG…` |
| `remove PKG…` | `nix profile remove PKG…` |
| `update [PKG…]` | `nix profile upgrade --all` (or the packages named) |
| `list` | `nix profile list` |
| `search TERM…` | `nix search nixpkgs TERM…` |
| `run PKG [ARGS…]` | `nix run nixpkgs#PKG -- ARGS…` |
| `shell PKG… [-c CMD]` | `nix shell nixpkgs#PKG… [-c CMD]` |
| `rollback` / `history` | `nix profile rollback` / `history` |
| `clean` | `nix-collect-garbage -d` |

A name starting with `nyx-` comes from nyx-packages
(`github:nyxos-project/nyx-packages#nyx-pdf`); anything with `#` or `:` is used as
given. `nyx icons …`, `nyx share …` and `nyx plugin …` run the Nyx tools as on Omarchy.
`nyx agent` starts the default coding agent (Settings > Default Apps, or `nyx agent default
CMD`) with its flag for working without stopping to ask, as Super Shift Ctrl A does; `nyx
agent skills` links NyxOS's skills into every agent's skills folder.
`nyx system …` and `nyx service NAME on|off|default` go to the Nyx System Manager:
system settings, packages for everyone, `update`, `generations` and `rollback`.

## Defaults

- Terminal: Foot. Shell: Zsh with autosuggestions, syntax highlighting, fzf, zoxide
  and a native prompt. Editor: Helix (`EDITOR=hx`, `VISUAL=hx`). Multiplexer: Herdr,
  installed but not started automatically. Bash remains for scripts and root.
- Desktop: Hyprland through UWSM, PipeWire and WirePlumber, NetworkManager, BlueZ,
  Polkit, and firewall on with only SSH open.
