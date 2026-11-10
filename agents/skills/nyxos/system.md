# The system: configuration, updates and getting back

Read this before changing anything that applies to the whole computer.

## Where the system comes from

```
/etc/nyxos/
├── flake/                  # root's: this computer's flake (flake.nix, flake.lock,
│                           #   host.nix, hardware-configuration.nix)
├── overrides/              # the System Manager's settings layer: system.json and the
│                           #   users' default DOMAIN.toml files. Never edit by hand
├── defaults/               # the distribution's defaults for user settings (generated)
├── system.toml             # flake = "/etc/nyxos/flake", host = "<attribute>"
├── built-from/             # the flake.lock and system.json the running generation used
└── secrets/                # root only: logins for mounts and the like. Never read out
```

- `flake/flake.nix` takes NyxOS as an input (`github:nyxos-project/nyxos/stable`, or
  `/testing`, the release channel) and builds `nixosConfigurations.<host>` through
  `nyxos.lib.mkSystem` from `hardware-configuration.nix` and `host.nix`.
- `host.nix` is what the installer wrote for this machine: user name, disks, encryption,
  swap and hibernation, snapshots. Hand edits go here, sparingly.
- `overrides/system.json` is the flake's `nyxos-overrides` input. Its values win over the
  distribution's and `host.nix`'s.
- The host attribute is `host` in `/etc/nyxos/system.toml` (often the host name).

## nyx-system: the System Manager

Every command below is built before it's switched to, with a Btrfs snapshot before and
after when snapshots are on. If the build fails nothing changes. Polkit asks for the
user's password in a graphical prompt.

```bash
nyx-system settings                          # the system layer as it is now
nyx-system set hostname|time-zone|locale|keyboard VALUE
nyx-system set theme|boot-theme|login-theme THEME   # e.g. nyx-dark, nyx-light
nyx-system unset NAME                        # back to the distribution's value

nyx-system services                          # what NyxOS manages: bluetooth, printing, ssh,
nyx-system service NAME on|off|default       #   flatpak, docker, podman, incus, libvirtd,
                                             #   tailscale, fwupd, avahi, ollama
nyx-system app NAME on|off|default           # a Nyx app for everyone (mail, media-player…)
nyx-system firewall on|off|default
nyx-system port open|close PORT tcp|udp
nyx-system power KEY ACTION|default          # HandleLidSwitch suspend, HandlePowerKey poweroff…

nyx-system person add NAME 'FULL NAME' [--admin] [--password-stdin]
nyx-system person remove NAME                # an account NyxOS made; its home stays
nyx-system person admin NAME on|off
nyx-system full-name USER 'FULL NAME'
nyx-system password USER                     # new password on stdin
nyx-system groups                            # groups NyxOS manages (docker, libvirtd…)
nyx-system group add|remove GROUP USER

nyx-system mount add ID JSON [--login-stdin] # a drive or share at startup
nyx-system mount remove ID
nyx-system hardware                          # graphics, processor, battery, Bluetooth, VM
nyx-system hardware apply                    # drivers, power and firmware for it
nyx-system nvidia-driver on|off              # NVIDIA's own driver (unfree) or nouveau

nyx-system update [WHAT...] [--dry-run]      # the same as `nyx update` (see Updates)
nyx-system generations
nyx-system rollback                          # back to the previous generation
nyx-system clean [DAYS]                      # ONLY when asked: drops old generations
nyx-system clean-logs [MB]

nyx-system apply JSON|-                      # several typed changes at once
```

`nyx system ...` and `nyx service NAME on|off` are the same commands.

Mount JSON: `{"what": "<filesystem UUID, //server/share or server:/path>", "dir":
"/mnt/data", "fsType": "ext4|btrfs|exfat|cifs|nfs|nfs4|…", "options": ["noatime"]}`. A share's
login goes on stdin with `--login-stdin`, as `username=`, `password=` and `domain=` lines;
it's kept apart from the configuration, root only. Find a drive's UUID with `lsblk -f`.

### Settings everyone starts from

User settings are TOML "domains" (`appearance`, `idle`, `bar`, `dock`, `control-center`…),
layered as in SKILL.md:

```bash
nyx-system config show appearance            # merged, with the layer each key came from
nyx-system config get idle lock
nyx-system config set idle lock 600          # the user's own (VALUE is TOML)
nyx-system config reset idle lock
nyx-system default set idle lock 600         # every user's default (system layer)
nyx-system default reset idle lock
```

## When nyx-system can't do it: host.nix

For a NixOS option nyx-system has no command for (a kernel parameter, a service NyxOS
doesn't manage, an extra udev rule), tell the user you're editing `host.nix`, then:

```bash
host=$(sed -n 's/^host = "\(.*\)"/\1/p' /etc/nyxos/system.toml)
sudo cp /etc/nyxos/flake/host.nix /etc/nyxos/flake/host.nix.bak.$(date +%s)
sudoedit /etc/nyxos/flake/host.nix           # or write it with sudo tee
sudo nixos-rebuild build  --flake path:/etc/nyxos/flake#$host \
  --override-input nyxos-overrides path:/etc/nyxos/overrides
sudo nixos-rebuild switch --flake path:/etc/nyxos/flake#$host \
  --override-input nyxos-overrides path:/etc/nyxos/overrides
```

- Always pass both the `path:` flake and the overrides input, exactly as above, or the
  build leaves out the System Manager's settings and the switch undoes them.
- `build` first; `switch` only when it succeeded.
- Look options up at search.nixos.org (channel 26.05) or with `man configuration.nix`.
- Keep `host.nix` a plain module: `{ config, lib, pkgs, ... }: { ... }`.
- `nyxos.*` options NyxOS adds: `nyxos.user`, `nyxos.snapshots.{enable,mounts}`,
  `nyxos.recovery.enable`, `nyxos.theme.{system,boot,login}`, `nyxos.signinStyle`
  (`circular`, `cyberpunk`, `minimal`, `edge`), `nyxos.idle.{lock,screenOff,suspend}`
  (seconds), `nyxos.hardware.*`, and `nyx.<app>.enable` for each Nyx app.

## Updates and release channels

One command updates everything, each piece through what owns it:

```bash
nyx update                   # everything: plans, asks once, then updates (firmware asked apart)
nyx update system            # the channel: NixOS, NyxOS, the Nyx apps built into the desktop
nyx update apps              # the user's own apps (their Nix profile) and Flatpaks
nyx update tools             # coding agents and the user's mise and uv tools
nyx update firmware          # fwupd; always asked, never undoable
nyx update claude            # one thing by name: codex, cursor-agent, grok, firefox, gimp...
nyx update … --dry-run       # the plan only; --yes doesn't ask; --json for scripts
nyx update check             # what has updates (offline: the last check's, and when)
nyx update status            # everything installed: version, what's newer, how, its setting
nyx update history           # what was updated, and how it went
```

- Names resolve the way `nyx install` resolves them. One that fits several things
  (`cursor`: Cursor Agent and the Cursor IDE) is asked about on a terminal and listed
  otherwise: use the id it shows. `system`, `apps`, `tools`, `firmware`, `check`,
  `status`, `history`, `report`, `auto` and `help` are never package names.
- Exit codes: 0 done or nothing to do, 1 failed, 2 usage, 3 partly updated, 4 unknown or
  ambiguous name, 5 offline, 6 another update running, 7 declined. With `--json` a failed
  step is in the outcome and the code stays 0.
- The user's own apps and tools update from the channel's head with `nix profile
  upgrade`: no password, no rebuild, `nyx rollback` undoes it. Programs still running
  keep their version until reopened (it says which).
- System steps (the channel, and tools still installed for everyone) are one System
  Manager rebuild: built first, then switched to, undone if either fails. They ask for
  the administrator's password. `/etc/nyxos/tools.json` shows the system's tools as built.
- The coding agents' own updaters are off: NyxOS updates them. Don't run `claude update`,
  `npm i -g`, or an install script over them, and don't install them with mise too.
- Project languages and tools come from mise (`mise use node@22` in the project) and
  Python tools from `uv tool install`; they're the user's, and `nyx update tools` runs
  `mise upgrade` and `uv tool upgrade --all` for them. nix-ld lets their downloads run.
- The channel is the `nyxos.url` line in `/etc/nyxos/flake/flake.nix`: `.../stable` or
  `.../testing`. Change it only when the user asks, then `nyx update system`.
- Update settings, per kind (`nyx-system config set updates KEY VALUE`, or Settings >
  Updates): `system`, `apps`, `tools` and `firmware-policy` are `off`, `check`, `notify` or
  `auto` (defaults: notify, auto, auto, notify; the system and firmware never install by
  themselves). `install-at = "03:00"` holds automatic installs until then; `check false`
  turns everything off; `check-on-metered true` allows metered connections.
- The daily run (`nyx-update-check` user timer, `nyx-system update auto`) installs what's
  set to auto and notifies about the rest, once per set of updates, and when something fails.

## Generations, rollback and recovery

- Every switch makes a generation; the boot menu (Limine) lists them.
- `nyx-system generations` lists them; `nyx-system rollback` goes back one.
- Without the System Manager: `sudo nixos-rebuild switch --rollback`, or pick an older entry
  in the boot menu.
- Each generation has a **NyxOS Recovery** entry beside it: a text console with no desktop
  and no network that runs `nyx-recovery` as root (generations, configuration repair,
  health checks, accounts, restoring from a backup). Point the user there when the desktop
  won't start.
- `/etc/nyxos/built-from/` holds the `flake.lock`, `system.json` and (after a single-tool
  update) `tools.json` the running generation was built from, so a broken settings layer
  can be put back.

## Snapshots and backup

- With `nyxos.snapshots.enable` (the installer turns it on for Btrfs), snapper takes hourly
  and daily snapshots of `/` and `/home`, and one before and after each System Manager
  change. List them with `snapper -c root list` / `snapper -c home list`; compare with
  `snapper -c home status N..M`; restore one file with `snapper -c home undochange N..M PATH`.
  Ask before any `undochange` or `rollback`.
- Nyx Backup backs up the user's files (restic underneath). Its settings are in the Backup
  app; recovery can restore from it.

## Hardware

- `nyx-system hardware` shows what NyxOS detected; `hardware apply` sets drivers, power and
  firmware for it. NVIDIA: `nyx-system nvidia-driver on` for the proprietary driver.
- Power profiles: `powerprofilesctl` (`get`, `set balanced|power-saver|performance`).
- Displays are configured per user in Settings > Displays (see `desktop.md`).
- Sound: `wpctl status`, `wpctl set-default ID`, `wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%`.
- Network: `nmcli` (Wi-Fi: `nmcli device wifi list`, `nmcli device wifi connect SSID --ask`).
- Bluetooth: `bluetoothctl`.
- Fingerprint, face and security-key sign-in: Settings > Sign-in.

## Security defaults

Firewall on (only what services open), sudo for administrators only, Nix trusting only
root, root-only `/boot`, SSH off unless turned on. Keep them unless the user asks.
