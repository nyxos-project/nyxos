# Nyx Pulse scorecard

- **Repository:** design-nexus/nyx-pulse at `799f1b7081` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("Telegram, with calls.")
- **Purpose:** native Telegram client with one-to-one and group calls, stories, Mini Apps and business tools
- **Stack:** Rust/GTK4; TDLib 1.8.67 (`libtdjson`, loaded at runtime); NTgCalls 3.0.5 WebRTC engine (prebuilt upstream binary, bindgen bindings); libmpv for media; GStreamer + PipeWire for screen share; a separate Python GTK 3/WebKitGTK 4.1 helper for Mini Apps and libfido2 passkeys; GeoClue; Secret Service; Glimpse plugin; legacy nyx-core control
- **Binaries / services:** `nyx-pulse` plus its Glimpse plugin binary (`nyx-packages/pkgs/nyx-pulse.nix`: `glimpsePlugin = true`; `TDLIB_PATH` default to `nyx.tdlib_1_8_67`; `libntgcalls.so` symlinked to `share/nyx/lib`; `PULSE_PYTHON` helper; runtime `ffmpeg`, `pulseaudio` (pactl), `libcanberra-gtk3`, `libsecret`); option `nyx.pulse.enable` also enables GeoClue and GNOME Keyring (`modules/nixos/default.nix:389-392`)

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Very broad TDLib coverage (`apps/pulse/PARITY.md`); calls implemented but cross-client interoperability unverified per README |
| UX | 2 | Shortcuts documented and configurable; many tool windows; large surface to verify |
| Accessibility | 2 | Mostly labelled buttons (3 icon-button sites, 15 tooltip mentions, 2 explicit labels); needs runtime check |
| Reliability | 2 | 25 non-test unwraps incl. runtime-data ones (`chat_list.rs:374,379`); mock TDLib not used in production (`ffi.rs:52-71`) |
| Integration | 2 | `tg:`/`nyx-pulse:` URL handler, Glimpse plugin, keyring; no action manifest |
| Packaging | 2 | TDLib pinned from source; NTgCalls is a hash-pinned prebuilt binary; Telegram API credentials compiled in |
| Maintainability | 2 | 42 tests, check.yml CI; ARCHITECTURE/RISKS contradict the code on API credentials; 27-line README |

## Functionality

- Sessions: per-account TDLib databases in `$XDG_DATA_HOME/nyx-pulse/accounts/<id>/data/`, media cache in `$XDG_CACHE_HOME/nyx-pulse/accounts/<id>/files/` (README).
- Database encryption: per-account key in the Secret Service via `secret-tool` (`apps/pulse/src/secrets.rs:1-9,68`); existing sessions upgraded through TDLib's key change with a recovery marker; if setting parameters fails during a pending migration, it retries unencrypted (`service.rs:88-97`).
- Telegram API id/hash: a project-specific pair (not one of the well-known public client IDs) is committed as the default in `crates/nyx-telegram-core/src/auth.rs:28-29` and `apps/pulse/src/service.rs:84-85`; prefs can override (`prefs.rs:22-23`). Values not reproduced here.
- Calls: TDLib signalling + NTgCalls media; README: "interoperability with another Telegram client still requires an authorized remote test contact … live cross-client interoperability remains unverified".
- TDLib missing: production start reports it instead of using the mock driver (`ffi.rs:52-71`; README).

## UX and accessibility (static)

- Keys: Ctrl+F, Ctrl+B, Ctrl+,, F1, Esc, Enter/Shift+Enter, Ctrl+Q, Ctrl+W; tool shortcuts configurable (README).
- Colours: `auth_view.rs:95,108` grey/dark literals in a QR drawing; `export_bundle.rs` literals in exported HTML (fine).

## Reliability

- Notifications only while Pulse is open (README); no background service.
- `calls.rs:244-321` lock a `Mutex` with `unwrap()` across the call engine.

## Integration and packaging

- Desktop entry `apps/pulse/data/io.github.design_nexus.nyx.Pulse.desktop`: `MimeType=x-scheme-handler/nyx-pulse;x-scheme-handler/tg;`.
- Glimpse plugin installed to `share/nyx-pulse/glimpse` by `buildApp`.
- Control: legacy `control::serve_async` (`main.rs:94`), no manifest.
- Omarchy leftovers that execute on NyxOS: `device_model: "Nyx Desktop (Omarchy Linux)"` sent to Telegram (`auth.rs:31`); `--version` text "for Omarchy Linux" (`main.rs:70`). Mock fixtures with Omarchy strings (`ffi.rs:314,370,760`) are compiled in but unreachable.

## Maintenance

- Tests: 42 (one loopback call test skipped in the Nix sandbox); CI `check.yml`, `release.yml`.
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`, nyx-glimpse `6f9f732` (origin/main `deecabf`).
- NTgCalls: `pkgs/ntgcalls.nix` fetches the upstream release zip (sha256-pinned), `sourceProvenance = binaryNativeCode`, LGPL-3.0.

## Runtime results

- Smoke test (Pulse): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-PULSE-001: Project Telegram API id/hash compiled into the source as defaults

- **Component:** nyx-pulse `crates/nyx-telegram-core/src/auth.rs:28-29`, `apps/pulse/src/service.rs:84-85`
- **Category:** security
- **Severity:** P2
- **Status of feature:** verified
- **Description:** A project-specific Telegram API id and hash are committed in two places and used by every install. Telegram ties an api_id to the developer's account and revokes IDs that are abused; anyone who reads the source can reuse it. If it's revoked, sign-in breaks for every Pulse user at once. The repo's own docs say users bring their own id via a setup wizard and Secret Service (`apps/pulse/ARCHITECTURE.md:223`, `RISKS.md:15,61`), which the code doesn't do. Raise to P1 if the repository is public at release.
- **Expected:** Credentials injected at build time (nyx-packages, not in the public tree), or a documented decision to embed them as Telegram Desktop does, with a rotation plan.
- **Actual:** literals in both files; no setup wizard.
- **Reproduce / verify:** `rg -n api_hash crates apps` (do not copy values into reports).
- **Evidence:** as cited
- **Affected versions:** `799f1b7081` (present since at least `f3d0d70`)
- **User impact:** Risk of a sudden, total outage of sign-in.
- **Recommended correction:** Move the pair to a build-time env (`option_env!`) set by nyx-packages; keep the prefs override; update ARCHITECTURE/RISKS.
- **Effort:** S
- **Dependencies:** NYX-SEC, NYX-PKG
- **Verification criteria:** No literal id/hash in the repository; builds still sign in.

### NYX-APP-PULSE-002: Calls, the advertised feature, are unverified against other Telegram clients

- **Component:** nyx-pulse `README.md` (calls paragraph), `crates/nyx-telegram-calls`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The catalog sells Pulse as "Telegram, with calls", but the README says live cross-client interoperability "remains unverified"; only a local loopback test exists, and it's skipped in the Nix build (`pkgs/nyx-pulse.nix` `checkFlags`).
- **Expected:** One-to-one and group calls verified with official Telegram clients before release.
- **Actual:** as cited.
- **Reproduce / verify:** Phase D/F: call between Pulse on NyxOS and Telegram Desktop/mobile, both directions, audio and video.
- **Evidence:** as cited
- **Affected versions:** `799f1b7081`
- **User impact:** Calls may fail to connect or carry no media.
- **Recommended correction:** Run the interop matrix; if it fails, drop "with calls" from the catalog until fixed.
- **Effort:** M
- **Dependencies:** NYX-APP-PULSE-004
- **Verification criteria:** Interop results recorded in Runtime results.

### NYX-APP-PULSE-003: "Omarchy Linux" device name sent to Telegram

- **Component:** nyx-pulse `crates/nyx-telegram-core/src/auth.rs:31`, `apps/pulse/src/main.rs:11,70`, `apps/pulse/Cargo.toml:4`
- **Category:** UX
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Every NyxOS session appears in Telegram's Active Sessions as "Nyx Desktop (Omarchy Linux)"; `--version` and Cargo metadata say "for Omarchy Linux".
- **Expected:** "NyxOS" (or the detected OS name).
- **Actual:** as cited.
- **Reproduce / verify:** Sign in; Telegram → Settings → Devices.
- **Evidence:** as cited
- **Affected versions:** `799f1b7081`
- **User impact:** Wrong branding visible on all of the user's devices.
- **Recommended correction:** Use `/etc/os-release` `PRETTY_NAME`.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Devices list shows NyxOS.

### NYX-APP-PULSE-004: Network-facing call engine is a prebuilt binary NyxOS can't patch

- **Component:** `nyx-packages/pkgs/ntgcalls.nix`
- **Category:** packaging
- **Severity:** P3
- **Status of feature:** verified
- **Description:** NTgCalls (WebRTC, handles remote peers' media) comes from the upstream release zip with `autoPatchelfHook`; NyxOS can only take upstream releases for security fixes. Hash pinning and license files are in place.
- **Expected:** Built from source, or a tracked update policy for upstream security releases.
- **Actual:** `fetchurl …/v3.0.5/ntgcalls.linux-x86_64-shared_libs.zip`, `sourceProvenance = binaryNativeCode`.
- **Reproduce / verify:** read the file
- **Evidence:** as cited
- **Affected versions:** nyx-packages `d69e87e7fa`
- **User impact:** Delayed WebRTC security fixes.
- **Recommended correction:** Add NTgCalls to the dependency-update watch list (H08 tool updates); document the exception.
- **Effort:** S
- **Dependencies:** NYX-DEP
- **Verification criteria:** Update policy documented and automated.

### NYX-APP-PULSE-005: Design docs contradict the implementation; unwraps on runtime data

- **Component:** nyx-pulse `apps/pulse/ARCHITECTURE.md:223`, `apps/pulse/RISKS.md:15,61`; `apps/pulse/src/chat_list.rs:374,379`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Docs describe a credential wizard and `oo7` storage that don't exist (the code uses `secret-tool`, `secrets.rs:9`). `chat_list.rs:374,379` unwrap a chat projection and position from live data; if the list and model disagree, the app panics.
- **Expected:** Docs match code; list updates handle missing chats.
- **Actual:** as cited.
- **Reproduce / verify:** read the files; runtime: rapid archive/unarchive while filtering (static; confirm at runtime).
- **Evidence:** as cited
- **Affected versions:** `799f1b7081`
- **User impact:** Contributors misled; possible crash on edge cases.
- **Recommended correction:** Update docs; replace the unwraps with early returns.
- **Effort:** S
- **Dependencies:** NYX-APP-PULSE-001
- **Verification criteria:** Docs updated; no unwraps on chat lookups.
