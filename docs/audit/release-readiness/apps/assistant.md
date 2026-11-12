# Nyx Assistant scorecard

- **Repository:** design-nexus/nyx-assistant at `58ed80e2dd` (pinned in nyx-packages: yes, 0 behind origin; working tree has an uncommitted nyx-design bump in `apps/assistant/Cargo.lock` and `crates/assistant-visual/Cargo.toml`)
- **Release tier:** welcome (`nyx-system/crates/nyx-catalog/catalog.toml:416-424`, `scope = "system"`)
- **Purpose:** resident voice assistant with desktop control, plugins (abilities), a HUD, the Canvas and Aura
- **Stack:** Rust (38k lines, 15 crates), GTK4 + layer-shell (Canvas/Aura `assistant-visual`), Quickshell QML HUD, Python abilities, Node (Playwright browser worker, DuckDuckGo MCP server); IPC on `$XDG_RUNTIME_DIR/nyx-assistant/assistant.sock` (0600) and a bearer-token HTTP API on 127.0.0.1:8765
- **Binaries / services:** `nyx-assistantd`, `nyx-assistant` (CLI), `nyx-assistant-tui`, `assistant-plugin-worker`, `nyx-assistant-visual`, `nyx-assistant-node`; user units `nyx-assistantd` (not enabled by default), `nyx-assistant-hud` and `nyx-assistant-visual` (autostart with the graphical session), `nyx-assistant-failed`; module adds `nyx-assistant-setup` oneshot (`nyx-packages/pkgs/nyx-assistant.nix`, `modules/nixos/default.nix:398-414`). Enabling it turns on Nyx Voice and AI Core (`default.nix:164-177`).

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Large, real implementation on AI Core with a tested policy layer; many shipped voice commands and app launches call Omarchy-only tools (NYX-APP-ASSISTANT-001) |
| UX | 2 | Settings › Assistant, TUI and HUD approvals exist; no launcher entry, Aura ignores Nyx Bar |
| Accessibility | 1 | Voice-first; Canvas has 4 tooltips and no accessible labels, the QML HUD has no `Accessible` properties |
| Reliability | 2 | Restart policy, start limit, `OnFailure` spool; 232 unwrap/expect in non-test code, about 90% mutex locks |
| Integration | 1 | Uses AI Core and Nyx Voice's engine; Omarchy launchers, `omarchy-bar` layer and Omarchy wording on NyxOS; no desktop entry |
| Packaging | 2 | Careful Nix packaging (units rewritten, browser/search pinned, setup oneshot); dirty tree, pacman admin helper excluded but tools remain |
| Maintainability | 2 | 230 tests, CI (`check.yml`); `app.rs` 120 KB, docs Omarchy-centric, pins drift |

## Functionality

- **Language model:** Nyx AI Core through `nyx-ai-client` (`crates/assistant-inference/src/lib.rs:1-20`); `[llm] model = "auto"` takes AI Core's `assistant` default. No private runner. Implemented.
- **Speech:** links `nyx-voice-engine`/`nyx-voice-proto` at `0569d11` (`apps/assistant/Cargo.toml`), so TTS/VAD run in-process from Nyx Voice's code and listening goes through Nyx Voice's recognizer worker; it does not call `nyx-voiced`. `voxtype` remains as a fallback provider. Partial adoption of the shared service.
- **Wake word:** `[wake_word] enabled = true` by default (`config/config.toml:95-96`); once the daemon runs, the microphone is captured continuously and VAD-gated utterances are transcribed locally to look for the name (`daemon/nyx-assistantd/src/app.rs:1875-1950`). Settings › Assistant has Microphone (mute) and Wake word switches (`nyx-settings/apps/settings/src/sections/assistant/general.rs:128,185`).
- **Actions and permissions:** rules `allow/confirm/deny` with deny winning (`config/config.toml:158-170`); generated terminal commands and scripts always ask and run in bubblewrap with an empty home (`crates/assistant-tools/src/sandbox.rs:61-121`); `capture.screen`, `system.shutdown`, `terminal.*`, unknown tools ask by default (`crates/assistant-policy/src/lib.rs:246-273`); computer use asks once per task and again for labels like send/buy/delete, never touches terminals, password managers, polkit or lock screens (`config.toml` `[computer]`). Agent mode defaults to `autonomous` (`config.toml:179`).
- **Plugin worker sandbox:** bubblewrap + seccomp + `xdg-dbus-proxy` with declared names, systemd scope limits (`crates/assistant-tools/src/plugin_sandbox.rs:1-9,139-242,458-546`). Six bundled abilities are `unconfined` (calendar, reminders, passwords, nyx-apps, mail; `abilities/*/plugin.toml`), each with a stated reason.
- **Vision capture:** `screen.look`/`capture.screen` need approval (policy above); Chat-style region capture is not used.
- **Persistence:** `~/.config/nyx-assistant/{config,apps,commands}.toml`, plugin SQLite databases, `[privacy] save_history = false`, 30-day retention.
- **Stubs:** no `todo!`/`unimplemented!`; README lists file indexing, email/calendar accounts as future work.

## UX and accessibility (static)

Push-to-talk Alt+Space and Super+Shift+Escape (stop) come from the Arch install script's Hyprland snippet (`scripts/hypr-bind.lua`); NyxOS binds are outside this repo (confirm at runtime). The TUI is keyboard-complete. Canvas (`crates/assistant-visual/src/main.rs`) has 17 hard-coded colours and 4 tooltips; the HUD QML has no accessible names. Aura honours system reduce-motion (`main.rs:1395`) and only draws while active (`main.rs:321`).

## Reliability

`nyx-assistantd.service`: `Restart=on-failure`, `StartLimitBurst=5` in 120 s, `OnFailure=nyx-assistant-failed` (`systemd/nyx-assistantd.service`). HUD and Canvas restart on failure and require `WAYLAND_DISPLAY`. Offline: AI Core errors become spoken explanations (`assistant-inference/src/lib.rs:41-50`); weather, search and location need the network.

## Integration and packaging

No `.desktop` entry or app icon anywhere in the repository; the Store/Welcome item installs a service the user must find in Settings (NYX-APP-ASSISTANT-002). No actions manifest of its own; it consumes others' manifests (`abilities/nyx-apps`). Omarchy leftovers that run on NyxOS: `assistant-omarchy` maps 20 `omarchy …` commands to NyxOS tools and fails the rest (`crates/assistant-omarchy/src/lib.rs:35-71`); 18 of 51 shipped commands and 11 of 15 shipped apps have no NyxOS mapping (NYX-APP-ASSISTANT-001); Aura sizes around `omarchy-bar` only (`assistant-visual/src/main.rs:132`); the system prompt says "on Omarchy/Hyprland" (`config/config.toml:4`); `terminal = "omarchy-launch-terminal"` falls back to `xdg-terminal-exec` (`assistant-omarchy/src/lib.rs:27-33`); DND checks `omarchy-shell` then nyx-notifyd (`interaction.rs:923-925`). The rest (TUI "Follow Omarchy", migrate script, privileged helper's pacman protections) don't run on NyxOS.

## Maintenance

230 Rust tests; Nix runs only `assistant-core` and `assistant-policy` lib tests. CI `check.yml`, `release.yml`. Pins: nyx-core `394ddf8` and `4f05fb8` (origin `9187295`), nyx-design `cf39397` (origin `e311c2f`), nyx-ai `9633690` (origin `d325462`), nyx-voice `0569d11` (origin `1ebd749`), nyx-biometrics `5011c09` (origin `1fe62af`) (`evidence/shared-crate-pins.txt`). README and docs/SETUP describe Omarchy, CUDA and a curl installer.

## Runtime results

- Not exercised at runtime (wake word, voice and actions need audio hardware); its daemons and Aura/HUD units run on the dev VM.

## Findings

### NYX-APP-ASSISTANT-001: Shipped voice commands and app launches call Omarchy tools that NyxOS doesn't have

- **Component:** nyx-assistant `apps/assistant/config/apps.toml`, `config/commands.toml`, `crates/assistant-omarchy/src/lib.rs`
- **Category:** functionality
- **Severity:** P1
- **Status of feature:** partial
- **Description:** The default `apps.toml` and `commands.toml` that `nyx-assistant-setup` copies into every user's config route through `omarchy launch …` / `omarchy toggle …`. Without Omarchy, `without_omarchy` maps 20 command strings; everything else fails with "“…” is Omarchy's, and this system doesn't have it".
- **Expected:** Voice-launching apps and desktop commands (the README's Phase 1 loop) work on NyxOS, using desktop entries or Nyx equivalents.
- **Actual:** `apps.toml:30,40,49,56,61,66,71,76,81` (browser, private browser, files ×2, Spotify, Signal, Discord, About, 1Password) and `:96,101` (`omawrite`, `omacalc`) have no NyxOS path; 18 of 51 commands are unmapped (nightlight, next background, idle, bar, gaps, animations, transparency, fullscreen, layout, capture text, touchpad, screensaver, audio output switch, theme switcher, window pop, emoji and keybinding menus; e.g. `commands.toml:288`). Mapping table: `assistant-omarchy/src/lib.rs:38-60`; failure: `:68-71`. No desktop-entry fallback exists in the router.
- **Reproduce / verify:** On NyxOS with the daemon enabled, say "open the browser" or "open files"; or run the classification script in this report's method (parse both TOMLs, compare against `without_omarchy`). Static; confirm at runtime.
- **Evidence:** `nyx-assistant/apps/assistant/config/apps.toml:17-106`, `config/commands.toml:207-899`, `crates/assistant-omarchy/src/lib.rs:35-99`
- **Affected versions:** `58ed80e2dd`
- **User impact:** The most common requests ("open the browser", "open files") answer with an error on a fresh NyxOS install.
- **Recommended correction:** Ship NyxOS defaults (`exec` arrays via `gtk-launch`/`xdg-open`/Nyx apps), resolve app names through desktop entries, and map or drop the remaining Omarchy toggles.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** Every shipped app and command resolves on NyxOS without Omarchy; a test fails if a default routes to `omarchy` with no NyxOS mapping.

### NYX-APP-ASSISTANT-002: No launcher entry or icon; installed Assistant is invisible outside Settings

- **Component:** nyx-assistant (repository), `nyx-packages/pkgs/nyx-assistant.nix`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** partial
- **Description:** The repository has no `io.github.design_nexus.nyx.*.desktop` or app icon, so `buildApp` installs none; the daemon stays disabled until enabled in Settings › Assistant.
- **Expected:** A Welcome-tier app appears in Glimpse/the launcher with an icon and a first-run path (H05 Assistant 2.0).
- **Actual:** `find` finds no `.desktop`/icon in the repo; `nyx-assistantd` "waits until it is enabled" (`nyx-assistant.nix` passthru comment; `modules/nixos/default.nix:394-397`).
- **Reproduce / verify:** `find nyx-assistant -name '*.desktop'`; after install, search Glimpse for "Assistant".
- **Evidence:** `nyx-packages/lib/default.nix:240-243`, `nyx-settings/apps/settings/src/sections/assistant/client.rs:101-105`
- **Affected versions:** `58ed80e2dd`
- **User impact:** People who pick Assistant in Welcome see nothing happen and have no icon to open.
- **Recommended correction:** Add a desktop entry and icon that open Settings › Assistant (or the TUI/Canvas) and offer to enable the service on first open.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Assistant shows in Glimpse/Dock with its icon and leads to enabling the daemon.

### NYX-APP-ASSISTANT-003: Wake word is on by default, so enabling the Assistant starts always-on listening without a consent step

- **Component:** nyx-assistant `apps/assistant/config/config.toml:95-96`, `daemon/nyx-assistantd/src/app.rs:1875-1950`
- **Category:** privacy
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** `mode = "push-to-talk"` but `wake_word.enabled = true`; the wake loop captures the microphone whenever the daemon is idle and not muted.
- **Expected:** Always-listening is an explicit opt-in with clear disclosure (H05 voice privacy); push-to-talk alone by default.
- **Actual:** Default on; Settings offers Microphone/Wake word switches after the fact (`nyx-settings/.../assistant/general.rs:128,185`). Audio stays local.
- **Reproduce / verify:** Enable `nyx-assistantd` with defaults; `pw-top` shows a capture stream while idle. Static; confirm at runtime.
- **Evidence:** as above
- **Affected versions:** `58ed80e2dd`
- **User impact:** The microphone is open continuously from the moment the service is enabled.
- **Recommended correction:** Default `wake_word.enabled = false`, or ask on first enable; show a persistent mic indicator while listening.
- **Effort:** S
- **Dependencies:** NYX-APP-ASSISTANT-002 (first-run flow)
- **Verification criteria:** Fresh config has no capture stream until the user turns the wake word on.

### NYX-APP-ASSISTANT-004: Network services used by default without disclosure (IP geolocation, web search, Google)

- **Component:** nyx-assistant `config/config.toml:234-236`, `daemon/nyx-assistantd/src/interaction.rs:667`, `crates/assistant-policy/src/lib.rs:250-259`
- **Category:** privacy
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** `[location] enabled = true` sends the public IP to ipapi.co (fallback ipwho.is) for location questions; the model decides whether a question needs the web and `browser.search` is `Allow`, sending spoken questions to DuckDuckGo; visible page requests use Google.
- **Expected:** A "local" assistant discloses and gates third-party lookups (handoff 10 privacy; catalog text says only "downloads its models").
- **Actual:** Defaults on; disclosed only in README and a Settings switch ("Use my location", `general.rs:332`).
- **Reproduce / verify:** Ask "what's the weather" with defaults and watch DNS/HTTP. Static; confirm at runtime.
- **Evidence:** `apps/assistant/README.md` (Location paragraph), files above
- **Affected versions:** `58ed80e2dd`
- **User impact:** Questions and approximate location leave the computer without the user having chosen it.
- **Recommended correction:** First-run choice for location and web search; mention them in the catalog note.
- **Effort:** S
- **Dependencies:** NYX-APP-ASSISTANT-002
- **Verification criteria:** No third-party request before the user opts in.

### NYX-APP-ASSISTANT-005: Aura doesn't account for Nyx Bar

- **Component:** nyx-assistant `crates/assistant-visual/src/main.rs:126-139`
- **Category:** UX
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Bar height is read only from layers named `omarchy-bar`; Nyx Bar's namespace is `nyx-bar` (`nyx-bar/apps/bar/src/bar.rs:763`).
- **Expected:** Aura's edge flow sits clear of the NyxOS bar.
- **Actual:** On NyxOS `bar_heights` stays empty, so Aura draws as if there were no bar. Static; confirm at runtime.
- **Reproduce / verify:** Trigger the Assistant on NyxOS and screenshot the top edge.
- **Evidence:** as above
- **Affected versions:** `58ed80e2dd`
- **User impact:** Aura overlaps or misaligns with the bar.
- **Recommended correction:** Match `nyx-bar` (and keep `omarchy-bar`), or ask Shell Core for reserved areas.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Screenshot shows Aura below Nyx Bar.

### NYX-APP-ASSISTANT-006: Omarchy-centric README, docs and system prompt

- **Component:** nyx-assistant `apps/assistant/README.md:1-30`, `config/config.toml:4`, `docs/SETUP.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README says "for Omarchy/Hyprland", curl installer, CUDA/Blackwell notes; the LLM prompt tells the model it runs on Omarchy.
- **Expected:** NyxOS-accurate docs and prompt.
- **Actual:** As cited.
- **Reproduce / verify:** Read the files.
- **Evidence:** as above
- **Affected versions:** `58ed80e2dd`
- **User impact:** Misleading setup steps; the model may give Omarchy-specific answers.
- **Recommended correction:** Platform-neutral prompt; NyxOS section in README/SETUP.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No Omarchy-only instructions on the NyxOS path.

### NYX-APP-ASSISTANT-007: Shared-crate pin drift, uncommitted bump and thin packaged tests

- **Component:** nyx-assistant `apps/assistant/Cargo.toml`, `crates/assistant-visual/Cargo.toml`; `nyx-packages/pkgs/nyx-assistant.nix` (`cargoTestFlags`)
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Two nyx-core revisions in one repo and AI/Voice/Biometrics pins behind their mains; nyx-design bump uncommitted; Nix runs 2 of 15 crates' tests.
- **Expected:** One revision per shared crate, clean tree at the pinned commit, CI-equivalent tests in the package.
- **Actual:** `evidence/shared-crate-pins.txt`; `git status` shows 2 modified files.
- **Reproduce / verify:** `git -C nyx-assistant status --short`; read pins file.
- **Evidence:** as above
- **Affected versions:** `58ed80e2dd`
- **User impact:** Protocol mismatches with AI Core/Voice are possible; regressions in tools/daemon aren't caught at build.
- **Recommended correction:** Commit or drop the bump; align pins; run workspace tests that don't need hardware.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Clean tree; pins match the suite's current revisions.

### NYX-APP-ASSISTANT-008: pacman-based admin tools stay in the tool set on NyxOS

- **Component:** nyx-assistant `crates/assistant-tools/src/admin.rs:7,220-227`; `nyx-packages/pkgs/nyx-assistant.nix` header
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** partial
- **Description:** The root helper (pacman) isn't installed on NyxOS, but `admin.*` tools still call `pkexec nyx-assistant-helper`.
- **Expected:** Admin tools hidden on NyxOS or routed through the System Manager.
- **Actual:** They fail at call time. Static; confirm at runtime.
- **Reproduce / verify:** Ask the Assistant to install a package on NyxOS.
- **Evidence:** as above
- **Affected versions:** `58ed80e2dd`
- **User impact:** Confusing failures after an approval prompt.
- **Recommended correction:** Gate on helper presence; add a System Manager backend.
- **Effort:** M
- **Dependencies:** none
- **Verification criteria:** No admin tool is offered without a working backend.
