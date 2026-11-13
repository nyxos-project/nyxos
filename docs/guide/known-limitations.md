# Known limitations in NyxOS 0.1

What 0.1 doesn't do yet, or does with a caveat. Each item links to the issue it's
tracked as in the [release-readiness audit](../audit/release-readiness/issues.md).

## Hardware

- **Tested only in virtual machines.** No laptop or desktop has been through a full test
  yet ([requirements](requirements.md)). (NYX-HW-001)
- **Firmware updates are off** until you turn fwupd on (`nyx-system service fwupd on`).
- **The USB stick isn't signed for Secure Boot.** Turn Secure Boot off to start it.

## Desktop

- **If the shell crashes repeatedly** (more than 10 times a minute), the bar, dock and
  launcher stop; a notification offers to start them again
  ([troubleshooting](troubleshooting.md#the-bar-dock-or-launcher-is-gone)). (NYX-SHELL-001)
- **Virtual monitors are experimental.** If a layout leaves you stuck,
  `nyx display virtual disable --all` in a terminal (Super+Return) gives every screen back
  whole. (NYX-HYPR-003)
- **Screen readers:** Orca comes with NyxOS (Super+Alt+S at the sign-in screen,
  Super+Ctrl+Alt+S in a session). The terminal in Nyx Agents reads its screen but doesn't
  announce new output as it arrives. (NYX-APP-AGENTS-002)
- **Screen capture rules take effect at sign-in:** after an update that changes them, the
  session asks about every capture until you sign out and in. (NYX-PRIV-001)

## Apps

- **Online accounts:** Google and Microsoft accounts (Mail, Calendar, Contacts) need an
  OAuth client of your own for now (Settings › Accounts explains it). (NYX-APP-MAIL-001)
- **Passwords** has no browser autofill yet. (NYX-APP-PASSWORDS-001)
- **Office** keeps text, formatting, tables, pictures, comments and more, but not
  everything in Word, Excel and PowerPoint files; it says what it can't keep and asks
  before saving over the original. (NYX-APP-OFFICE-001)
- **Assistant:** some voice commands (night light, gaps, transparency and other desktop
  toggles) still expect Omarchy and answer that this system doesn't have them.
  (NYX-APP-ASSISTANT-001)
- **Lyra** plays YouTube Music through YouTube Music's own web player and can break when
  YouTube changes it. (NYX-APP-LYRA-001)
- **Containers** works with Incus and Docker, not Podman.

## Security and privacy

- **Programs you run can act as you.** Screen capture is limited to the screen-sharing
  portal and Nyx's own tools, and Nyx services check which program calls them, but a
  program running as you can still start one of those tools, read your files, or change
  your Hyprland settings. Install software you trust. (NYX-PRIV-001, NYX-SEC-002)
- **Disk unlock** uses the encryption passphrase; unlocking with the TPM isn't there yet.
  (NYX-SEC-013)
- **The testing channel isn't signed.** `nyx update` checks the stable channel's
  release signature; testing installs whatever is on its branch. (NYX-SEC-008)
