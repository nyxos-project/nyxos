# NyxOS

NyxOS is a NixOS distribution built around the Nyx desktop and applications. This
repository holds the distribution flake: NixOS modules, Home Manager defaults and host
definitions. Nyx applications stay in their own repositories and are packaged by
[nyx-packages](https://github.com/nyxos-project/nyx-packages).

Status: phase 1, a development VM that boots NixOS 26.05 into a minimal Hyprland
session. See [docs/dev-vm.md](docs/dev-vm.md) to run it and
[docs/audit/repository-audit.md](docs/audit/repository-audit.md) for the state of the
Nyx repositories.

## Layout

| Path | Contents |
| --- | --- |
| `flake.nix` | Inputs (nixpkgs 26.05, Home Manager, Herdr, nyx-packages) and outputs |
| `hosts/incus-dev` | The Incus development VM |
| `modules/nixos` | System defaults: Nix, users, network, audio, desktop, shell, packages, base Nyx apps |
| `modules/home` | User defaults: Foot, Zsh and the Nyx prompt, Helix, Herdr, Hyprland |
| `themes` | Theme tokens (Nyx Dark), mirrored from nyx-design |
| `pkgs/nyx-cli` | The `nyx` command on NyxOS |
| `scripts/dev-vm` | Create, rebuild, snapshot and inspect the VM |

## Configuration layers

1. Distribution defaults: this flake.
2. System overrides: `/etc/nyxos/overrides/` (created, not read yet).
3. User settings: `~/.config/nyx/` (created, not read yet).

Later layers win. Updates replace only the first layer. The merge logic arrives with
the theme and settings services in phase 3.

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
given. `nyx icons …` and `nyx share …` run the Nyx tools as on Omarchy.

## Defaults

- Terminal: Foot. Shell: Zsh with autosuggestions, syntax highlighting, fzf, zoxide
  and a native prompt. Editor: Helix (`EDITOR=hx`, `VISUAL=hx`). Multiplexer: Herdr,
  installed but not started automatically. Bash remains for scripts and root.
- Desktop: Hyprland through UWSM, PipeWire and WirePlumber, NetworkManager, BlueZ,
  Polkit, and firewall on with only SSH open.
