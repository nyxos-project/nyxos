# Nyx Greeter scorecard

- **Repository:** nyxos-project/nyx-greeter at `6c4cce1692` (pinned in nyx-packages: yes, 0 behind origin/main). The same repository holds the locker and polkit prompt, packaged separately.
- **Release tier:** base (greetd `default_session`, nyxos `modules/nixos/desktop.nix:150-161`)
- **Purpose:** the NyxOS login screen: a greetd greeter in GTK 4 inside a bare Hyprland session
- **Stack:** Rust/GTK4 with gtk4-layer-shell; `nyx-greetd` (greetd IPC), `nyx-greeter-core` (config, users, sessions, the login conversation), `nyx-signin-ui` (shared with the locker)
- **Binaries / services:** `nyx-greeter`, `share/nyx-greeter/hyprland.lua` (its session, with the binary path substituted) (`nyx-packages/pkgs/nyx-greeter.nix`); config `/etc/nyx-greeter/config.toml` and state `/var/cache/nyx-greeter` from nyxos `desktop.nix:132-147`

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Users, sessions, PAM prompts (password, fingerprint, face, key), last user remembered, sleep/restart/shut down |
| UX | 2 | Friendly failure messages and a shake; no keyboard layout or Caps Lock indicator; "greetd lost" is a dead end |
| Accessibility | 2 | All icon buttons and the password field have accessible labels; no screen reader in the greeter session |
| Reliability | 2 | PAM on its own thread; failures restart the conversation; a broken greetd connection isn't retried |
| Integration | 3 | System login theme and lock wallpaper, the chosen keyboard layout substituted into its Hyprland session |
| Packaging | 3 | Binary path patched into the session file; greeter user gets a home for caches |
| Maintainability | 2 | 11 tests in the greeter crates (18 in the repository), CI `check.yml`; docs are the README and config.toml comments |

## Functionality

- **Auth flow.** `crates/nyx-greeter-core/src/flow.rs:1-3`: the greetd conversation runs on a thread so the UI never waits on PAM. `CreateSession` per user, Secret/Visible prompts to the UI, Info/Error shown and auto-answered, `Success` → start the selected session (`flow.rs:79-129`). Error descriptions are mapped to plain words: too many tries, expired, wrong password (`flow.rs:45-61`).
- **Failure states** (`apps/greeter/src/ui.rs:556-605`): wrong password clears the field, shakes the card, shows the message on the ring and starts a new conversation for the same user; no installed sessions → "No sessions are installed."; greetd unreachable or lost → message and a disabled password field (NYX-APP-GREETER-001).
- Biometric messages go to the ring and the password waits until PAM asks (`ui.rs:608-623`).
- Power buttons run `systemctl suspend|reboot|poweroff` (`ui.rs:285-300`).
- The session file has no key bindings, animations or wallpaper of Hyprland's own; Hyprland exits when the greeter does so greetd can start the user's session or a fresh greeter (`data/hyprland.lua:1-25`).

## UX and accessibility (static)

- Accessible labels: icon buttons (`ui.rs:271-273`), Session and Other users (`ui.rs:349-355`), "Password for <name>" (`ui.rs:488`), the sign-in ring (`crates/nyx-signin-ui/src/lib.rs:350`).
- No layout indicator or Caps Lock warning anywhere in `apps/greeter` or `nyx-signin-ui` (search for caps/layout/keymap finds nothing).
- The bare Hyprland session starts no AT-SPI bus or screen reader (`data/hyprland.lua`), so the labels can't be heard at login.
- Hard-coded colours are fallbacks when the system theme can't be read (`nyx-signin-ui/src/lib.rs:93-98,125`).

## Reliability

- 3 `unwrap()` and 2 `expect()` outside tests by rough count; no panics on greetd data found.
- A crash ends Hyprland (`hyprland.lua:23-25`) and greetd shows the greeter again; text consoles stay available.

## Integration and packaging

- nyxos substitutes the machine's keyboard layout, an absolute `hyprctl` and `XCURSOR_PATH` into the session (`modules/nixos/desktop.nix:14-22`).
- No Omarchy references. Pins: nyx-core `166ff17` (main `9187295`), nyx-design `553f655` (main `e311c2f`).

## Maintenance

- Tests: 11 `#[test]` in `apps/greeter`, `nyx-greeter-core` and `nyx-greetd` (the package's `cargoTestFlags`), with a fake greetd for demos and tests (`crates/nyx-greetd/src/fake.rs`). README (51 lines) is current.

## Runtime results

- On the installed system: user card, focused password field, power buttons; typing the password signed in, session up 2.0 s later; wordmark cut to 'NYX' at 1280×800, session named 'Hyprland (uwsm-managed)' (NYX-UX-003, shots/installed-greeter.png).

## Findings

### NYX-APP-GREETER-001: When greetd's connection fails, the login screen is a dead end

- **Component:** nyx-greeter `apps/greeter/src/ui.rs:599-604`, `crates/nyx-greeter-core/src/flow.rs:66-72,104,127`
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** On `Event::Broken` ("Can't reach greetd" or "Lost greetd") the password field is disabled and the message shown; the flow thread has ended. Nothing reconnects or exits so greetd can restart the greeter.
- **Expected:** A recovery path at the login screen: retry, or quit so greetd starts a fresh greeter.
- **Actual:** see Component; the only way out is the power buttons or a text console.
- **Reproduce / verify:** Run with `--demo` against the fake greetd and stop it mid-conversation (static; confirm at runtime).
- **Evidence:** as above.
- **Affected versions:** `6c4cce1692`
- **User impact:** Can't sign in without restarting the computer.
- **Recommended correction:** After a short delay, quit the app on `Broken` (greetd restarts the greeter), or offer "Try again".
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Killing the greetd socket shows a retry or a fresh greeter within seconds.

### NYX-APP-GREETER-002: No keyboard layout indicator or Caps Lock warning at the password field

- **Component:** nyx-greeter `apps/greeter/src/ui.rs`, `crates/nyx-signin-ui/src/lib.rs`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** approved, not implemented
- **Description:** The greeter runs with the system's layout (`desktop.nix:18`) but never shows it or Caps Lock; with NYX-APP-INSTALLER-001 a mismatched layout is invisible.
- **Expected:** The current layout (and a switch when more than one is set) and a Caps Lock hint beside the password.
- **Actual:** no layout or Caps Lock code.
- **Reproduce / verify:** Read the sources; at runtime, turn Caps Lock on at the greeter.
- **Evidence:** as above.
- **Affected versions:** `6c4cce1692`
- **User impact:** Failed sign-ins with no hint why.
- **Recommended correction:** Read the layout from Hyprland (`hyprctl devices -j`) and Caps Lock from GDK's `caps-lock-state`, and show both.
- **Effort:** S
- **Dependencies:** NYX-APP-INSTALLER-001
- **Verification criteria:** The greeter shows the layout and warns on Caps Lock.

### NYX-APP-GREETER-003: No screen reader at the login screen

- **Component:** nyx-greeter `data/hyprland.lua`; nyxos `modules/nixos/desktop.nix:150-161`
- **Category:** accessibility
- **Severity:** P2
- **Status of feature:** approved, not implemented
- **Description:** The greeter's widgets have accessible labels, but its session starts no accessibility bus or Orca, and there's no shortcut to start one.
- **Expected:** A way for a blind user to sign in (GNOME and KDE greeters offer a screen-reader toggle).
- **Actual:** session file has no bindings and starts only the greeter; `nyxos.desktop.autoLogin` is the only workaround.
- **Reproduce / verify:** Boot the VM to the greeter and try to start a screen reader.
- **Evidence:** as above.
- **Affected versions:** `6c4cce1692`
- **User impact:** Blind users can't sign in unaided.
- **Recommended correction:** Start `at-spi-bus-launcher` in the greeter session and bind a shortcut (Super+Alt+S) to Orca, with a visible toggle.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** Orca reads the user name and password field at the greeter.
