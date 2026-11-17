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

Installing and using NyxOS: the [guide](docs/guide/README.md) (requirements, installing,
updates and recovery, troubleshooting, known limitations).

How it's built and what it trusts: [architecture](docs/architecture.md) and
[security model](docs/security.md).

Developing: [docs/dev-vm.md](docs/dev-vm.md) runs the development VM;
[docs/audit/release-readiness/](docs/audit/release-readiness/README.md) is the 0.1
release-readiness audit.

## Layout

| Path | Contents |
| --- | --- |
| `flake.nix` | Inputs (nixpkgs 26.05, Home Manager, nyx-packages, the machine's overrides) and outputs |
| `VERSION` | NyxOS's version |
| `iso` | The live USB: its own image, started by Limine on UEFI and BIOS (`live-image.nix`, `boot-menu.nix`) |
| `hosts/incus-dev` | The Incus development VM |
| `modules/nixos` | System defaults: Nix, users, network, audio, desktop, shell, packages, base Nyx apps |
| `modules/home` | User defaults: Foot, Zsh and the Nyx prompt, Helix, Herdr, Hyprland |
| `themes` | Theme tokens (the boot and login themes), mirrored from nyx-design |
| `pkgs/nyx-cli` | The `nyx` command on NyxOS |
| `pkgs/tools`, `pkgs/<tool>` | The coding agents and tools the catalog offers that nixpkgs lacks (Herdr among them), pinned in `pkgs/tools/sources.json`, added to `pkgs` by an overlay |
| `agents/skills` | Skills that teach coding agents NyxOS, shared by every agent ([docs/agent-skills.md](docs/agent-skills.md)) |
| `scripts/dev-vm` | Create, rebuild, snapshot and inspect the VM |

## Channels

- `main`: development; every change lands here first.
- `stable`: the last known-good state (`known-good/<n>` tags, signed). Its `flake.lock`
  pins nyx-packages to the commit that nyx-packages' own `stable` branch points at:
  `scripts/promote-stable` moves both branches together, only to commits with a
  successful CI run, and only forward. Follow it with `github:nyxos-project/nyxos/stable`.
  `stable` is always a commit of `main`, so its `flake.nix` names nyx-packages' `main`
  like `main`'s does; pins change on `main` and reach `stable` by promotion, never by a
  `nix flake update` on `stable`.

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

`nyx --help` lists every command. The main ones:

| Command | What it does |
| --- | --- |
| `nyx install NAME…` | Install software as Welcome and the Store do: names the NyxOS catalog has go through it (apps and tools for you; services and drivers for everyone, through the Nyx System Manager); other names are packages from the system's channel, for you |
| `nyx remove NAME…` | Remove it, wherever it's installed (also `uninstall`) |
| `nyx update [WHAT…]` | Update everything, or `system`, `apps`, `tools`, `firmware`, or one thing by name |
| `nyx list` | Your installed packages |
| `nyx search TERM…` | Search the NyxOS catalog, then nixpkgs |
| `nyx run PKG [ARGS…]` / `nyx shell PKG… [-c CMD]` | Run a program, or open a shell with packages, without installing |
| `nyx rollback` / `nyx history` | Undo the last install, remove or update / list them |
| `nyx clean` | Delete old versions to free disk space |
| `nyx system …` / `nyx service NAME on\|off` | System settings, packages for everyone, generations and rollback, and the services NyxOS manages, through the Nyx System Manager |
| `nyx apps`, `nyx APP [ACTION]` | What Nyx apps can do from the command line (`nyx notes create "Ideas"`) |
| `nyx agent` | Start your default coding agent (Settings › Default Apps); `nyx agent skills` links NyxOS's skills into every agent |
| `nyx icons`, `nyx share`, `nyx display virtual`, `nyx plugin` | Launcher icons, the Share Sheet, virtual monitors, bar plugins |
| `nyx completion SHELL` | Completions for bash, zsh or fish |

NAME is what the catalog calls it, a command or an alias (`claude`, `firefox`,
`notepad`), or any package name. Anything with `#` or `:` is a flake reference, used as
given. Any other command goes to an app that answers to it, else to `nix` (`nyx build`,
`nyx flake`, …).

## Defaults

- Terminal: Foot. Shell: Zsh with autosuggestions, syntax highlighting, fzf, zoxide
  and a native prompt. Editor: Helix (`EDITOR=hx`, `VISUAL=hx`). Multiplexer: Herdr,
  installed but not started automatically. Bash remains for scripts and root.
- Desktop: Hyprland through UWSM, PipeWire and WirePlumber, NetworkManager, BlueZ,
  Polkit, and firewall on with only SSH open.
