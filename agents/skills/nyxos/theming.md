# Themes, wallpaper, icons and fonts

Read this before changing colours, the theme, the wallpaper, icons or fonts.

## How theming works

One Nyx theme styles everything. The user's choice is `~/.config/nyx/theme.toml`; every Nyx
app follows it within a second, and **nyx-themed** (a user service) carries it to the rest
of the desktop: Hyprland's borders and background, Foot's colours (and Helix's, through
the terminal palette), GTK's light or dark preference, the Umbra icons and the wallpaper.
Change the theme file and everything follows; don't edit what nyx-themed writes
(`~/.config/hypr/nyx-theme.lua`, `~/.config/foot/nyx-theme.ini`, `~/.local/share/icons/Umbra`).

```toml
# ~/.config/nyx/theme.toml
mode = "theme"          # follow the Nyx theme below (keep it on NyxOS)
theme = "nyx-dark"      # a shipped theme, or custom:<file name> for the user's own
density = "comfortable" # or "compact"
text_scale = 1.0        # 0.9 to 1.25
start = "home"          # apps open on their start page, or "last" for the last page

[app_accents]           # each app's accent, by swatch name
mail = "violet"
```

Settings > Theme (`nyx-settings --section theme`) and Look (`look`) change the same file.

Shipped themes: `nyx-dark`, `nyx-light`, `catppuccin-mocha`, `catppuccin-macchiato`,
`catppuccin-frappe`, `catppuccin-latte`, `dracula`, `everforest`, `gruvbox-dark`,
`kanagawa`, `nord`, `one-dark-pro`, `rose-pine`, `solarized-dark`, `tokyo-night`,
`tokyo-night-moon`, `tokyo-night-storm`.

## Making or tuning a theme

User themes are TOML files in `~/.config/nyx/themes/` (every app) or
`~/.config/nyx-<app>/themes/` (one app). Two ways:

- **Tune a shipped theme:** a file with the same name (`~/.config/nyx/themes/nyx-dark.toml`)
  holding only the keys to change. It overrides the shipped one everywhere.
- **A new theme:** `~/.config/nyx/themes/<name>.toml` with `name = "..."` and usually
  `inherits = "nyx-dark"` (or another shipped theme) so only the differences are needed.
  Select it as `theme = "custom:<name>"`.

```toml
# ~/.config/nyx/themes/midnight.toml
name = "Midnight"
inherits = "nyx-dark"
accent = "#7c5cff"
bg = "#08080c"

[font]
ui = "Inter"
mono = "JetBrains Mono"
```

Keys (all optional over the inherited theme):

- `light` (bool); core colours `bg`, `surface`, `text`, `dim_text`, `accent`, `border`,
  `muted`, `highlight`, `danger`, `glow`, `shadow`; surfaces `panel`, `card`, `raised`,
  `popover`, `text_tertiary`, `divider`, `warning`, `success`; `hover` and `selection`
  (0 to 1, how strongly the accent tints rows)
- `[swatches]`: the accent choices every app offers (`blue`, `violet`, `pink`, `red`,
  `coral`, `amber`, `green`, `teal`, `graphite`), `[accents]`: each app's default accent
- `[font]`: `ui`, `mono`, `weight`, `heading_weight`
- `[shape]`: `radius_small`, `radius_card`, `radius_dialog`
- `[material]`: `see_through`, `blended`; `[icons]`: `file_colors`; `[syntax]`: code colours

With `inherits`, write only the keys that differ; the shipped themes are built into the apps,
not files on disk. Saving the file restyles open apps at once; check the result in a Nyx
app and in a new terminal. Colours are `#rrggbb`; a file that doesn't parse is skipped,
so if nothing changes, check the TOML (`taplo check FILE` with `nyx shell taplo`).

## Wallpaper

`wallpaper = "/path/to/image"` in `~/.config/nyx/appearance.toml` (Settings > Theme). Without
one, each theme's own wallpaper from the Nyx wallpapers is shown (`nyx-wallpaper` service).

## Icons

- **Umbra** is the icon theme for apps, folders and files. nyx-themed redraws it in the
  theme's colours whenever the theme changes (`~/.local/share/icons/Umbra`); there's nothing
  to rerun by hand.
- The Nyx apps' own icons follow the theme too (`nyx icons --help`).
- To use another icon theme for GTK apps, set it in Settings > Theme; Umbra stays the default
  for every account (`gtk-icon-theme-name=Umbra` in `/etc/xdg/gtk-*/settings.ini`).

## Fonts

- The interface and monospace fonts are the theme's `[font]` (`ui`, `mono`); the terminal
  uses NyxOS's monospace font.
- Install a font family for the user with `nyx install` (e.g. `nyx install jetbrains-mono`;
  Nerd Fonts are `nerd-fonts.jetbrains-mono` and similar), then `fc-cache -f`, then name it
  in the theme. `fc-list : family | sort -u` lists what's installed.

## The lock screen, sign-in, boot and login

- Lock screen theme and sign-in animation: `lock-theme` and `lock-style` (`circular`,
  `cyberpunk`, `minimal`, `edge`) in `~/.config/nyx/appearance.toml`, or Settings.
- For every account, and the boot and login screens: `nyx-system set theme|boot-theme|login-theme
  THEME` (system.md). The boot screen (Plymouth) and the boot menu (Limine) use the boot theme.
