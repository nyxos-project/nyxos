# Software

Read this before installing, removing or updating anything. NyxOS has no `apt`, `pacman`
or `dnf`, and programs don't install into `/usr`. Downloaded installers (`curl | sh`,
`.deb`, `.AppImage` run from anywhere, `sudo make install`) fight the system; don't use them.

## Pick the right way

Apps and tools are each person's own: they go into that person's Nix profile, with no
password and no rebuild, and other accounts have their own. Only what the system has to
provide (services, groups, drivers, the Nyx apps built into the desktop) is installed for
everyone.

| The user wants | Use | Who gets it | Rebuild? |
| --- | --- | --- | --- |
| Any app or tool (catalog name, command, alias or nixpkgs name) | `nyx install NAME` | this user, or everyone for system items | only for system items |
| A desktop app from Flathub | Nyx Store, or `flatpak install --user flathub APP` | this user | no |
| To try something once | `nyx run PKG` / `nyx shell PKG` | nobody keeps it | no |
| Tools for one project | a `flake.nix` dev shell, `nix develop`; or mise (`mise use node@22`) | that project | no |
| A Python command-line tool | `uv tool install NAME` (lands in `~/.local/bin`) | this user | no |
| A program for every account, deliberately | `nyx-system install PKG` | everyone | yes |
| A system service (Docker, SSH…) | `nyx-system service NAME on` (or its catalog item) | the system | yes |
| An app installed for everyone, as their own | `nyx-system catalog move NAME` | this user | yes (it leaves everyone's) |

`nyx install claude`, `nyx install claude-code` and `nyx install "Claude Code"` are the same:
names resolve through the catalog (ids, names, aliases, commands, packages), the same way
for install, remove, update and search. A name the catalog doesn't have is a nixpkgs
package from the system's channel. Find names with `nyx search TERM`.

## The NyxOS catalog

The curated list Welcome and the Store offer, with presets. An item can bring nixpkgs
packages, a Nyx app, a Flatpak, a flake for the user's profile, services and groups at once.
Each says who it's for: "for you" (the person's profile, from
`github:nyxos-project/nyxos/<channel>`) or "for everyone" (the System Manager, one
rebuild).

```bash
nyx-system catalog                    # every section; * marks what's installed
nyx-system catalog agents             # one section (nyx-apps, desktop, cli, toolchains,
                                      #   infrastructure, agents…)
nyx-system catalog presets
nyx-system catalog search TERM...
nyx-system catalog install NAME... [--preset P] [--yes]
nyx-system catalog remove NAME...
nyx-system catalog move NAME...|--all # per-user software installed for everyone (older
                                      #   NyxOS did that), into this user's profile
```

It prints the plan first (packages, Flatpaks, groups the user would join, licenses) and
asks. Show the user the plan and get their yes before passing `--yes`. Joining a group
such as `docker` or `libvirtd` amounts to root on the machine; say so.

The catalog's source is `catalog.toml` in nyx-system (`nyx-catalog` crate); NyxOS updates
bring new items.

## Per-user packages: `nyx`

```bash
nyx install NAME...           # through the catalog, else CHANNEL#NAME into the profile
                              #   (anything with # or : is a flake reference as given)
nyx remove NAME...            # wherever it's installed (catalog name, or as `nyx list` shows)
nyx update [NAME...]          # everything, or what's named (system, apps, tools, firmware,
                              #   claude, firefox...): see system.md, Updates
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

- mise (catalog item `mise`) is the other way, for people used to it or a project that
  ships a `mise.toml`/`.tool-versions`: `mise use node@22` in the project, `mise use -g`
  for the user's default. Its downloads run through nix-ld. `nyx update tools` keeps the
  user's global ones current; don't use it for the coding agents NyxOS packages.
- Python: `python3` is there; for packages use a dev shell with
  `python3.withPackages (p: [ p.requests ])`, or `uv` / a venv inside the project.
  `pip install` outside a venv fails on purpose. Python tools: `uv tool install`.
- Node: `npm -g` can't write to the system; use the dev shell, mise, `npx`, or `pnpm dlx`.
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
