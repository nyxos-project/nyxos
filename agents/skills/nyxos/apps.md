# Nyx apps and default apps

Read this before changing how a Nyx app behaves, turning apps on or off, or changing which
app opens what.

## The apps

Each Nyx app is a GTK 4 program. Its command is `nyx-<name>`, its app ID (Wayland class,
desktop file, D-Bus name) `io.github.design_nexus.nyx.<Name>`, and its files are:

- `~/.config/nyx-<name>/`: settings (`settings.toml` and friends). Safe to edit with the
  app closed, or through the app.
- `~/.local/share/nyx-<name>/`: data (mail, notes, libraries, indexes). Don't edit by hand;
  back it up before anything risky.
- `~/.cache/nyx-<name>/`: safe to delete while the app is closed.

| App | Command | Notes |
| --- | --- | --- |
| Files | `nyx-files` | File manager |
| Mail | `nyx-mail` | Sync service `nyx-maild` |
| Calendar | `nyx-calendar` | Sync service `nyx-calendard` |
| Contacts | `nyx-contacts` | |
| Reminders | `nyx-reminders` | Sync service `nyx-remindersd` |
| Notes | `nyx-notes` | |
| Notepad | `nyx-notepad` | Plain text editor |
| Write, Sheets, Present | `nyx-write`, `nyx-sheets`, `nyx-present` | Nyx Office |
| PDF | `nyx-pdf` | |
| Photos, Photo Viewer | `nyx-photos`, `nyx-viewer` | |
| Music, Media Player, Theater | `nyx-music`, `nyx-media-player`, `nyx-theater` | |
| Capture | `nyx-capture` | Screenshots and screen recording |
| Passwords | `nyx-passwords` | Vault service `nyx-passwords`; never read its data |
| Backup | `nyx-backup` | Background service `nyx-backup` |
| Share, Transfer | `nyx-share-sheet`, `nyx-transfer` | `nyx share FILE…` from a terminal |
| Clipboard | `nyx-clipboard` | History service `nyx-clipboardd` |
| Archive, Calculator, Fonts | `nyx-archive`, `nyx-calculator`, `nyx-fonts` | |
| Git, Containers | `nyx-git`, `nyx-containers` | |
| Chat, News, Maps, Weather | `nyx-chat`, `nyx-news`, `nyx-maps`, `nyx-weather` | |
| Home | `nyx-home` | Smart home; automation service `nyx-homed` |
| Torrents, Pulse, Activity | `nyx-torrents`, `nyx-pulse`, `nyx-activity` | Activity is the system monitor |
| Assistant | `nyx-assistant` | Local voice assistant; daemon `nyx-assistantd` |
| Glimpse | `nyx-glimpse` | Launcher and search (Super Space) |
| Settings | `nyx-settings` | `--section ID` opens a page |
| Store | `nyx-store` | Software |
| Welcome | `nyx-welcome` | Setup after installing; can be run again |

Which apps are installed: `ls /run/current-system/sw/share/applications | grep nyx`.
Turn one on or off for everyone: `nyx-system app NAME on|off|default` (names as in
`nyx.<name>.enable`: `mail`, `media-player`, `office`, `photos`…), or its catalog item.

Start an app from a script with `uwsm app -- nyx-files`; quit it with
`pkill -x nyx-files` only when the user agrees (unsaved work). Background services are
user units: `systemctl --user status|restart nyx-maild`. `systemctl --user list-units
'nyx*'` lists them all.

## Settings pages

`nyx-settings --section ID` opens Settings on a page (or switches the open window):

`home`, `wifi`, `bluetooth`, `network`, `mounts`, `sharing`, `displays`, `audio`, `power`,
`idle`, `printers`, `disks`, `theme`, `look`, `bar`, `plugins`, `nightlight`, `dock`,
`switcher`, `control-center`, `notifications`, `workspaces`, `workspace-profiles`,
`keybindings`, `rules`, `capture`, `keyboard`, `mouse`, `trackpad`, `accounts`, `sign-in`,
`online-accounts`, `assistant`, `region`, `boot`, `apps`, `software`, `services`,
`extensions`, `about`.

When the user asks for something Settings has a page for and you can't do it from files
or a command, open that page and tell them what to change.

## Default apps

| Default | Where it's kept | From a terminal |
| --- | --- | --- |
| Which app opens each file type and link | MIME defaults (`~/.config/mimeapps.list`) | `xdg-mime default APP.desktop TYPE`; `xdg-mime query default TYPE` |
| Web browser | same | `xdg-settings set default-web-browser APP.desktop` |
| Terminal (Super Enter) | `~/.config/xdg-terminals.list`, first line | write the desktop ID first (`foot.desktop`) |
| Text editor (`EDITOR`) | `~/.config/nyx/editor`, `~/.config/environment.d/60-nyx-editor.conf` | Settings > Default Apps |
| Coding agent (Super Shift Ctrl A) | `~/.config/nyx/agent` | `nyx agent default CMD` |

Settings > Default Apps (`nyx-settings --section apps`) sets all of them. Desktop IDs are
the `.desktop` file names in `/run/current-system/sw/share/applications`,
`/etc/profiles/per-user/$USER/share/applications` and `~/.local/share/applications`.

## Coding agents

```bash
nyx agent                    # start the default agent here (or in a new terminal)
nyx agent default [CMD]      # show or set it: claude, codex, agy, cursor-agent, grok,
                             #   crush, opencode, omp, gemini, pi (none clears it)
nyx agent list [--all]       # the installed agents
nyx agent skills             # link these skills into every agent's skills folder
```

`nyx agent` starts the agent with its "work without asking" flag, as the user chose the
task. Run by name (`claude`, `codex`…) an agent keeps its own approval prompts. Agents are
installed from the catalog's `agents` section.

The NyxOS skills live in `/etc/nyxos/agents/skills` (read-only, updated with the system) and
are linked into `~/.agents/skills`, `~/.config/agents/skills`, `~/.claude/skills`,
`~/.config/opencode/skills`, `~/.grok/skills` and `~/.gemini/*/skills`. A skill of the
user's own with the same name is left alone.
