# Troubleshooting

Read this when something doesn't work, before changing anything. Find out what's wrong
first; most fixes on NyxOS are a setting, a rebuild, or going back a generation.

## Where to look

```bash
journalctl --user -b -p warning              # this session's user services and apps
journalctl --user -u nyx-bar -b              # one user service (nyx-themed, nyx-maild…)
systemctl --user --failed                    # user services that stopped
journalctl -b -p err                         # the system's errors since boot
systemctl --failed
journalctl -u nyx-system-manager -b          # System Manager: what it changed and why it failed
hyprctl configerrors                         # Hyprland's config
nyx-system settings; nyx-system generations  # the system layer and its history
```

A Nyx app run from a terminal prints its warnings there: `nyx-files` (close the open window
first, or it just hands over to it).

## A system change or update failed

The System Manager builds before it switches, so a failed build changed nothing. Read the
first `error:` line it printed (or `journalctl -u nyx-system-manager -b`):

- *"nixpkgs has no package X"*: a wrong attribute name; `nyx search X`.
- *"has an unfree license"*: the user hasn't accepted it; ask, then `--accept-unfree`.
- *Hash mismatch / download failed*: network or a moved upstream; retry later, or report it.
- *Evaluation error in host.nix*: the hand edit; restore the `.bak` copy (system.md).

If it switched and something now misbehaves: `nyx-system rollback` (ask first), then find
the cause.

## The desktop won't start or is broken

- Keybindings or windows gone after an edit: `hyprctl configerrors`, then fix or remove the
  last change to `~/.config/hypr/user.lua`. From a text console (Ctrl Alt F3) the file can be
  moved aside: `mv ~/.config/hypr/user.lua ~/.config/hypr/user.lua.off`.
- The bar, dock or a panel is missing: `systemctl --user status nyx-bar` (or `nyx-dock`,
  `nyx-control-center`), then `systemctl --user restart …`.
- Theme not applied: `systemctl --user restart nyx-themed`; check `~/.config/nyx/theme.toml`.
- Nothing works after an update: reboot into the previous generation from the boot menu,
  or choose **NyxOS Recovery** there. Tell the user how; don't guess at fixes blind.

## An app crashed

```bash
coredumpctl list                     # recent crashes, newest last
coredumpctl info nyx-mail            # signal, backtrace summary, the command line
journalctl --user -b | grep -i nyx-mail
```

Report what crashed, when, and the top of the backtrace. Don't delete app data to "fix" a
crash; move a suspect settings file aside instead (`mv settings.toml settings.toml.off`)
and ask.

## Disk full

```bash
df -h / /home /nix
du -sh ~/.cache/* | sort -h | tail
nix path-info -Sh /run/current-system      # size of the running system
nyx-system generations
```

Suggest, and run only once the user agrees: emptying the trash, `~/.cache`, old user
profile generations (`nix profile wipe-history --older-than 30d`), then
`nyx-system clean 14` for old system generations (they can't be rolled back to after).

## Network, sound, Bluetooth

- Network: `nmcli general status`, `nmcli device`, `journalctl -u NetworkManager -b`.
- Sound: `wpctl status`; restart with `systemctl --user restart pipewire wireplumber`.
- Bluetooth: `nyx-system service bluetooth on`, then `bluetoothctl`.

## Getting help upstream

NyxOS is developed at github.com/nyxos-project (the distribution in `nyxos`, the System
Manager in `nyx-system`, packages in `nyx-packages`); the Nyx apps at
github.com/design-nexus. Gather the command, its output, `nyx-system generations | tail -3`
and the logs above before suggesting a report, and let the user file it.
