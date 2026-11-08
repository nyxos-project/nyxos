---
name: nyxos
description: >
  REQUIRED for any change to a NyxOS computer: its system configuration, software, desktop,
  Nyx apps or settings. Use when the user asks to install or remove software, change a system
  setting (host name, time zone, locale, keyboard, users, firewall, services, drivers, power,
  mounts), update, roll back or recover the system, or customize the desktop: Hyprland,
  keybindings, monitors, window rules, the bar, dock, Control Center, notifications, Glimpse,
  Switcher, lock screen, idle, themes, wallpaper, icons, fonts, default apps or the default
  coding agent. Also when editing anything in /etc/nyxos, ~/.config/nyx, ~/.config/nyx-*,
  ~/.config/hypr or ~/.config/foot, or running nyx, nyx-system, nyx-settings or nixos-rebuild.
  NyxOS is NixOS: never use apt, pacman, dnf or a curl | sh installer.
---

# NyxOS

NyxOS is a NixOS distribution built around the Nyx desktop and apps. The whole system is
declared in a Nix flake and built from it, so most of what other distributions do by
editing files in place is done here by changing configuration and rebuilding. Read the
topic guide for the area before you start:

- [`system.md`](system.md): the system's configuration, `nyx-system`, updates, generations,
  rollback, recovery, snapshots, users, hardware, firewall, services and mounts
- [`software.md`](software.md): installing and removing software (catalog, nixpkgs, Flathub,
  per-user Nix profiles), unfree licenses, dev shells
- [`desktop.md`](desktop.md): Hyprland, keybindings, monitors, window rules, and the Nyx shell
  (bar, plugins, dock, Control Center, notifications, Glimpse, Switcher, lock, idle)
- [`theming.md`](theming.md): Nyx themes, custom themes, wallpaper, icons, boot and login themes
- [`apps.md`](apps.md): the Nyx apps, their commands, IDs, settings and services; default apps
  and the default coding agent
- [`troubleshooting.md`](troubleshooting.md): logs, failed builds, crashes, getting back to a
  working system

## Critical safety rules

1. **The Nix store is read-only and generated.** Never edit anything under `/nix/store`,
   `/run/current-system` or `/etc/static`. Files there (and the symlinks into them, such as
   `~/.config/hypr/hyprland.lua` and `~/.config/foot/foot.ini`) are rebuilt and your edit
   would be lost or refused. Each guide names the file you may edit instead.
2. **Prefer `nyx-system` for system changes.** It makes typed changes to the settings
   layer, builds the result before switching to it, takes snapshots around it and undoes
   it if the switch fails. Edit `/etc/nyxos/flake/host.nix` only for what `nyx-system`
   can't express, and say so to the user first.
3. **Never run `nix-collect-garbage -d`, `nyx-system clean`, `nyx clean` or delete
   generations unless the user asked.** Old generations are how they get back.
4. **Don't change the release channel, the flake inputs or `system.stateVersion`** unless
   the user asked for exactly that.
5. **Ask before anything destructive**: removing accounts, wiping or partitioning disks,
   resetting settings, removing software the user didn't name.
6. Never print or copy secrets: `/etc/nyxos/secrets`, `~/.ssh`, password vaults, tokens.

## Privilege

- `nyx-system` talks to the Nyx System Manager, a root D-Bus service. It needs no `sudo`:
  polkit asks the user for their password in a graphical prompt (the Nyx Administrator
  Prompt), even when you have no terminal. Tell the user a password prompt is coming.
- `sudo` works only for administrators (the `wheel` group) and asks for the password in
  the terminal. Use it when there's a terminal the user can type in.
- `pkexec CMD` shows the same graphical prompt as `nyx-system`. Use it for a root command
  when there's no terminal for `sudo`.
- Nix accepts system-wide changes only from root; per-user installs (`nyx install`) need no
  privilege at all.

## How NyxOS is put together

| Part | What it is | Where it's configured |
| --- | --- | --- |
| NixOS 26.05 | The base system, built from a flake | `/etc/nyxos/flake` (root's), `/etc/nyxos/overrides` (System Manager) |
| Home Manager | Each user's generated dotfiles | Part of the NyxOS flake; don't edit its output |
| Hyprland (Lua config, via UWSM) | Compositor and window manager | `~/.config/hypr/user.lua` (yours), `settings.lua` (Settings) |
| Nyx shell | Bar, dock, Control Center, notifications, Glimpse, Switcher, lock screen | `~/.config/nyx/*.toml`, Nyx Settings |
| nyx-themed | Carries the Nyx theme to Hyprland, Foot, GTK, icons and the wallpaper | `~/.config/nyx/theme.toml`, `appearance.toml` |
| Nyx apps | Mail, Files, Notes, Settings, Store... (GTK 4, Rust) | `~/.config/nyx-<app>/` |
| Foot + Zsh | Terminal and shell | `~/.config/foot/`, `~/.config/zsh/` |
| PipeWire, NetworkManager, BlueZ | Sound, network, Bluetooth | Settings, `nmcli`, `bluetoothctl` |

### The three configuration layers

1. **Distribution defaults**: the NyxOS flake, and `/etc/nyxos/defaults/` for user settings.
   Updates replace this layer only.
2. **System overrides**: `/etc/nyxos/overrides/`. `system.json` holds what Settings, Welcome,
   the Store and `nyx-system` set for the whole computer (host name, locale, packages for
   everyone, services, Nyx apps, themes, firewall, power, accounts, mounts, hardware). The
   `DOMAIN.toml` files there are every user's defaults. Root-owned; change it through
   `nyx-system`, never by hand.
3. **User settings**: `~/.config/nyx/` and each app's `~/.config/nyx-<app>/`, written by the
   apps. Safe to edit; the apps follow most changes live.

Later layers win, key by key. `nyx-system config show DOMAIN` shows the merged result and
where each value came from.

## Command discovery

```bash
nyx help                 # the nyx command: per-user packages, system, services, agent, plugins
nyx-system --help        # system settings, packages for everyone, services, users, updates
nyx-settings --help      # Settings' command-line options; --section ID opens a page
nyx plugin help          # bar, Control Center and desktop plugins
nyx agent help           # the default coding agent and these skills
```

`nyx` passes anything it doesn't know to `nix` (`nyx build`, `nyx flake`, `nyx develop`).

## Decision framework

1. **Software?** Follow [`software.md`](software.md): the catalog (`nyx-system catalog`) for
   anything NyxOS offers, `nyx install` for one user, `nyx-system install` for everyone,
   `nyx shell` / `nyx run` for a one-off. Never `pip install --user`, `npm -g` into the
   system or a downloaded installer.
2. **A system setting?** `nyx-system set/service/app/firewall/port/power/person/...` (see
   [`system.md`](system.md)). Only if it has no command: `host.nix` and a rebuild.
3. **The desktop?** Settings (`nyx-settings --section ID`) or the files in
   [`desktop.md`](desktop.md): `~/.config/hypr/user.lua` for your own Hyprland lines,
   `~/.config/nyx/*.toml` for the shell.
4. **Looks?** [`theming.md`](theming.md): pick a theme, or write
   `~/.config/nyx/themes/<name>.toml`.
5. **A Nyx app's behaviour?** [`apps.md`](apps.md): its settings file or its page in Settings.
6. **Something broke?** [`troubleshooting.md`](troubleshooting.md) before changing anything.

After a change, check it took: `hyprctl configerrors` for Hyprland, `systemctl --user
status` for a service, the app itself for its settings, `nyx-system settings` for the system.

## Example requests

- "Install GIMP" -> `nyx-system catalog` to see if NyxOS offers it; if so `nyx-system
  catalog install gimp`, else `nyx install gimp` (just this user) or `nyx-system install
  gimp` (everyone)
- "Try ripgrep without installing it" -> `nyx shell ripgrep`
- "Change the computer's name to studio" -> `nyx-system set hostname studio`
- "Turn on SSH" -> `nyx-system service ssh on` (it opens port 22 too)
- "Open port 8080" -> `nyx-system port open 8080 tcp`
- "Update everything" -> `nyx update` (it plans, then asks); "update Claude" -> `nyx update claude`
- "Undo the last system change" -> `nyx-system rollback`
- "Switch to the light theme" -> set `theme = "nyx-light"` in `~/.config/nyx/theme.toml`, or
  Settings > Theme
- "Bind Super+E to Files" -> add `hl.bind(...)` to `~/.config/hypr/user.lua` (see
  `desktop.md`), then `hyprctl configerrors`
- "Make Claude my default agent" -> `nyx agent default claude`
- "Why did Mail crash?" -> `coredumpctl list nyx-mail`, then `troubleshooting.md`
