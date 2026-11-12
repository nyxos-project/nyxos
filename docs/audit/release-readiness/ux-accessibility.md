# Design, UX and accessibility (handoff 10 sections 9, 10, 11)

Sources: 47 app screenshots from the smoke tests (montages in
[evidence/shots/montage-apps-1.png](evidence/shots/montage-apps-1.png) and `-2`), the
installed system's greeter and first run, live theme switching, an AT-SPI survey, WCAG
contrast computed for all 17 built-in themes ([evidence/contrast.md](evidence/contrast.md),
script `evidence/scripts/contrast.py`), and the static findings in [shell.md](shell.md),
[infrastructure.md](infrastructure.md) and the app scorecards.

## Design consistency (Nyx Design 2.0)

Good overall. Across 24 apps side by side the structure is the same (sidebar, header with
search, content), with one type scale, one icon set, the same accent usage, and the same
empty-state pattern (icon, one line, one primary button) in Git, Home, Theater, Photos and
Contacts. A live theme change repaints the bar in 375 ms and running apps without restart,
with bar and apps on the same colours (Catppuccin Mocha `#1e1e2e` measured in both).

Outliers: Notes' first-run vault dialog (flat buttons, larger body text); Lyra's content
area is YouTube Music's own web page; the greeter's vertical wordmark is cut to "NYX" at
1280×800; the greeter's session picker says "Hyprland (uwsm-managed)" (NYX-UX-003).
Static design findings: seven nyx-design revisions in the apps (NYX-THEME-001,
NYX-PKG-002), Omarchy-era wording in Settings (NYX-SET-001).

## Usability journeys

| Journey | Assessment | Findings |
| --- | --- | --- |
| Install | Blocked by NYX-INST-001; installer flow otherwise clear (static) | NYX-INST-001, NYX-APP-INSTALLER-001..004 |
| First run | Welcome opens at first sign-in with 14 clear steps and says how changes are made | NYX-PKG-008 (two Welcome apps can't both install) |
| App launch | Every app opens from the dock and Glimpse in under 1 s; two helper entries in the launcher do nothing | NYX-UX-001 |
| Window management | Fullscreen gets its own workspace and returns cleanly; workspace wrap works | NYX-HYPR-002 (dock/bar don't model fullscreen workspaces) |
| Files | Opens fast; no data-loss defects reproduced | apps/files.md |
| Search (Glimpse) | Works; unavailable while Shell Core is down | NYX-SHELL-002 |
| Notifications | Survive daemon restarts; `notify-send` isn't installed | |
| Device pairing | Clear "Flux isn't running / Start Flux"; pairing untested (no phone) | |
| Theme changes | Instant and consistent; a typo in theme.toml silently resets the theme | NYX-THEME-003 |
| System updates | Clear plans and offline message; raw errors elsewhere | NYX-UX-002, NYX-UPD-001 |
| Backup and restore | Works from the CLI; GUI not exercised | apps/backup.md |
| Authentication | Lock screen solid; face first, "Use password" one key away | NYX-APP-GREETER-002, NYX-APP-BIOMETRICS |

## Accessibility (WCAG 2.2 AA and Linux AT expectations)

| Area | Result |
| --- | --- |
| Assistive technology | **Disabled on every install**: `GTK_A11Y=none`, `NO_AT_BRIDGE=1`, no a11y bus (NYX-A11Y-001) |
| Accessible names (GTK apps, bridge forced on) | Notepad 8/8, Files 26/26, Calculator 32/32, Mail 29/29, Settings 55/55 buttons named; Store 56/60 (NYX-A11Y-003). GTK4 uses tooltips as names, so tooltip-only icon buttons are named |
| Shell surfaces (Quickshell) | Not on the a11y bus; keyboard paths missing outside Glimpse (NYX-SHELL-005) |
| Greeter | No screen reader, no layout or Caps Lock indicator (NYX-APP-GREETER-002/003) |
| Text contrast | Default theme Catppuccin Mocha: body text 11.3:1, secondary 3.4:1, tertiary 2.6:1 (fail 4.5:1); 15 of 17 themes fail for secondary text (NYX-THEME-002, NYX-A11Y-002) |
| Non-text contrast | Default border vs surface 1.1–1.4:1 in all 17 themes, strong border below 3:1 in 16 (NYX-A11Y-002) |
| Focus indicators | Focus ring colour passes 3:1 in every theme except Solarized Dark |
| Reduced motion, font scaling | Not verified; most apps can't read reduce-motion on NyxOS (NYX-THEME-001) |
| Keyboard | GTK apps keyboard-operable (static); shell surfaces mostly pointer-only (NYX-SHELL-005) |

## Findings

### NYX-A11Y-001: Accessibility is switched off for every session

- **Component:** nyxos `modules/nixos` (no `services.gnome.at-spi2-core.enable`); NixOS `nixos/modules/services/desktops/gnome/at-spi2-core.nix:47-50`
- **Category:** accessibility
- **Severity:** P1
- **Status of feature:** verified
- **Description:** NixOS sets `NO_AT_BRIDGE=1` and `GTK_A11Y=none` for every session when the at-spi2-core service is off, and NyxOS never turns it on. GTK and Qt apps don't expose anything to assistive technology, and `org.a11y.Bus` doesn't exist.
- **Expected:** Screen readers and other AT work with GTK apps (handoff 10 section 11, "Linux desktop accessibility expectations", WCAG 4.1.2 via the platform API).
- **Actual:** `/etc/set-environment` exports both variables; `busctl --user call org.a11y.Bus …` → "The name is not activatable". With the bus started by hand and the variables removed, the apps expose well-named controls, so the apps are ready and the system setting is the blocker.
- **Reproduce / verify:** `grep -E 'GTK_A11Y|NO_AT_BRIDGE' /etc/set-environment`
- **Evidence:** evidence/logs/atspi-buttons.txt; evidence/runtime-notes.md
- **Affected versions:** nyxos 97f1573 (dev VM) and the installed example configuration
- **User impact:** Blind and low-vision users can't use NyxOS at all; no screen reader (Orca) can be added without editing the system configuration.
- **Recommended correction:** `services.gnome.at-spi2-core.enable = true;` in `modules/nixos/desktop.nix`; offer Orca in the catalog and a Settings switch; then test the greeter, locker and shell surfaces with Orca.
- **Effort:** S (enable); M (Orca integration and testing)
- **Dependencies:** NYX-SHELL-005, NYX-APP-GREETER-003
- **Verification criteria:** On a fresh install `org.a11y.Bus` answers, and Orca reads Files, Settings and the greeter.

### NYX-A11Y-002: Themes pass Nyx's own contrast check but fail WCAG AA for secondary text and borders

- **Component:** nyx-design `crates/nyx-theme-core/src/contrast.rs`, `builtin-themes.json`
- **Category:** accessibility
- **Severity:** P2
- **Status of feature:** verified (computed)
- **Description:** nyx-theme-core asks only 3:1 of secondary text and of labels on accent buttons (`contrast.rs` PAIRS), below WCAG 1.4.3's 4.5:1 for normal-size text, and doesn't check borders at all. Measured: secondary text fails 4.5:1 in 15 of 17 built-in themes (Mocha 3.4:1), tertiary text in 16, the default border is 1.1–1.4:1 against the surface in all 17, the strong border under 3:1 in 16 (WCAG 1.4.11 needs 3:1 for component boundaries that identify controls).
- **Expected:** WCAG 2.2 AA (handoff 10 section 11); handoff 02's contrast validation.
- **Actual:** evidence/contrast.md (full table).
- **Reproduce / verify:** `evidence/scripts/contrast.py …/builtin-themes.json`
- **Evidence:** as above
- **Affected versions:** nyx-design e311c2f
- **User impact:** Hints, captions, timestamps and secondary labels are hard to read for low-vision users and in bright light; inputs that rely on a border are hard to find.
- **Recommended correction:** Raise the check to 4.5:1 for text roles that render at body size, add 3:1 checks for `border.strong` (used for input outlines and control boundaries) against surfaces, and adjust the built-in themes (or derive accessible variants) so the default passes. Ship a high-contrast theme.
- **Effort:** M
- **Dependencies:** NYX-THEME-002
- **Verification criteria:** `contrast.py` shows no failures for the default theme; nyx-theme-core's check flags the remaining themes.

### NYX-A11Y-003: Four Store category buttons have no accessible name

- **Component:** nyx-store (Home page category tiles)
- **Category:** accessibility
- **Severity:** P3
- **Status of feature:** verified (with the bridge forced on)
- **Description:** "Browse graphics", "Browse productivity", "Browse games", "Browse development" are exposed as unnamed push buttons with only a description.
- **Expected:** Every control has an accessible name (WCAG 4.1.2).
- **Actual:** evidence/logs/atspi-buttons.txt
- **Reproduce / verify:** AT-SPI survey script in evidence/logs/atspi-buttons.txt's run.
- **Evidence:** as above
- **Affected versions:** nyx-store fc2bdca
- **User impact:** A screen reader announces "button" for those tiles.
- **Recommended correction:** Set the label (`update_property(&[Property::Label(...)])`) instead of only the description.
- **Effort:** S
- **Dependencies:** NYX-A11Y-001
- **Verification criteria:** Survey shows 60/60 named.

### NYX-UX-001: The launcher lists helper entries that open nothing

- **Component:** nyxos desktop packages (foot's `foot-server.desktop`, uwsm's `uuctl.desktop`)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** "Foot Server" and "uuctl" appear in the app launcher (and to the smoke test) but open no window; Foot also appears three times (Foot, Foot Client, Foot Server).
- **Expected:** The launcher lists apps people open.
- **Actual:** smoke-dock/report.tsv: NO-WINDOW for both.
- **Reproduce / verify:** open the dock's app drawer; search "foot".
- **Evidence:** evidence/smoke-dock/report.tsv
- **Affected versions:** nyxos 97f1573
- **User impact:** Clutter and dead entries.
- **Recommended correction:** Hide them (`NoDisplay=true` overrides via `xdg.desktopEntries` or a filtered package).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Smoke test lists only entries that open.

### NYX-UX-002: Network failures show raw error text

- **Component:** nyx-system catalog install; nyx-ai pull; nyx-store header
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Offline, `nyx update` explains "there's no network connection", but catalog installs print Nix's "unable to download 'https://api.github.com/…' Could not resolve hostname (6)", `nyx-ai pull` prints a reqwest error, and the Store shows "Flathub could not load: error: Can't load in https://dl.flathub.org/… Could not resolve hostname" in its header.
- **Expected:** Actionable messages (handoff 10 section 10: "Are error messages actionable?").
- **Actual:** evidence/logs/network-loss.txt, shots/offline-store.png
- **Reproduce / verify:** `nmcli networking off`; run the commands; open the Store.
- **Evidence:** as above
- **Affected versions:** nyx-system 6f0c47c, nyx-ai d325462, nyx-store fc2bdca
- **User impact:** Users see URLs and resolver codes instead of "You're offline".
- **Recommended correction:** Reuse nyx-system's connectivity check before network operations and map resolver/connection errors to one message.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** The same steps show a plain offline message everywhere.

### NYX-UX-003: Login screen polish: wordmark cut off, technical session name

- **Component:** nyx-greeter; nyx-wallpapers (wordmark)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** At 1280×800 the vertical wordmark shows only "NYX" (the "OS" falls off-screen). The session picker reads "Hyprland (uwsm-managed)", the desktop file's name.
- **Expected:** The brand shows whole at common resolutions; the session is called NyxOS.
- **Actual:** evidence/shots/installed-greeter.png
- **Reproduce / verify:** boot the installed system at 1280×800.
- **Evidence:** as above
- **Affected versions:** nyx-greeter 6c4cce1, nyx-wallpapers a2adbbc
- **User impact:** First impression looks unfinished.
- **Recommended correction:** Scale the wordmark to the screen height; ship a `nyxos.desktop` session (or rename in the greeter) and hide the plain Hyprland one.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Greeter at 1280×800 shows "NYXOS" and "NyxOS" as the session.

### NYX-UX-004: `nyx system generations` prints Unix timestamps

- **Component:** nyx-system `system-cli` (generations)
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Output is `* 244  1794462566  0.1.0`.
- **Expected:** A date and time, like `nixos-rebuild list-generations`.
- **Actual:** evidence/logs/runtime-nyx-update.txt
- **Reproduce / verify:** `nyx system generations`
- **Evidence:** as above
- **Affected versions:** nyx-system 6f0c47c
- **User impact:** People can't tell which generation to roll back to.
- **Recommended correction:** Format the timestamp in local time.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Output shows dates.
