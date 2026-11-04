# NyxOS development VM

NyxOS is developed in an Incus virtual machine (QEMU/KVM, virtio-gpu with 3D
acceleration from the host's Intel iGPU, no GPU passthrough). The host doesn't need Nix: the VM boots the stock NixOS 26.05 Incus
image, receives a copy of this checkout, and builds and switches to the flake itself.

`scripts/dev-vm` wraps every command below; `scripts/dev-vm help` lists them.

## Host prerequisites (once)

- Incus with KVM, and your user in `incus-admin`.
- Omarchy enables ufw with forwarding denied, which blocks DHCP and NAT for
  `incusbr0`. Allow the bridge:

  ```sh
  sudo ufw allow in on incusbr0
  sudo ufw route allow in on incusbr0
  sudo ufw route allow out on incusbr0
  ```

  If a VPN client with its own firewall (NordVPN's kill switch, for example) is
  connected, it may need `incusbr0` or `10.24.219.0/24` allowlisted too.
- QEMU's GL display modules and virglrenderer, for 3D acceleration:

  ```sh
  sudo pacman -S --needed virglrenderer qemu-hw-display-virtio-gpu-gl \
    qemu-hw-display-virtio-vga-gl qemu-hw-display-virtio-gpu-pci-gl qemu-ui-egl-headless
  ```

## Create the VM

```sh
incus init images:nixos/26.05 nyxos-dev --vm \
  -c limits.cpu=6 -c limits.memory=8GiB -c security.secureboot=false \
  -d root,size=50GiB
incus config device add nyxos-dev gpu gpu gputype=native-context pci=0000:00:02.0
incus start nyxos-dev
```

Secure Boot is off because the image's systemd-boot isn't signed.

### 3D acceleration

The `native-context` GPU device shares the host's Intel iGPU (`0000:00:02.0`, Arc 140T
on `i915`) with the VM through virtio-gpu; nothing is passed through and the host keeps
using the GPU. Select the Intel GPU explicitly: without `pci=`, QEMU picks the default
render node, which on this laptop is the NVIDIA card. The device can't be hot-plugged,
so `scripts/dev-vm gpu on|off` stops and restarts the VM.

Inside the VM, Mesa's virgl driver uses it, so Hyprland and GL clients report
`virgl (Mesa Intel(R) Graphics (ARL))` with OpenGL 4.6 and OpenGL ES 3.2. Vulkan still
falls back to llvmpipe: native Vulkan (ANV) needs Mesa built with
`intel-virtio-experimental`, which nixpkgs doesn't enable.

Check from the host:

```sh
scripts/dev-vm exec dmesg | grep 'features:'   # expect +virgl +resource_blob +context_init
scripts/dev-vm exec bash -c 'grep Renderer: /run/user/1000/hypr/*/hyprland.log'
```

## Build and switch to NyxOS

```sh
scripts/dev-vm rebuild          # copy checkout to /etc/nyxos/flake, nixos-rebuild switch
```

Which is:

```sh
tar -C ~/Projects/nyxos --exclude=.git -cf - . |
  incus exec nyxos-dev -- /run/current-system/sw/bin/tar -C /etc/nyxos/flake -xf -
incus exec nyxos-dev --env PATH=/run/wrappers/bin:/run/current-system/sw/bin -- \
  nixos-rebuild switch --flake path:/etc/nyxos/flake#incus-dev
```

The `path:` flake reference builds the copied files as they are, without needing a
Git checkout inside the VM. The first switch builds Herdr from source (Rust and Zig),
which takes several minutes.

`incus exec` talks to the VM over the Incus agent, not the network, so it keeps
working even if a change breaks networking or SSH.

`scripts/dev-vm rebuild test` activates without adding a boot entry;
`scripts/dev-vm rebuild boot` makes the build the default for the next boot only.

## Working on nyx-packages

NyxOS takes the Nyx applications from the `nyx-packages` flake at the revision in
`flake.lock`. To build and test a local checkout (default `../nyx-packages`) in the VM:

```sh
scripts/dev-vm packages flake check -L      # build and test every package
scripts/dev-vm packages build -L .#nyx-fonts
```

To run NyxOS against that checkout instead of the pinned revision:

```sh
NYX_PACKAGES=~/Projects/nyx-packages scripts/dev-vm rebuild
```

With `NYX_PACKAGES` set, `flake.lock` isn't copied back, so the override never ends
up pinned. Add `NYX_SYSTEM=~/Projects/nyx-system` to also build nyx-packages against a
local nyx-system (the System Manager and the software catalog), and
`NYX_SOURCES="nyx-welcome=$HOME/Projects/nyx-welcome ..."` for any of its other sources.

## Log in

```sh
scripts/dev-vm ssh              # ssh ken@<VM IPv4>, key-only
scripts/dev-vm exec bash        # root shell through the Incus agent
```

The VM logs `ken` straight into Hyprland at boot (temporary, until Nyx Greeter).
After logging out, tuigreet takes over; the initial password is `nyx`.

To see the desktop:

- `scripts/dev-vm shot shot.png` takes a screenshot inside the VM with `grim` and
  copies it to the host. Nothing opens on the host.
- `incus console nyxos-dev --type=vga` opens an interactive SPICE window. It needs
  `virt-viewer` (`remote-viewer`) installed on the host.

## Rebuild, roll back, restore

```sh
scripts/dev-vm generations                 # nixos-rebuild list-generations
scripts/dev-vm rollback                    # nixos-rebuild switch --rollback --flake …
scripts/dev-vm snapshot known-good-1       # incus snapshot create nyxos-dev known-good-1
scripts/dev-vm restore known-good-1        # incus snapshot restore nyxos-dev known-good-1
```

Every older generation also stays in the systemd-boot menu (up to 20), reachable from
`incus console nyxos-dev --type=vga` during boot.

`scripts/dev-vm snapshot` flushes the guest's disks first: a snapshot of a running VM
is only crash-consistent, and unflushed store files come back empty.

A known-good state is a Git tag (`known-good/<n>`) on the commit that built it, plus an
Incus snapshot with the same number. Restoring the snapshot returns the whole VM disk;
checking out the tag and running `scripts/dev-vm rebuild` reproduces the system
from source.

## Checks

```sh
scripts/dev-vm check            # nix flake check (builds the full system closure)
```

## Remove

```sh
scripts/dev-vm destroy          # incus delete --force nyxos-dev
```
