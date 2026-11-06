# Skills for coding agents

NyxOS ships skills that teach coding agents (Claude Code, Codex, Antigravity, Cursor, Grok
Build, Crush, OpenCode, oh-my-pi, Pi) how to do everything on NyxOS. One copy is shared by
every agent. This note records how Omarchy does it, which NyxOS follows, and what's left.

## How Omarchy does it

- **Where they live.** `$OMARCHY_PATH/default/agents/skills/<name>/` in the read-only
  Omarchy package: `omarchy` (end-user customization), `omarchy-app` (building Omarchy-style
  apps) and `diagnose-crash` (core dumps, and reporting confirmed bugs upstream).
- **Shape of a skill.** A `SKILL.md` with YAML frontmatter (`name`, a long `description`
  naming every trigger: the paths, tools and kinds of request it covers) and a short index
  body. The body has:
  - the critical safety rules first: never edit the package's files, back up before
    editing, ask before resets;
  - privilege rules: `sudo` with a terminal, `pkexec` without one;
  - an architecture table: component, purpose, config location;
  - command discovery (`omarchy commands`, `--help` for each group);
  - a numbered decision framework ("is it a stock command? a config edit? a theme?");
  - an out-of-scope section;
  - example requests mapped to commands.
  
  The details are in topic guides beside it (`hyprland.md`, `theming.md`, `plugins.md`,
  `hooks.md`, `capture.md`, `contributing.md`), each starting "Read this before…". Big
  skills keep templates in a separate file (`omarchy-app/templates.md`).
- **Shared by every agent.** Skills are symlinked, not copied, into each agent's
  user-level folder: `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills`,
  `~/.pi/agent/skills`, `~/.gemini/config/skills`, `~/.hermes/skills` (and each Hermes
  profile's). The links follow package updates, and a skill of the user's own with the same
  name is left in place.
- **When they're linked.** At first login (`omarchy-provision-user`), and by a migration
  whenever a new skill ships.

## How NyxOS does it

- Skills are in this repository under `agents/skills/<name>/`, installed read-only at
  `/etc/nyxos/agents/skills` (`modules/nixos/apps.nix`), so they update with the system and
  roll back with it.
- `nyx agent skills` links each one into `~/.agents/skills`, `~/.config/agents/skills`,
  `~/.claude/skills`, `~/.config/opencode/skills`, `~/.grok/skills`,
  `~/.gemini/config/skills` and `~/.gemini/antigravity-cli/skills`, which together cover the
  catalog's agents. It removes links to skills that no longer exist and leaves the user's
  own skills alone. Home Manager runs it at each activation (`modules/home/default.nix`),
  and `nyx agent` runs it before starting an agent, so an agent installed later still finds
  them.
- Same shape as Omarchy's: a `SKILL.md` index with the trigger-rich description, safety
  rules, privilege, architecture, the three configuration layers, command discovery, the
  decision framework and example requests, then one topic guide per area.

## The skills

Written now, on the parts that are settled:

| Skill | Guides |
| --- | --- |
| `nyxos` | `system.md` (flake, `nyx-system`, updates, generations, rollback, recovery, snapshots, hardware), `software.md` (catalog, `nyx`, packages for everyone, Flatpak, unfree, dev shells), `desktop.md` (Hyprland files and Lua API, keybindings, monitors, the Nyx shell, bar plugins, Zsh and Foot), `theming.md` (theme files, custom themes, wallpaper, Umbra, fonts, lock and boot), `apps.md` (every Nyx app, files, services, Settings pages, default apps, coding agents), `troubleshooting.md` |

To write once the system is final, so they don't need rewriting:

- **`nyx-app`**: building an app the way the Nyx apps are built (Rust, GTK 4, nyx-ui,
  nyx-theme, nyx-core, packaging in nyx-packages, the app-ID override for testing), like
  Omarchy's `omarchy-app` with a `templates.md`.
- **`nyx-plugin`**: writing bar, Control Center and desktop plugins (`nyx plugin new`,
  the manifest, permissions, the sandbox, `check` and `pack`), once the plugin API is frozen.
- **`diagnose-crash`**: core dumps on NyxOS (`coredumpctl`, debug symbols from the Nix store
  and debuginfod), and reporting a confirmed bug to the right repository.
- **`contributing`**: reporting NyxOS bugs and sending fixes upstream (which repository owns
  what, the dev VM, the channels).
- **Automation**: hooks or routines that run on system events, when NyxOS has them (Omarchy's
  `hooks.md`).
- **Per-area guides that will grow**: Assistant, Capture, Backup and restore, Online
  Accounts and sign-in methods, the lock screen and greeter, Displays, and
  `host.nix` recipes for common NixOS options.
- **The NyxOS desktop pieces still replacing Omarchy's**: update `desktop.md` as each lands.

When something in NyxOS changes, update the guide that describes it in the same commit.
