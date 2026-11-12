# Nyx Passwords scorecard

- **Repository:** design-nexus/nyx-passwords at `7a090fa2d8` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user)
- **Purpose:** Bitwarden-API client for a self-hosted Vaultwarden server, with browser autofill
- **Stack:** Rust/GTK4 app; `nyx-passwordsd` vault daemon on a private Unix socket (peer-checked); bitwarden-crypto 4.0.0; wl-clipboard-rs; nyx-biometrics `1fe62af`; Secret Service for tokens
- **Binaries / services:** `nyx-passwords`, `nyx-passwordsd`, `nyx-passwords-bridge`, `nyx-passwords-assistant`, `nyx-passwords-settings`; user unit `nyx-passwords.service` (graphical session); action manifest; Firefox/Chromium native-messaging manifests (`nyx-packages/pkgs/nyx-passwords.nix`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Vault, editing, generator, TOTP, attachments, audit implemented; advertised autofill not deliverable on NyxOS |
| UX | 2 | Shortcuts, reveal timeouts; custom-field editing and passphrase SSH import missing |
| Accessibility | 2 | 14 icon-only buttons, 24 tooltips, 0 explicit labels |
| Reliability | 3 | 1 non-test `unwrap()`; `expect()`s on invariants; unit restarts and reloads after updates |
| Integration | 2 | Actions, Glimpse API, Assistant; browser bridge not registered for per-user installs |
| Packaging | 2 | License metadata wrong (MIT vs GPL-3.0-only); extension not built |
| Maintainability | 3 | 144 tests, threat model, architecture docs; a few stale references |

## Functionality

Sign-in with 2FA, sync with live updates, items of every type, folders/collections,
generator, TOTP, attachments without temp files, weak/reused/breached audit (k-anonymity),
trash with Undo (README "What it does"). Not yet: editing custom fields, importing
passphrase-protected SSH keys.

**Key handling:** keys live only in the daemon; it sets `PR_SET_DUMPABLE 0` and
`RLIMIT_CORE 0` (`apps/passwords/src/daemon/mod.rs:74-79`); secrets are `Zeroizing`
(`crates/nyx-passwords-core/src/secret.rs:3-59`) and bitwarden-crypto zeroes freed memory;
memory is not mlocked, so encrypted swap is assumed (`apps/passwords/docs/SECURITY.md`,
"Same-user processes"). On disk: ciphertext only (`vault.sqlite`, 0600); refresh token in
Secret Service; "Unlock with the keyring" off by default.

**Auto-lock:** idle timer (15 min default, checked every 10 s), Hyprland session lock
(polled every 2 s via the Hyprland socket), logind `Lock` and `PrepareForSleep`
(`daemon/watch.rs:76-90, 123-153`). On NyxOS, nyx-locker uses the session-lock protocol, so
the Hyprland check applies; it needs `HYPRLAND_INSTANCE_SIGNATURE` in the unit's environment
(`watch.rs:93-96`; static; confirm at runtime).

**Clipboard:** copies through Wayland data-control from the daemon, marked sensitive,
optional paste-once, cleared after 30 s only if unchanged, and on lock/exit
(`daemon/clipboard.rs:1-60`).

## UX and accessibility (static)

Ctrl+N/F, Ctrl+Shift+U/C/O, Ctrl+L, F5, F1. Icon buttons via `nyx_ui` (see NYX-APP-OFFICE-002).
CSS hex colours are inside `mix(…, @theme_accent, …)` or for the card/QR surfaces.

## Reliability

`nyx-passwords.service`: `Restart=on-failure`, restart on exit 75 after updates,
`MemoryDenyWriteExecute`, `UMask=0077`. Offline reading from the local copy.

## Integration and packaging

Desktop entry and icon; action manifest with `"activation": "dbus"` (`app/control.rs:27`;
per-user D-Bus caveat as NYX-APP-CALENDAR-002). Glimpse search API (`apps/passwords/docs/GLIMPSE_API.md`).
Omarchy: a "Follow Omarchy theme" switch shown only when Omarchy is present
(`app/settings.rs:954-961`); Hyprland socket use is NyxOS-compatible.

## Maintenance

144 tests, fuzz targets, SECURITY/ARCHITECTURE docs under `apps/passwords/docs/`. Pins:
nyx-biometrics `1fe62af`, common nyx-core/nyx-design.

## Runtime results

- Smoke test (Passwords): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 535 / 519 ms (two warm runs), RSS 132 MB 4 s after start (logs/perf-app-startup.txt, dev VM).

## Findings

### NYX-APP-PASSWORDS-001: Welcome advertises autofill, but NyxOS ships no browser extension

- **Component:** nyx-packages `pkgs/nyx-passwords.nix`, `modules/nixos/default.nix`; nyx-system catalog
- **Category:** functionality
- **Severity:** P1
- **Status of feature:** partial
- **Description:** The catalog sells "A password vault, with autofill." The package installs only the native-messaging manifests; the extension (`apps/passwords/browser/`) is built only by `install.sh`, and release Firefox needs a Mozilla-signed build that isn't distributed. For Welcome's per-user installs, the module's Firefox/Chromium host registration (`nyx.passwords.enable`) doesn't apply either.
- **Expected:** Autofill works after installing from Welcome, or the catalog doesn't promise it.
- **Actual:** `nyx-system/crates/nyx-catalog/catalog.toml:394`; `pkgs/nyx-passwords.nix:29-38`; `modules/nixos/default.nix:353-359`; `apps/passwords/README.md:103-112`.
- **Reproduce / verify:** Install Passwords from Welcome; look for the extension and for `~/.mozilla/native-messaging-hosts/io.github.design_nexus.nyx.passwords.json` (runtime).
- **Evidence:** as above
- **Affected versions:** nyx-passwords 7a090fa2d8; nyx-packages d69e87e
- **User impact:** The headline feature isn't available to NyxOS users.
- **Recommended correction:** Publish the signed extension (AMO / Chrome Web Store) and register hosts for profile installs (user-level manifests or system defaults); or drop "with autofill" for 0.1.0.
- **Effort:** M
- **Dependencies:** NYX-PKG per-user install review
- **Verification criteria:** Fresh NyxOS + Welcome install fills a login in Firefox.

### NYX-APP-PASSWORDS-002: Package metadata says MIT; the app is GPL-3.0-only

- **Component:** nyx-packages `pkgs/nyx-passwords.nix`, `lib/default.nix`
- **Category:** packaging
- **Severity:** P2
- **Status of feature:** verified
- **Description:** `buildWorkspace` defaults `meta.license` to MIT and the recipe doesn't override it; the README says GPL-3.0-only because of bitwarden-crypto.
- **Expected:** `meta.license = lib.licenses.gpl3Only`.
- **Actual:** `lib/default.nix:188-190`; `pkgs/nyx-passwords.nix:40-44` (no `license`); `nyx-passwords/README.md:79`.
- **Reproduce / verify:** Read the recipe's `meta`.
- **Evidence:** as above
- **Affected versions:** nyx-packages d69e87e
- **User impact:** Wrong license shown to users and redistributors.
- **Recommended correction:** Set the license in the recipe.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `meta.license` is GPL-3.0-only.

### NYX-APP-PASSWORDS-003: Screen-lock auto-lock depends on the unit's Hyprland environment

- **Component:** nyx-passwords `apps/passwords/src/daemon/watch.rs`
- **Category:** security
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** The daemon reads the session lock from Hyprland's socket using `XDG_RUNTIME_DIR` and `HYPRLAND_INSTANCE_SIGNATURE`; if the systemd user environment lacks the signature, only logind `Lock`, sleep and the idle timer remain.
- **Expected:** The vault locks when Nyx Locker locks the screen.
- **Actual:** `watch.rs:83-105, 123-131`.
- **Reproduce / verify:** Unlock the vault, lock the screen on NyxOS, unlock, check the vault is locked (runtime).
- **Evidence:** as above
- **Affected versions:** 7a090fa2d8
- **User impact:** Vault may stay open up to the idle timeout while the screen is locked.
- **Recommended correction:** Have Nyx Locker also call logind's `LockSession`, or confirm the environment import.
- **Effort:** S
- **Dependencies:** NYX-SEC locker review
- **Verification criteria:** Screen lock locks the vault within 2 s.

### NYX-APP-PASSWORDS-004: Stale references in docs and the recipe

- **Component:** nyx-passwords `README.md`; nyx-packages `pkgs/nyx-passwords.nix`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Root README.md:61 links `docs/ARCHITECTURE.md` and `docs/SECURITY.md`, which live in `apps/passwords/docs/`. The recipe says Nyx Biometrics "isn't packaged yet" (`pkgs/nyx-passwords.nix:3-4`), but `pkgs/nyx-biometrics.nix` exists.
- **Expected:** Working links and current comments.
- **Actual:** as cited.
- **Reproduce / verify:** `ls nyx-passwords/docs`
- **Evidence:** as above
- **Affected versions:** 7a090fa2d8; nyx-packages d69e87e
- **User impact:** Broken links to the threat model.
- **Recommended correction:** Fix the paths and the comment.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Links resolve.
