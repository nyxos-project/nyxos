# Repository inventory

Collected 2026-11-12 from the checkouts in `~/Projects` after `git fetch` of every
origin. Script: [evidence/scripts/inventory.py](evidence/scripts/inventory.py) (raw data:
[evidence/inventory.json](evidence/inventory.json)); table: `inventory-table.py`.

"Pin vs origin" compares the revision nyx-packages' `flake.lock` builds with the
repository's `origin` default branch. nyxos pins nyx-packages `d69e87e`, which is
nyx-packages' `origin/main`; the dev VM's `/etc/nyxos/flake` pins the same revision
(system generation 244). "Omarchy refs" counts lines mentioning `omarchy` in Rust, QML,
shell, Nix and Python sources: a rough measure of leftover Omarchy coupling, not a
defect count. "Rust tests" counts `#[test]`/`#[tokio::test]` attributes.

## Every repository

| Repository | Origin | HEAD (date) | Languages | Rust tests | CI workflows | Pin vs origin | Omarchy refs | Dirty |
| --- | --- | --- | --- | ---: | ---: | --- | ---: | ---: |
| `Hyprland` | hyprwm/Hyprland | `4e6b10e` (2026-11-10) | C++ | 0 | 14 | not pinned | 0 | 1 |
| `flux` | bjarneo/flux | `513bb88` (2026-10-24) | QML 5k, Go | 0 | 3 | 18 behind | 40 | 0 |
| `nyx` | design-nexus/nyx | `fce696c` (2026-11-11) | data | 0 | 2 | current | 27 | 0 |
| `nyx-accounts` | design-nexus/nyx-accounts | `e0df68a` (2026-11-03) | Rust 3k | 23 | 0 | None behind | 5 | 0 |
| `nyx-activity` | design-nexus/nyx-activity | `a1e46d2` (2026-11-11) | Rust 13k | 52 | 2 | current | 26 | 0 |
| `nyx-agents` | design-nexus/nyx-agents | `e2ad8b0` (2026-11-11) | Rust 22k, QML <1k | 90 | 0 | current | 4 | 0 |
| `nyx-ai` | design-nexus/nyx-ai | `d325462` (2026-11-10) | Rust 9k | 62 | 0 | current | 0 | 0 |
| `nyx-archive` | design-nexus/nyx-archive | `3e6072d` (2026-11-11) | Rust 4k | 20 | 2 | current | 11 | 0 |
| `nyx-assistant` | design-nexus/nyx-assistant | `58ed80e` (2026-11-11) | Rust 38k, QML 1k | 230 | 2 | current | 196 | 2 |
| `nyx-backup` | design-nexus/nyx-backup | `7ac27ae` (2026-11-11) | Rust 14k | 38 | 0 | current | 6 | 0 |
| `nyx-bar` | design-nexus/nyx-bar | `4a84c75` (2026-11-11) | Rust 10k, QML <1k | 32 | 1 | current | 14 | 1 |
| `nyx-biometrics` | design-nexus/nyx-biometrics | `1fe62af` (2026-11-11) | Rust 8k, QML 4k | 114 | 1 | current | 96 | 0 |
| `nyx-browser` | design-nexus/nyx-browser | `24e1817` (2026-11-08) | Rust 1k | 31 | 0 | not pinned | 0 | 0 |
| `nyx-calculator` | design-nexus/nyx-calculator | `9912a37` (2026-11-11) | Rust 8k | 43 | 1 | current | 0 | 0 |
| `nyx-calendar` | design-nexus/nyx-calendar | `54113d6` (2026-11-11) | Rust 9k | 36 | 2 | current | 11 | 0 |
| `nyx-capture` | design-nexus/nyx-capture | `06b4d57` (2026-11-11) | Rust 16k | 117 | 2 | current | 12 | 1 |
| `nyx-chat` | design-nexus/nyx-chat | `38a8bae` (2026-11-11) | Rust 18k | 78 | 2 | current | 11 | 0 |
| `nyx-clipboard` | design-nexus/nyx-clipboard | `0389ee0` (2026-11-11) | Rust 8k | 42 | 0 | current | 17 | 0 |
| `nyx-cloud` | design-nexus/nyx-cloud | `ba6385f` (2026-11-01) | Rust 1k | 2 | 2 | current | 0 | 0 |
| `nyx-contacts` | design-nexus/nyx-contacts | `f6af150` (2026-11-11) | Rust 4k | 12 | 2 | current | 11 | 0 |
| `nyx-containers` | design-nexus/nyx-containers | `bd04944` (2026-11-11) | Rust 14k | 43 | 2 | current | 1 | 0 |
| `nyx-control-center` | design-nexus/nyx-control-center | `7335302` (2026-11-11) | Rust 13k, QML 10k | 50 | 0 | current | 118 | 0 |
| `nyx-core` | design-nexus/nyx-core | `9187295` (2026-11-11) | Rust 53k | 308 | 2 | current | 45 | 0 |
| `nyx-design` | design-nexus/nyx-design | `e311c2f` (2026-11-11) | Rust 14k, QML 3k | 68 | 2 | current | 103 | 2 |
| `nyx-desktop-widgets` | nyxos-project/nyx-desktop-widgets | `8b8bf32` (2026-11-11) | Rust 5k, QML <1k | 16 | 1 | current | 0 | 0 |
| `nyx-dock` | design-nexus/nyx-dock | `0cd8173` (2026-11-11) | Rust 9k, QML 7k | 48 | 0 | current | 31 | 0 |
| `nyx-files` | design-nexus/nyx-files | `4a2d8bf` (2026-11-11) | Rust 275k | 2594 | 2 | current | 28 | 24 |
| `nyx-fonts` | design-nexus/nyx-fonts | `1571ea3` (2026-11-11) | Rust 4k | 11 | 2 | current | 11 | 0 |
| `nyx-git` | design-nexus/nyx-git | `84deb08` (2026-11-11) | Rust 24k | 63 | 2 | current | 13 | 0 |
| `nyx-glimpse` | design-nexus/nyx-glimpse | `deecabf` (2026-11-11) | Rust 15k, QML 5k | 78 | 2 | current | 62 | 0 |
| `nyx-greeter` | nyxos-project/nyx-greeter | `6c4cce1` (2026-11-11) | Rust 4k | 18 | 1 | current | 0 | 0 |
| `nyx-home` | design-nexus/nyx-home | `f70d1e6` (2026-11-11) | Rust 20k | 56 | 1 | current | 0 | 0 |
| `nyx-hyprland` | nyxos-project/nyx-hyprland | `71afdcb` (2026-11-11) | data | 0 | 0 | current | 0 | 0 |
| `nyx-installer` | nyxos-project/nyx-installer | `1ea97f2` (2026-11-11) | Rust 2k | 13 | 0 | current | 0 | 0 |
| `nyx-lyra` | design-nexus/nyx-lyra | `c786ddc` (2026-11-11) | Rust 10k | 31 | 0 | current | 11 | 0 |
| `nyx-mail` | design-nexus/nyx-mail | `5235153` (2026-11-11) | Rust 13k | 62 | 2 | current | 11 | 0 |
| `nyx-maps` | design-nexus/nyx-maps | `ef6fe24` (2026-11-11) | Rust 5k | 12 | 1 | current | 0 | 0 |
| `nyx-media-player` | design-nexus/nyx-media-player | `af518c0` (2026-11-11) | Rust 13k | 42 | 2 | current | 11 | 0 |
| `nyx-music` | design-nexus/nyx-music | `c1d13d2` (2026-11-11) | Rust 14k | 57 | 2 | current | 11 | 0 |
| `nyx-news` | design-nexus/nyx-news | `f7604d2` (2026-11-11) | Rust 8k | 41 | 2 | current | 11 | 0 |
| `nyx-notepad` | design-nexus/nyx-notepad | `a5c720a` (2026-11-11) | Rust 2k | 9 | 2 | current | 11 | 0 |
| `nyx-notes` | design-nexus/nyx-notes | `7f96c37` (2026-11-11) | Rust 20k | 34 | 2 | current | 0 | 0 |
| `nyx-notification-center` | design-nexus/nyx-notification-center | `b0801d6` (2026-11-11) | Rust 6k, QML 6k | 39 | 0 | current | 118 | 0 |
| `nyx-office` | design-nexus/nyx-office | `98becf4` (2026-11-11) | Rust 43k | 129 | 2 | current | 11 | 0 |
| `nyx-packages` | nyxos-project/nyx-packages | `d69e87e` (2026-11-11) | Nix | 0 | 1 | not pinned | 2 | 0 |
| `nyx-passwords` | design-nexus/nyx-passwords | `7a090fa` (2026-11-11) | Rust 29k | 144 | 2 | current | 13 | 0 |
| `nyx-pdf` | design-nexus/nyx-pdf | `7784708` (2026-11-11) | Rust 10k | 28 | 2 | current | 11 | 0 |
| `nyx-photos` | design-nexus/nyx-photos | `5a254f1` (2026-11-11) | Rust 11k | 60 | 2 | current | 12 | 0 |
| `nyx-plugin-index` | nyxos-project/nyx-plugin-index | `de61198` (2026-11-03) | data | 0 | 1 | not pinned | 0 | 0 |
| `nyx-plymouth` | nyxos-project/nyx-plymouth | `2c5a182` (2026-11-11) | Nix | 0 | 0 | current | 0 | 0 |
| `nyx-pulse` | design-nexus/nyx-pulse | `799f1b7` (2026-11-11) | Rust 31k | 42 | 2 | current | 11 | 0 |
| `nyx-reminders` | design-nexus/nyx-reminders | `6907cd6` (2026-11-11) | Rust 4k | 16 | 2 | current | 11 | 0 |
| `nyx-settings` | design-nexus/nyx-settings | `7e76622` (2026-11-11) | Rust 54k, QML <1k | 288 | 2 | current | 410 | 0 |
| `nyx-share` | design-nexus/nyx-share | `148dc74` (2026-11-11) | Rust 15k | 75 | 0 | current | 0 | 0 |
| `nyx-shell` | nyxos-project/nyx-shell | `975092e` (2026-11-11) | Rust 8k, QML 2k | 107 | 0 | current | 35 | 0 |
| `nyx-store` | design-nexus/nyx-store | `fc2bdca` (2026-11-11) | Rust 6k | 18 | 2 | current | 22 | 0 |
| `nyx-switcher` | design-nexus/nyx-switcher | `5ed009a` (2026-11-11) | Rust 4k, QML 5k | 25 | 0 | current | 9 | 0 |
| `nyx-system` | nyxos-project/nyx-system | `6f0c47c` (2026-11-11) | Rust 11k | 87 | 0 | current | 1 | 0 |
| `nyx-theater` | design-nexus/nyx-theater | `e5377d0` (2026-11-11) | Rust 16k | 55 | 2 | current | 11 | 0 |
| `nyx-themes` | design-nexus/nyx-themes | `fcbbfe3` (2026-11-05) | data | 0 | 0 | not pinned | 1 | 0 |
| `nyx-torrents` | design-nexus/nyx-torrents | `ab13d7b` (2026-11-11) | Rust 9k | 17 | 2 | current | 12 | 0 |
| `nyx-transfer` | design-nexus/nyx-transfer | `8f55e6a` (2026-11-11) | Rust 6k | 9 | 1 | current | 0 | 0 |
| `nyx-voice` | design-nexus/nyx-voice | `1ebd749` (2026-11-08) | Rust 4k | 22 | 0 | current | 0 | 0 |
| `nyx-wallpapers` | nyxos-project/nyx-wallpapers | `a2adbbc` (2026-11-11) | data | 0 | 0 | current | 0 | 0 |
| `nyx-weather` | design-nexus/nyx-weather | `1bdbad5` (2026-11-11) | Rust 11k, QML <1k | 29 | 2 | current | 12 | 0 |
| `nyx-welcome` | nyxos-project/nyx-welcome | `1094052` (2026-11-10) | Rust 1k | 3 | 0 | current | 0 | 0 |
| `nyxos` | nyxos-project/nyxos | `97f1573` (2026-11-11) | Nix | 0 | 2 | not pinned | 2 | 1 |
| `umbra-icons` | design-nexus/umbra-icons | `0deb6bb` (2026-11-03) | data | 0 | 0 | current | 7 | 0 |

Not in the table (worktrees of the repositories above, on side branches, not built by
nyx-packages):

| Checkout | Worktree of | Branch | HEAD | Status |
| --- | --- | --- | --- | --- |
| `nyx-assistant-auth` | nyx-assistant | `secrets-through-broker` | `df7faec` (2026-11-02) | Unmerged experiment |
| `nyx-glimpse-protected` | nyx-glimpse | `protected-items` | `66e4248` (2026-11-02) | Unmerged experiment |
| `nyx-passwords-face` | nyx-passwords | `face-unlock` | `af781af` (2026-11-02) | Unmerged experiment |
| `nyx-packages-h05`, `nyxos-h05` | nyx-packages, nyxos | `handoff-05` | `1744cec`, `2e867e3` (2026-11-09) | Handoff 05 staging, superseded by `main` |
| `hyprland-fs-0.56.2`, `hyprland-fs-0.57.2` | Hyprland | `nyx/0.5x.2-fullscreen-spaces` | `169c25d`, `0a31fa6` (2026-11-11) | Patch development; the shipped series is `nyx-hyprland` |
| `nyx-integration-audit` | (no git) | | | Integration audit of 2026-10-30 |

## Repository roles

| Role | Repositories |
| --- | --- |
| Distribution | `nyxos` (flake, modules, ISO, `nyx` CLI), `nyx-packages` (every Nyx package and the NixOS module), `nyx-installer`, `nyx-welcome`, `nyx-plymouth`, `nyx-greeter`, `nyx-wallpapers` |
| Compositor | `Hyprland` (fork, branch `nyx/0.57.2`, development), `nyx-hyprland` (the patch series nyx-packages applies to upstream v0.57.2) |
| Shell | `nyx-shell` (Shell Core daemon, `nyx-shell-qs`: OSD, Control Center panel, widgets, window menu), `nyx-bar`, `nyx-dock`, `nyx-control-center`, `nyx-notification-center`, `nyx-switcher`, `nyx-desktop-widgets`, `nyx-glimpse` |
| Shared libraries | `nyx-core` (19 crates: identity, paths, preferences, actions, capabilities, devices, Connect, plugins, PIM, peer identification), `nyx-design` (theme core, GTK widgets, plugin views, icons, playback), `nyx-accounts`, `nyx-cloud`, `nyx-fonts` (also an app) |
| Shared services | `nyx-system` (System Manager, `nyx-themed`, recovery, catalog, updates), `nyx-ai` (AI Core, `nyx-aid`), `nyx-voice`, `nyx-biometrics` (face, fingerprint, key; locker; polkit prompt), `nyx-accounts` (`nyx-accountsd`), `flux` (upstream fluxd for Nyx Connect) |
| Apps | `nyx-activity`, `nyx-agents`, `nyx-archive`, `nyx-assistant`, `nyx-backup`, `nyx-calculator`, `nyx-calendar`, `nyx-capture`, `nyx-chat`, `nyx-clipboard`, `nyx-contacts`, `nyx-containers`, `nyx-files`, `nyx-fonts`, `nyx-git`, `nyx-home`, `nyx-lyra`, `nyx-mail`, `nyx-maps`, `nyx-media-player`, `nyx-music`, `nyx-news`, `nyx-notepad`, `nyx-notes`, `nyx-office`, `nyx-passwords`, `nyx-pdf`, `nyx-photos`, `nyx-pulse`, `nyx-reminders`, `nyx-settings`, `nyx-share`, `nyx-store`, `nyx-theater`, `nyx-torrents`, `nyx-transfer`, `nyx-weather` |
| Suite, Omarchy era | `nyx` (suite installer for Omarchy; on NyxOS it supplies the icon tools), `nyx-themes` (no README, not packaged; themes now live in `nyx-design`), `nyx-plugin-index` (data for `nyx plugin search`) |
| Not packaged | `nyx-browser` (1.2k lines, a WebKit browser prototype), `nyx-themes`, `nyx-plugin-index` |

## Observations

- **Pins are current.** Every app nyx-packages builds is pinned at its `origin/main`.
  The exception is `flux`, deliberately held at the `v0.19.1` tag (18 commits behind
  upstream `master`) until the mobile app is checked. The VM runs these pins.
- **Shared crates drift.** Apps pin `nyx-core` at 10 distinct revisions and
  `nyx-design` at 7 ([evidence/shared-crate-pins.txt](evidence/shared-crate-pins.txt)).
  The shell components (dock, Control Center, Notification Center, switcher, widgets,
  greeter) are on `nyx-design 553f655`; most apps on `cf39397`; Settings on `997a2c1`;
  the bar on `0117f5f`. `nyx-accounts` is used at `afdc148` everywhere, behind its
  `main` (`e0df68a`). Each app builds its own copy of the theme and widget code, so a
  fix in nyx-design reaches only the apps re-pinned to it (see NYX-PKG-002).
- **Uncommitted work** sits in five checkouts (24 files in nyx-files, mostly locale
  strings; two in nyx-assistant; untracked mockups in nyx-design and nyx-capture;
  `.cargo/` in nyx-bar). It isn't on GitHub, so it isn't in NyxOS. Other sessions own it;
  the audit didn't touch it.
- **Tests are uneven.** nyx-files has 2,594 Rust tests, nyx-core 308, nyx-settings 288,
  nyx-assistant 230. nyx-welcome has 3, nyx-cloud 2, nyx-notepad and nyx-transfer 9,
  nyx-installer 13, and the QML in the shell repositories (about 49k lines) has no
  automated tests found.
- **CI is missing for core NyxOS repositories.** No workflows in `nyx-shell`,
  `nyx-system`, `nyx-ai`, `nyx-voice`, `nyx-installer`, `nyx-welcome`, `nyx-dock`,
  `nyx-control-center`, `nyx-notification-center`, `nyx-switcher`, `nyx-share`,
  `nyx-backup`, `nyx-clipboard`, `nyx-hyprland`, `nyx-plymouth`, `nyx-wallpapers`.
  By design nyx-packages' CI builds every package and each build runs its Cargo tests
  (narrowed in about ten packages), but every push to nyxos and nyx-packages since
  10 November fails at the format check before anything is built (NYX-CI-001, see
  [packaging-ci.md](packaging-ci.md)).
- **READMEs still describe Omarchy.** 28 READMEs present the app as Omarchy software in
  their opening (see [docs-review.md](docs-review.md)).
