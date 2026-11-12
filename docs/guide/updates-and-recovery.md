# Updates and recovery

## Updates

NyxOS follows a release channel, written into `/etc/nyxos/flake/flake.nix` when you
install: **stable** (the default) or **testing** (what's next, updated more often).

Settings › Updates shows what's installed, what's newer, and how each part updates. By
default:

| Part | Updates |
| --- | --- |
| The system (NyxOS and the Nyx apps built into it) | You're told; you install |
| Your own apps (from Welcome, the Store, Flatpak) | Installed automatically |
| Command-line tools (coding agents, mise and uv tools) | Installed automatically |
| Firmware | You're told; you install (once fwupd is on) |

From a terminal:

```sh
nyx update --dry-run       # what would change, without changing anything
nyx update                 # everything, after showing the plan and asking
nyx update system          # only NyxOS; or apps, tools, firmware, or one thing by name
nyx update history         # what was updated, newest first
```

A system update builds the new system first and switches to it only if the build works.
If the build or the switch fails, the change is undone and the computer stays as it was.

On the stable channel, an update installs only a release NyxOS signed (a `known-good`
tag checked against the keys in `/etc/nyxos/release-signers`); anything else on the
channel is refused, and so are your own apps from it. The testing channel isn't signed.

## Going back

Every system change (an update, the computer's name, time zone or keyboard, software installed for everyone)
makes a new **generation**. The previous ones stay until they're cleaned up.

- **From the desktop:** Settings › Updates, or `nyx system rollback` (back one
  generation). `nyx system generations` lists them.
- **When NyxOS doesn't start:** the boot menu lists every generation; pick an earlier one.
  Once it works, make it the default with `nyx system rollback`.

Old generations are removed after 30 days by the weekly cleanup, or now with
`nyx system clean` (keeps the last 14 days).

## Snapshots

On a Btrfs install (the installer's layout), NyxOS keeps snapshots of `/` and `/home`:
hourly, daily, and one before and after each system change. They're there to recover
files and settings, not a backup: they live on the same disk.

```sh
sudo snapper -c root list           # the system's snapshots
sudo snapper -c home list           # your home folder's
sudo snapper -c home diff 41..42    # what changed between two
sudo snapper -c home undochange 41..42 /home/you/Documents/report.odt
```

## NyxOS Recovery

Each generation in the boot menu has a **Recovery** entry. It starts a text console
instead of the desktop, without the network, and opens NyxOS Recovery: earlier
generations, repairing the configuration, a health check, accounts (resetting a
password), and restoring from a backup.

Recovery asks for an administrator's password first (an account that can change system
settings). If no administrator has a password, it opens without one.

### Forgot your password

Start from the NyxOS USB stick, press Ctrl+Alt+F2 for a console, and reset it there
(replace `you` with your login name):

```sh
sudo cryptsetup open /dev/disk/by-label/NyxOS cryptroot   # if the disk is encrypted
sudo mount -o subvol=@ /dev/disk/by-label/nyxos /mnt
sudo mount -o subvol=@nix /dev/disk/by-label/nyxos /mnt/nix
sudo nixos-enter --root /mnt -c 'passwd you'
sudo umount -R /mnt
```

Then restart without the stick.

## Backups

Nyx Backup (in the launcher) makes encrypted, incremental backups of the folders you
choose to a drive, a network share (SMB, NFS, SFTP) or cloud storage. Restore from its
Restore page: pick a snapshot, the files or folders, and restore them to a separate
folder or over the originals (the originals are kept so the restore can be undone).

Its backups are standard Restic repositories, so they can also be read without NyxOS:

```sh
restic --repo /path/to/repository snapshots
restic --repo /path/to/repository restore SNAPSHOT --target /new/empty/folder
```

Keep the recovery password Backup asks you to export somewhere other than the computer.
