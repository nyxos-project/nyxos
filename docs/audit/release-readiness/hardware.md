# Hardware compatibility (handoff 10 section 24)

**Tested hardware: none physical.** Every runtime result in this audit comes from two
QEMU/KVM virtual machines under Incus on one host (Intel Core Ultra 9 285H, Arc iGPU):

| Configuration | Machine | GPU path | What ran |
| --- | --- | --- | --- |
| Dev VM `nyxos-dev` | 6 vCPU, 16 GiB, ext4 disk, systemd-boot image | virtio-gpu native context on the Intel iGPU (Mesa vdrm); Vulkan for AI Core not usable ("0.0 GB GPU") | Desktop, all apps, shell failure tests, performance |
| Install VM `nyxos-install-test` | 4 vCPU, 6 GiB, 64 GiB disk, UEFI, Secure Boot off | virtio VGA, no acceleration | ISO boot, headless install (LUKS2 + Btrfs), first boot, greeter, first sign-in, Welcome |

The laptop itself runs Omarchy, not NyxOS, so nothing here says how NyxOS behaves on it.

## Matrix

"Tested" means exercised at runtime in this audit. "Configured" means NyxOS has code or
configuration for it (cited) but nothing ran on such hardware. Nothing is "supported" yet:
no hardware has passed a test plan.

| Category | Status | Basis |
| --- | --- | --- |
| Intel graphics (iGPU) | Configured, untested on metal (VM uses it through virtio native context) | `nyx-system hardware apply` detects GPUs (`nyx-system-proto/src/hardware.rs`) |
| AMD graphics | Configured, untested | same detection; Mesa from nixpkgs |
| NVIDIA graphics | Configured, untested | `nyx-system nvidia-driver on|off` (unfree driver or nouveau); AI Core `acceleration = "cuda"` uses a prebuilt worker CI never builds (NYX-PKG-004) |
| Hybrid / discrete+integrated | Untested, no specific handling found | |
| High-DPI displays | Untested | Hyprland scaling; Settings › Displays |
| Multiple monitors | Partly tested in VM: a hot-plugged headless output got wallpaper and Glimpse but **no bar or dock** (evidence/runtime-notes.md) | NYX-REL-003 |
| Ultrawide / virtual monitors | Untested at runtime | Hyprland patches 0003/0004 (hyprland-patches.md NYX-HYPR-003) |
| Audio | Untested (VM has no audio device in use) | PipeWire + WirePlumber |
| Bluetooth | Untested (VM has none: `nyx-system hardware` → `bluetooth no`) | BlueZ |
| Wi-Fi | Untested (VM uses virtio Ethernet) | NetworkManager |
| Touchpads | Untested | Hyprland input config |
| Fingerprint readers | Untested; in the VM the fingerprint gate fails and the password works | `nyx.biometrics.fingerprint` |
| Cameras / face sign-in | Untested; in the VM the face gate fails and the password works | irlume / gaze |
| Security keys | Untested | nyx-biometrics |
| External storage | Untested | udisks2, gvfs |
| Suspend / resume, hibernate | Untested (VM) | `nyxos.boot` resume offset written by the installer (installed host.nix) |
| Firmware updates | Not available by default: fwupd off (`nyx update` says "fwupd isn't installed") | NYX-UPD (infrastructure.md) |
| Secure Boot | Live USB unsigned (README); installed systems can enroll own keys; untested | `nyxos.boot.secureBoot` |
| Dual boot with Windows | Untested here; `install-vm fake-windows` exists for it | nyx-installer |

## What a first release needs

A minimum hardware test plan before any "supported" claim: one Intel and one AMD laptop
(install, boot, suspend/resume, Wi-Fi, Bluetooth, audio, brightness and volume keys,
touchpad, external monitor hotplug, fingerprint if present), one NVIDIA desktop (both
driver choices), and one HiDPI display. Record results per machine in this file.

## Finding

### NYX-HW-001: No physical hardware has been tested

- **Component:** release process
- **Category:** reliability
- **Severity:** P1
- **Status of feature:** not verified
- **Description:** All testing (this audit's and the project's) is in VMs; the laptop runs Omarchy. No install, boot, suspend, Wi-Fi, Bluetooth, audio, GPU or biometric result exists for NyxOS on metal.
- **Expected:** Gate B: "NyxOS installs and boots on the required tested configurations"; handoff 10 section 24: distinguish tested from theoretical support.
- **Actual:** this file's matrix.
- **Reproduce / verify:** n/a
- **Evidence:** this file
- **Affected versions:** all
- **User impact:** Unknown failure rate on real machines; no basis for a supported-hardware list.
- **Recommended correction:** Run the minimum hardware plan above and record results here before release.
- **Effort:** M
- **Dependencies:** NYX-INST-001
- **Verification criteria:** At least one Intel and one AMD laptop pass install, boot, suspend/resume, networking, audio and display tests.
