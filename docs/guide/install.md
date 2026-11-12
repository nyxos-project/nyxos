# Installing NyxOS

Check [Requirements](requirements.md) first, and back up anything on the computer you
want to keep: installing erases the disk you choose, or uses free space beside Windows.

## 1. Make the USB stick

Download `nyxos-0.1.0-installer.iso`, with `SHA256SUMS`, `SHA256SUMS.sig` and
[`release-signers`](../../release-signers) beside it, and check that it's the image NyxOS
signed (on Linux or macOS):

```sh
ssh-keygen -Y verify -f release-signers -I nyxos-release -n file -s SHA256SUMS.sig < SHA256SUMS
sha256sum -c SHA256SUMS    # macOS: shasum -a 256 -c SHA256SUMS
```

The first line must say `Good "file" signature for nyxos-release`, the second `OK`.

Then write it to a USB stick of 4 GB or more (it erases the stick):

- On Linux: `sudo dd if=nyxos-0.1.0-installer.iso of=/dev/sdX bs=4M status=progress conv=fsync`,
  with `/dev/sdX` the stick (check with `lsblk`; the wrong device loses its contents).
- On Windows or macOS: a tool such as Rufus (DD mode) or balenaEtcher.

## 2. Start from the stick

Turn Secure Boot off in the computer's firmware settings, then start from the USB stick
(usually a key such as F12, F11 or Esc at power-on opens the boot menu). The stick's menu
starts NyxOS's installer after three seconds.

## 3. Install

The installer asks four things, and changes nothing until you choose **Install**:

1. **Language, keyboard and time zone.** Choose the keyboard first: the installer starts
   again in that layout, so the password and disk passphrase you type later are typed the
   way you'll type them when NyxOS starts.
2. **Where to install.** A whole disk (everything on it is erased), or the free space
   beside an existing system such as Windows. To install beside Windows, shrink its
   partition in Windows' Disk Management first. NyxOS gets its own EFI partition and
   writes nothing to Windows'; the boot menu offers both. Encryption is on by default: you
   choose a passphrase, which NyxOS asks for at every start.
3. **You and this computer.** Your name, login and password (your account can change
   settings for everyone), and the computer's name.
4. **Review.** What will happen, in order. For a whole disk you confirm the erase.

Installing takes a few minutes and needs no network. When it's done, restart and take the
USB stick out.

If an install stops, the installer says which step failed and keeps a log in
`/tmp/nyxos-install.log` on the stick (open a console with Ctrl+Alt+F2 to read it).

## 4. The first start

1. Type the disk's passphrase when asked.
2. Sign in with your password.
3. **Welcome** opens: appearance, apps to install, accounts, default apps, updates. Every
   step but the last can be skipped, and Welcome is in the app launcher if you want it
   again.

A few keys to start with:

| Keys | Does |
| --- | --- |
| Super+Space | Glimpse: search apps, files and settings |
| Super+Return | A terminal |
| Super+F | Full screen |
| Super+Tab | The next workspace |

Settings has the rest, under Keyboard Shortcuts.
