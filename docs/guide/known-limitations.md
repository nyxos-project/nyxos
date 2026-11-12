# Known limitations in NyxOS 0.1

What 0.1 doesn't do yet, or does with a caveat. Each item links to the issue it's
tracked as in the [release-readiness audit](../audit/release-readiness/issues.md).

## Hardware

- **Tested only in virtual machines.** No laptop or desktop has been through a full test
  yet ([requirements](requirements.md)). (NYX-HW-001)
- **Firmware updates are off** until you turn fwupd on (`nyx-system service fwupd on`).
- **The USB stick isn't signed for Secure Boot.** Turn Secure Boot off to start it.

## Desktop

- **Monitors plugged in after signing in** get no bar or dock until you sign in again.
  (NYX-REL-003)
- **If the shell crashes repeatedly**, the bar, dock and launcher stay gone until you
  restart them ([troubleshooting](troubleshooting.md#the-bar-dock-or-launcher-is-gone)).
  (NYX-SHELL-001)
- **Screen readers:** the accessibility bus is on and the apps label their controls, but
  the bar, dock, panels and sign-in screen haven't been made to work with a screen reader
  yet, and Orca isn't in the catalog. (NYX-SHELL-005, NYX-APP-GREETER-003)
- **Contrast:** the default theme's secondary text is lighter than accessibility
  guidelines recommend; Nyx Dark has more contrast. (NYX-A11Y-002)

## Apps

- **Online accounts:** Google and Microsoft accounts (Mail, Calendar, Contacts) need an
  OAuth client of your own for now (Settings › Accounts explains it). (NYX-APP-MAIL-001)
- **Passwords** has no browser autofill yet. (NYX-APP-PASSWORDS-001)
- **Office** keeps text, formatting, tables, pictures, comments and more, but not
  everything in Word, Excel and PowerPoint files; it says what it can't keep and asks
  before saving over the original. (NYX-APP-OFFICE-001)
- **Assistant:** some voice commands (night light, gaps, transparency and other desktop
  toggles) still expect Omarchy and answer that this system doesn't have them; once
  enabled, it listens for its wake word all the time. (NYX-APP-ASSISTANT-001,
  NYX-PRIV-002)
- **Lyra** plays YouTube Music through YouTube Music's own web player and can break when
  YouTube changes it. (NYX-APP-LYRA-001)
- **Containers** works with Incus and Docker, not Podman.

## Security and privacy

- **The local AI endpoint** (127.0.0.1:8080, for coding tools) answers any program on the
  computer without a key. (NYX-SEC-001)
- **Screen capture** isn't gated: any app can capture the screen without asking.
  (NYX-PRIV-001)
- **Nyx Connect** listens on port 12100 on every network, for pairing phones.
  (NYX-SEC-003)
- **The Recovery boot entry** gives a root console without a password; the disk's
  encryption is what protects the computer. (NYX-SEC-005)
- **Your account is in the `input` group**, which lets your programs read keyboard input
  directly. (NYX-SEC-004)
