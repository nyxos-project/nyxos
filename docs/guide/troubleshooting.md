# Troubleshooting

## NyxOS doesn't start after a change

Pick an earlier generation in the boot menu. If none works, use a generation's
**Recovery** entry (see [Updates and recovery](updates-and-recovery.md#nyxos-recovery)).

## The bar, dock or launcher is gone

They're drawn by one process, which systemd stops restarting if it crashes five times in
a minute. Open a terminal (Super+Return) and run:

```sh
systemctl --user reset-failed nyx-shell-qs
systemctl --user start nyx-shell-qs
```

Signing out and in again does the same.

## A new monitor has no bar or dock

Bars and docks appear on monitors that were connected when you signed in. Sign out and in
again after plugging one in.

## A setting or software change says it couldn't be built

Nothing changed: NyxOS undoes a change whose build fails. The message says why. If it
mentions a missing `/nix/store/…-source` path, update first (`nyx update system`) and try
again; if it mentions the network, connect and try again.

## Settings, the Store or `nyx install` show a network error

They need a connection for anything they download. `nyx update` says plainly when you're
offline; some other tools still show the raw error ("Could not resolve hostname").

## I can't sign in after installing

The password is typed in the keyboard layout chosen in the installer. If you chose a
layout other than the one on your keyboard's keys, try the password as that layout would
type it.

## Another computer or phone can't send files with Share

Share receives on port 53317 (TCP and UDP), which NyxOS opens while Share is on. Both
devices must be on the same network, and Share asks before receiving from a device it
doesn't know.

## My phone doesn't show up in Connected Devices

Nyx Connect (Flux) starts once a phone is paired, and phones can reach this computer
only on networks you trust. In Settings › Connected Devices, choose Start pairing if
it's offered, and turn on Trust for your home or work network. A café's or hotel's
network stays untrusted, so phones can't reach the computer there.

## Office warns that it can't keep part of a file

Some Word, Excel and PowerPoint content (text boxes, content controls, equations and so
on) can't be edited in Office yet. Saving over the original would remove it, so Office
asks first: choose **Save a copy** to keep the original as it is.

## Where the logs are

```sh
journalctl --user -b              # your session's services since this start
journalctl -b -p err              # the system's errors since this start
journalctl -b -1                  # the previous start
nyx update history                # updates and their results
```

When you report a problem (<https://github.com/nyxos-project/nyxos/issues>), include the
NyxOS version (Settings › About), what you did, and the relevant log lines.
