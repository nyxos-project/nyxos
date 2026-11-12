# Requirements

## What NyxOS needs

| | Needs | Notes |
| --- | --- | --- |
| Processor | 64-bit x86 (Intel or AMD) | No ARM builds yet. |
| Firmware | UEFI | The USB stick also starts on older BIOS computers, but NyxOS itself installs only on UEFI. |
| Secure Boot | Off to start the USB stick | The stick isn't signed. Once installed, NyxOS can sign its own boot with your computer's keys (`nyxos.boot.secureBoot`); Windows keeps starting. |
| Disk | At least 32 GB for NyxOS, plus a swap file as large as your memory | The installer refuses smaller disks or free spaces. 64 GB or more is comfortable: every update keeps the previous system until it's cleaned up. |
| Memory | 8 GB recommended | NyxOS starts in about 1 GB at the sign-in screen; each Nyx app uses 130 to 240 MB. 4 GB works for light use. |
| Network | Not needed to install | The USB stick carries everything it installs. Updates, the Store and online accounts need a connection. |

## What has been tested

NyxOS 0.1 has been tested only in virtual machines (QEMU/KVM with virtio graphics). No
laptop or desktop has been through a full test yet, so there is no list of supported
hardware. The table says which parts of NyxOS know about which hardware; none of them
has been confirmed on a real machine.

| Hardware | Status |
| --- | --- |
| Intel and AMD graphics | Should work with the open drivers NyxOS ships (Mesa). Untested. |
| NVIDIA graphics | Settings and `nyx-system nvidia-driver on` switch to NVIDIA's driver (unfree). Untested. |
| Wi-Fi, Bluetooth, audio | NetworkManager, BlueZ, PipeWire. Untested on real hardware. |
| External monitors | Plugging one in while signed in currently gives it no bar or dock; signing out and in again does. |
| Fingerprint readers, face sign-in, security keys | Supported by Nyx Biometrics, set up in the system configuration. Untested on real hardware; the password always works. |
| Firmware updates | Off until you turn fwupd on (`nyx-system service fwupd on`). |
| Suspend and hibernate | Configured (the installer sets up a swap file for hibernating). Untested. |

If you try NyxOS on your computer, reports of what works and what doesn't help:
<https://github.com/nyxos-project/nyxos/issues>.
