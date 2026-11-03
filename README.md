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

The same commands as the Omarchy CLI. `nyx icons …` and `nyx share …` run the
packaged tools; `nyx list` shows which Nyx apps are installed or available. Apps
belong to the system configuration, so `nyx install`, `uninstall` and `update`
print the configuration change and the rebuild command instead of installing
anything themselves.

## Defaults

- Terminal: Foot. Shell: Zsh with autosuggestions, syntax highlighting, fzf, zoxide
  and a native prompt. Editor: Helix (`EDITOR=hx`, `VISUAL=hx`). Multiplexer: Herdr,
  installed but not started automatically. Bash remains for scripts and root.
- Desktop: Hyprland through UWSM, PipeWire and WirePlumber, NetworkManager, BlueZ,
  Polkit, and firewall on with only SSH open.
