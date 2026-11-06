# The desktop: Hyprland and the Nyx shell

Read this before changing keybindings, monitors, windows, the bar, dock, panels, the lock
screen or idle behaviour.

## Hyprland's files

Hyprland is configured in Lua. Its files in `~/.config/hypr/`, in the order they load:

| File | Written by | Edit? |
| --- | --- | --- |
| `hyprland.lua` | NyxOS (Home Manager): defaults, keybindings | **No**: a read-only link into the Nix store |
| `nyx-switcher.lua` | Nyx Switcher, from its settings | No |
| `nyx-theme.lua` | nyx-themed, from the Nyx theme | No |
| `user.lua` | **You**: the user's own lines | **Yes**; NyxOS never writes it |
| `settings.lua` | Nyx Settings, from `~/.config/nyx-settings/state.json` | No; use Settings |

Later files win. Put hand edits in `~/.config/hypr/user.lua` (create it if it's missing).
What Settings sets (monitors, input, look and feel, keybindings added or turned off on its
Keybindings page) loads after `user.lua`; if a line in `user.lua` seems to do nothing,
check whether Settings sets the same thing and change it there instead.

After any edit:

```bash
hyprctl reload
hyprctl configerrors        # must print nothing (or "no errors")
```

If there are errors, fix or revert the edit before doing anything else; a broken file can
leave the session without keybindings.

### The Lua API, by example

```lua
-- ~/.config/hypr/user.lua
local function launch(command) return hl.dsp.exec_cmd("uwsm app -- " .. command) end

hl.bind("SUPER + E", launch("nyx-files"), { description = "Files" })
hl.unbind("SUPER + T")                               -- turn a default binding off
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))

hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1.25 })

hl.window_rule({
  name = "pip",                                      -- every rule needs a unique name
  match = { class = "^firefox$", title = "^Picture-in-Picture$" },
  float = true, pin = true, size = { 640, 360 },
})
hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true })

hl.config({
  general = { gaps_in = 4, gaps_out = 8, border_size = 2 },
  decoration = { rounding = 10 },
  input = { kb_layout = "us", follow_mouse = 1, touchpad = { natural_scroll = true } },
})

hl.env("XCURSOR_SIZE", "24")
hl.exec_cmd("uwsm app -- some-tray-app")             -- start something with the session
```

- Start programs through `uwsm app -- CMD` so they run in the session's systemd scope.
- Find a window's class and title with `hyprctl clients -j`; monitors with
  `hyprctl monitors -j`; the live bindings with `hyprctl binds -j`.
- Hyprland's own docs (wiki.hypr.land) describe every option; the Lua names match them.

### Default keybindings

| Keys | Does |
| --- | --- |
| Super Enter | Terminal (the default terminal, `xdg-terminal-exec`) |
| Super Space | Glimpse (launcher and search) |
| Super Q | Close window |
| Super T / Super F | Float / fullscreen |
| Super arrows | Move focus |
| Super 1-0 / Super Shift 1-0 | Go to / move window to workspace (Super Shift Alt: without following) |
| Super Tab, Super Shift Tab | Switch apps (Switcher); Alt Tab, Alt ` switch windows |
| Super Alt W | All windows (overview) |
| Super Ctrl Left/Right, Super Ctrl Tab | Next/previous/former workspace |
| Super S, Super Alt S | Scratchpad: show / move window there |
| Super Ctrl L | Lock |
| Super Shift Ctrl A | The default coding agent (`nyx agent`) |
| Alt Space (hold) | Talk to Nyx Assistant; Super Shift Escape stops it |
| Super Shift E | Sign out |
| Super + drag | Move (left button) / resize (right button) a window |

Settings > Keybindings shows the full list, including the ones apps add.

## Monitors

Settings > Displays (`nyx-settings --section displays`) sets resolution, refresh rate,
scale, position and mirroring, and writes them to `settings.lua`. For something it can't
express, add `hl.monitor(...)` to `user.lua` and make sure Settings doesn't also set that
output.

## The Nyx shell

Each part is a user service. Its settings are TOML under `~/.config/nyx/`; the parts
follow edits live. Settings has a page for each (`nyx-settings --section ID`).

| Part | Service | Settings file | Settings page |
| --- | --- | --- | --- |
| Bar | `nyx-bar` | `bar.toml` (layout), `plugins.toml` (which plugin parts are on) | `bar`, `plugins` |
| Dock | `nyx-dock` | `dock.toml` | `dock` |
| Control Center | `nyx-control-center` | `control-center.toml` (pages of tiles) | `control-center` |
| Notifications | `nyx-notifyd`, `nyx-notification-center` | in Settings | `notifications` |
| Glimpse | started on demand | `~/.config/nyx-glimpse/settings.toml` | — |
| Switcher | `nyx-switcher` | in Settings (writes `~/.config/hypr/nyx-switcher.lua`) | `switcher` |
| Lock screen | `nyx-lock` (Nyx Locker) | `appearance.toml` (`lock-theme`, `lock-style`) | `idle` |
| Idle | `idle.toml`: `lock`, `screen-off`, `suspend` in seconds (0 never) | — | `idle` |
| Wallpaper | `nyx-wallpaper` | `appearance.toml` `wallpaper = "/path"` | `theme` |

Restart a part after a change it didn't pick up: `systemctl --user restart nyx-bar`.

### Bar plugins

```bash
nyx plugin list                      # installed plugins and their parts
nyx plugin search [TERM]             # the Nyx plugin index
nyx plugin info ID                   # what it does and what it may access
nyx plugin add URL|NAME [--enable] [--section left|center|right]
nyx plugin enable ID[/ITEM] [--section S] [--before E|--after E]
nyx plugin disable ID[/ITEM]
nyx plugin configure [ID]
nyx plugin update [ID]
nyx plugin remove ID
```

Plugins live in `~/.local/share/nyx/plugins`. The bar's layout is `~/.config/nyx/bar.toml`:
`left`, `center` and `right` lists of plugins (`"nyx.clock"`) or their items
(`"nyx.system/volume"`), plus `[plugins."ID"]` settings and `[monitors."NAME"]` layouts.
Adding a third-party plugin shows its permissions; let the user approve them, and never
pass `--yes --allow-system` on their behalf without asking.

To change a built-in plugin, `nyx plugin clone ID NEW_ID` and edit the copy.

## Terminal and shell

- Zsh: its config is in `~/.config/zsh` (`ZDOTDIR`); `.zshrc` and `.zshenv` there are
  generated (read-only). Put the user's aliases, functions, exports and
  `PATH` additions in `~/.config/zsh/user.zsh`, which it sources last; NyxOS never writes
  that file. Check with `exec zsh` or a new terminal.
- Foot: `~/.config/foot/foot.ini` is generated, and `nyx-theme.ini` beside it is rewritten
  by nyx-themed at every theme change, so neither holds hand edits. Font and padding come
  from NyxOS; for other options, tell the user they need a NyxOS change.
- The default terminal is the first line of `~/.config/xdg-terminals.list` (desktop file
  IDs, e.g. `foot.desktop`); Settings > Default Apps changes it.
- `EDITOR` comes from `~/.config/nyx/editor` (Settings > Default Apps).
- Before editing any dotfile, `ls -la` it: a link into `/nix/store` is generated.
