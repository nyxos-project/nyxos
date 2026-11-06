# Software

Read this before installing, removing or updating anything. NyxOS has no `apt`, `pacman`
or `dnf`, and programs don't install into `/usr`. Downloaded installers (`curl | sh`,
`.deb`, `.AppImage` run from anywhere, `sudo make install`) fight the system; don't use them.

## Pick the right way

| The user wants | Use | Who gets it | Rebuild? |
| --- | --- | --- | --- |
| Something NyxOS offers (Welcome and Store items) | `nyx-system catalog install ID` | as the item says | if it has system parts |
| A program for themselves only | `nyx install PKG` | this user | no |
| A program for every account | `nyx-system install PKG` | everyone | yes |
| A desktop app from Flathub | Nyx Store, or `flatpak install --user flathub APP` | this user | no |
| To try something once | `nyx run PKG` / `nyx shell PKG` | nobody keeps it | no |
| Tools for one project | a `flake.nix` dev shell, `nix develop` | that project | no |
| A Nyx app | `nyx-system app NAME on` (or its catalog item) | everyone | yes |
| A system service (Docker, SSH…) | `nyx-system service NAME on` | the system | yes |

Package names are nixpkgs attribute names (`firefox`, `gimp`, `python3`, `nodejs_22`).
Find them with `nyx search TERM`, or at search.nixos.org (channel 26.05).

## The NyxOS catalog

The curated list Welcome and the Store offer, with presets. An item can bring nixpkgs
packages, a Nyx app, a Flatpak, a flake for the user's profile, services and groups at once.

```bash
nyx-system catalog                    # every section; * marks what's installed
nyx-system catalog agents             # one section (nyx-apps, desktop, cli, toolchains,
                                      #   infrastructure, agents…)
nyx-system catalog presets
nyx-system catalog install ID... [--preset P] [--yes]
nyx-system catalog remove ID...
```

It prints the plan first (packages, Flatpaks, groups the user would join, licenses) and
asks. Show the user the plan and get their yes before passing `--yes`. Joining a group
such as `docker` or `libvirtd` amounts to root on the machine; say so.

The catalog's source is `catalog.toml` in nyx-system (`nyx-catalog` crate); NyxOS updates
bring new items.

## Per-user packages: `nyx`

```bash
nyx install PKG...            # nix profile add nixpkgs#PKG (nyx-NAME: the Nyx app's flake;
                              #   anything with # or : is a flake reference as given)
nyx remove NAME...            # names as `nyx list` shows them
nyx update [NAME...]          # all, or the ones named
nyx list
nyx history / nyx rollback    # undo the last install, removal or update
nyx search TERM...
nyx run PKG [-- ARGS...]      # run without installing
nyx shell PKG... [-c CMD]     # a shell with the packages on PATH
```

No password needed; the packages land in `~/.nix-profile/bin`, which is on `PATH`.

## Packages for everyone

```bash
nyx-system install PKG...                   # added to the settings layer, then rebuilt
nyx-system install --accept-unfree PKG...   # for unfree ones, after the user accepted
nyx-system remove PKG...
nyx-system settings                         # lists what was added this way
```

Unfree packages (Chrome, Steam, Discord, VS Code, Claude Code, Cursor, NVIDIA's driver…)
build only once their license is accepted. Tell the user the package is unfree and ask
before `--accept-unfree`.

## Flatpak

Turn Flatpak on once with `nyx-system service flatpak on`. Nyx Store adds Flathub for the
user and installs per user (`flatpak --user`). From a terminal:

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.gimp.GIMP
flatpak update --user
```

Prefer nixpkgs when the same app is there, unless the user wants the Flatpak.

## Languages and project tools

Don't install compilers and language tools globally to build one project. Give the
project a dev shell:

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux; in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [ nodejs_22 pnpm python3 ];
      };
    };
}
```

Then `nix develop` (or direnv with `use flake`). In a Git repository, `git add flake.nix`
first: flakes only see tracked files.

- Python: `python3` is there; for packages use a dev shell with
  `python3.withPackages (p: [ p.requests ])`, or `uv` / a venv inside the project.
  `pip install` outside a venv fails on purpose.
- Node: `npm -g` can't write to the system; use the dev shell, `npx`, or `pnpm dlx`.
- Rust: `rustup` from nixpkgs (`nyx install rustup`) works as usual in `~/.rustup`.
- Prebuilt Linux binaries that expect `/lib64/ld-linux-x86-64.so.2` fail on NixOS. Prefer
  the nixpkgs package; else `nyx shell steam-run -c steam-run ./binary`, or ask whether to
  turn on `programs.nix-ld.enable = true;` in `host.nix`.

## Services that come with software

Docker, Podman, Incus, libvirt, Ollama, Tailscale, SSH, printing, Bluetooth, fwupd and
Avahi are switched with `nyx-system service NAME on|off|default`. Using Docker or libvirt
without sudo also needs the group: `nyx-system group add docker USER` (ask first; the user
must sign out and in again).

## Removing

Remove the way it came: `nyx-system catalog remove ID`, `nyx remove NAME`,
`nyx-system remove PKG`, `flatpak uninstall --user APP`. Removed packages stay in the store
until old generations are cleaned, so rollback still works.
