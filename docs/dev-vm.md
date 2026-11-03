# NyxOS development VM

NyxOS is developed in an Incus virtual machine (QEMU/KVM, virtio-gpu, no GPU
passthrough). The host doesn't need Nix: the VM boots the stock NixOS 26.05 Incus
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

## Create the VM

```sh
incus launch images:nixos/26.05 nyxos-dev --vm \
  -c limits.cpu=6 -c limits.memory=8GiB -c security.secureboot=false \
  -d root,size=50GiB
```

Secure Boot is off because the image's systemd-boot isn't signed.

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
scripts/dev-vm rollback                    # nixos-rebuild switch --rollback
scripts/dev-vm snapshot known-good-1       # incus snapshot create nyxos-dev known-good-1
scripts/dev-vm restore known-good-1        # incus snapshot restore nyxos-dev known-good-1
```

Every older generation also stays in the systemd-boot menu (up to 20), reachable from
`incus console nyxos-dev --type=vga` during boot.

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
