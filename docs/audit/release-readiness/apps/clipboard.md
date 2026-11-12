# Nyx Clipboard scorecard

- **Repository:** design-nexus/nyx-clipboard at `0389ee07dd` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** store (`catalog.toml:459-466`, `scope = "system"`: the shell's clipboard history)
- **Purpose:** clipboard history with a keyboard popup, pins, snippets, actions and verification codes
- **Stack:** Rust/GTK4 + gtk4-layer-shell (8.7k lines), SQLite; D-Bus `io.github.design_nexus.nyx.Clipboard1`
- **Binaries / services:** `nyx-clipboardd` (Type=dbus, autostart, `UMask=0077`, `LimitMEMLOCK=8M`), `nyx-clipboard` (popup, autostart), `nyx-clipboard-settings`; D-Bus activation file; action manifest from `nyx-clipboardd` (`nyx-packages/pkgs/nyx-clipboard.nix`). NyxOS binds Super+Ctrl+V (`nyxos/modules/home/hyprland.nix:223-224`).

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | History, search, pins, snippets, multi-paste, transforms, codes, private mode implemented |
| UX | 2 | Keyboard-complete popup; its settings window can't be reached on NyxOS |
| Accessibility | 2 | 4 tooltips, 5 accessible properties; 2 hard-coded colours |
| Reliability | 3 | About 9 unwrap/expect outside tests; daemon restarts; limits enforced |
| Integration | 2 | Glimpse `cb`, Notification Center codes, Passwords, Share, Assistant actions; Settings page missing on NyxOS |
| Packaging | 2 | Units, D-Bus, actions installed; `extension.toml` not installed |
| Maintainability | 2 | 42 tests, docs (API, SECURITY, LIMITATIONS); no CI workflow |

## Functionality

- **Storage:** SQLite history opened 0600 (`crates/nyx-clipboard-store/src/lib.rs:125-128`) under the user's data dir; blobs for images. Not encrypted at rest (documented in `docs/SECURITY.md`).
- **Retention:** defaults 1000 entries, 30 days, 10 MB per item, 512 MB total (`crates/nyx-clipboard-core/src/prefs.rs:56-59`); pinned items kept.
- **Sensitive exclusion:** `x-kde-passwordManagerHint` honoured (`classify.rs:10`); regex detection of private keys, otpauth URIs, GitHub/GitLab/Slack/AWS/Google/HF/npm tokens, JWTs, `password=` lines, never written to history (`sensitive.rs:1-40`); app exclusions and private mode (Ctrl+Shift+P). Verification codes held in locked memory for 180 s and cleared from the clipboard after 30 s (`prefs.rs:70-71`).
- **Callers:** D-Bus clients checked against trusted program folders (`peer.rs`, `/etc/nyx/trusted-bin`).
- Imports Omarchy's history on first start (`omarchy.rs`); harmless on NyxOS.

## UX and accessibility (static)

Super+Ctrl+V popup, type to search, ↑/↓, Enter pastes via `wtype`, Alt+1…9, Menu/Shift+F10 actions. `docs/LIMITATIONS.md` explains the data-control protocol requirement.

## Reliability

Both units restart on failure; popup waits for the daemon. Limits trim history on insert.

## Integration and packaging

Desktop entry opens the popup (`data/desktop/…Clipboard.desktop`); icon present. Settings page `data/settings/extension.toml` (exec `nyx-clipboard-settings`) isn't installed by the package, and Settings only reads `~/.local/share/nyx-settings/extensions` (`nyx-settings/apps/settings/src/ext/mod.rs:206-207`) (NYX-APP-CLIPBOARD-001). README's "Super+V stays Omarchy's" and the install script's Hyprland block don't apply on NyxOS.

## Maintenance

42 tests (`tests/run.sh` private-bus check not in the package). No `.github/workflows`. Pins nyx-core `4f05fb8`, nyx-design `cf39397`.

## Runtime results

- Smoke test (Clipboard): dock launch **overlay**, Glimpse/GIO launch **overlay** (evidence/smoke-dock, smoke-glimpse).
- Overlay opens from the dock and GIO and closes with Escape; daemon restarted within 4 s after SIGKILL.

## Findings

### NYX-APP-CLIPBOARD-001: Clipboard settings (retention, exclusions, codes) unreachable on NyxOS

- **Component:** `nyx-packages/pkgs/nyx-clipboard.nix`; nyx-clipboard `data/settings/extension.toml`; nyx-settings `apps/settings/src/paths.rs:8-11`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The Settings extension isn't installed, Settings wouldn't find a packaged one anyway, and `nyx-clipboard-settings` has no desktop entry.
- **Expected:** Settings › Desktop › Clipboard as on Arch (README "Settings" section).
- **Actual:** No path to change history length, age, images, excluded apps or code handling except editing `~/.config/nyx-clipboard/settings.toml`.
- **Reproduce / verify:** Enable `nyx.clipboard` on the VM; open Settings › Desktop. Static; confirm at runtime.
- **Evidence:** as above; `nyx-settings/apps/settings/src/ext/mod.rs:206-207`
- **Affected versions:** `0389ee07dd`, nyx-packages `d69e87e`
- **User impact:** Privacy controls (exclusions, retention) aren't discoverable.
- **Recommended correction:** Install `extension.toml` to `share/nyx-settings/extensions/clipboard` and make Settings read `XDG_DATA_DIRS` (see NYX-APP-AGENTS-001).
- **Effort:** S
- **Dependencies:** NYX-APP-AGENTS-001
- **Verification criteria:** Clipboard page shows in Settings on the VM.

### NYX-APP-CLIPBOARD-002: No CI workflow

- **Component:** nyx-clipboard (repository)
- **Category:** CI
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Tests run only in the Nix build; the D-Bus access test (`tests/run.sh`) runs nowhere automatically.
- **Expected:** `check.yml` as in peer apps.
- **Actual:** No `.github/workflows`.
- **Reproduce / verify:** `ls .github`.
- **Evidence:** inventory `workflows: []`
- **Affected versions:** `0389ee07dd`
- **User impact:** Caller-check regressions could ship.
- **Recommended correction:** Add CI running `cargo test` and `tests/run.sh` under `dbus-run-session`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** CI green on push.
