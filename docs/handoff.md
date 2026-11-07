# Handoff: where NyxOS stands (2026-11-07)

Read this first in a new session. It covers what's done, what's half done, what Ken is
deciding, and how to work so things don't break again.

## How to work (Ken's rules, and lessons from this session)

- **Test the way a person uses NyxOS, not the piece you changed.** Open apps from the
  dock, its app drawer and Glimpse, not with `hyprctl exec` or a store path. Use the
  app: browse in Files, open Trash, change a setting, install from the Store. A
  screenshot of an idle screen proves nothing.
- **Read the logs after every test:** `journalctl _UID=1000 --since -10min` and
  `journalctl -b -p err` in the VM. Look for errors, crashes (`coredumpctl list`) and any
  line that repeats every second.
- **Keep every Nyx app pin current.** nyx-packages pins each app at a commit; update all
  of them (not just the app you touched) before testing NyxOS as a whole.
- **Watch the VM's disk.** `scripts/dev-vm disk check` after big builds (rebuild does it
  for you); `scripts/dev-vm disk clean` when it warns. Past the quota the VM's disk turns
  read-only and builds die quietly.
- **Ken's laptop:** tell Ken before installing or running anything there, and say when
  an install will ask for his password (install scripts use `pkexec` without a terminal).
  Nyx apps changed in a session are installed with `./install.sh <app> </dev/null`.
  Never touch his mouse, keyboard or focus; test windows go only on a headless output you
  create (see `.cursor/rules/screenshots-virtual-monitor.mdc`).
- Commit in each repo; push nyxos to `main` and `main:testing`.

## Uncommitted right now

- **nyx-packages** (`~/Projects/nyx-packages`): `flake.lock` and `lib/git-hashes.json`
  move 25 Nyx apps to their latest commits (Files was a week behind: no fixes since Nov 1).
  Not built yet: the full build was killed when the VM's disk filled. Next step below.

## Next steps

1. **Build every package** with the new pins, detached so it survives the session:

   ```bash
   cd ~/Projects/nyx-packages
   tar --exclude=.git --exclude=result -cf - . | incus exec nyxos-dev -- /run/current-system/sw/bin/tar -C /etc/nyxos/nyx-packages -xf -
   ~/Projects/nyxos/scripts/dev-vm exec systemd-run --unit nyx-pkgall --property=WorkingDirectory=/etc/nyxos/nyx-packages \
     --setenv=PATH=/run/wrappers/bin:/run/current-system/sw/bin /run/current-system/sw/bin/bash -c \
     'nix build --no-link --keep-going path:/etc/nyxos/nyx-packages#default > /var/tmp/pkgall.log 2>&1; echo build exit $? >> /var/tmp/pkgall.log'
   ```

   Log in `/var/tmp/pkgall.log` (not `/tmp`: system services get a private one). Fix any
   app that fails, in its own repo.
2. **Commit nyx-packages**, then in nyxos run `nix flake update nyx-packages` in the VM
   (`/etc/nyxos/flake`), pull `flake.lock` back, and `scripts/dev-vm rebuild`.
3. **Smoke test** (`scripts/smoke-apps dock`, then `scripts/smoke-apps glimpse`): opens
   every app as the dock and as Glimpse do, records its startup errors and a screenshot in
   `/tmp/nyx-smoke-*`. Then by hand: Files (browse, Trash, Network, a USB drive), Settings
   page by page, Store install and remove, Welcome start to finish, lock and unlock,
   notifications, Control Center tiles, the bar's plugins, Glimpse search.
4. **Fix what's broken, then report everything to Ken**, including what wasn't fixed.

The VM helpers in `/tmp` (`k.sh`, `vmclean.sh`, `vmfocus.sh`) were lost when the VM
restarted; `scripts/smoke-apps` does what they did. Ken's session in the VM is user `ken`
(uid 1000), Wayland display `wayland-1`, Hyprland signature in `/run/user/1000/hypr/`.

## Fixed this session (all committed and pushed)

- Dock, Control Center, notifications and Home couldn't start apps: NyxOS lacked
  `gtk-launch` (from GTK 3). NyxOS now ships it (`modules/nixos/desktop.nix`).
- nyx-themed re-applied the theme ~3 times a second for days (it reacted to its own reads
  of `theme.toml`); fixed in nyx-system `e7c6f9a`.
- Files couldn't open Trash or Network: GVfs is now on (`services.gvfs.enable`).
- The dev VM's disk filled its host quota and went read-only. Cleaned (42 GiB counted
  now, of 200), old snapshots pruned (kept `known-good-12`, `pre-limine`), and guarded:
  online discard, daily fstrim and GC, GC during builds below 30 GiB free, a 300 MB
  journal, and `dev-vm disk check|clean`.
- Earlier: `nyx agent` and the default coding agent (Settings, Welcome, Super Shift Ctrl
  A); NyxOS skills for every agent (`agents/skills`, see `docs/agent-skills.md`);
  Antigravity CLI, IDE and app, ChatGPT desktop and Herdr desktop packages
  (`pkgs/`, overlay in `modules/nixos/packages.nix`) and catalog items.

## Known problems not fixed yet

- Settings > Default Apps in the VM shows **Write** as the web browser.
- Apps that use the keyring (Antigravity, ChatGPT) show GNOME's old "Unlock Login
  Keyring" prompt in the VM, whose session starts by autologin; check it unlocks with a
  password sign-in on real hardware, and consider a Nyx-styled prompt.
- Files reopens the last tab; it had saved `trash:///`, which failed without GVfs.
- The VM lock screen says "Fingerprint not recognised" (biometrics on, no reader).
- Control Center's volume tile is tall without brightness; the notification center is a
  full-height drawer.

## Waiting on Ken: the Catppuccin Mocha look

Ken wants Catppuccin Mocha as NyxOS's default theme and a new identity (wallpaper, logo,
boot, login, lock). Four rounds of mockups are in `~/Pictures/nyx-catppuccin-mockups/`
(`round-1` … `round-4`, each with `overview-*.png`); generators in `src/gen*.py`. He
hasn't chosen. His latest direction (round 4): simple, modern, clean and techie like his
current Omarchy desktop, a flat mantle background (#181825) with one centred wordmark in
blue (#89b4fa). Round 4 has 12 wordmarks and four full sets (pixel gothic, pixel
lowercase, squared tech, mono). Don't build any of it until he picks.
